//
//  File.swift
//  
//
//  Created by Rafaël Warnault on 28/04/2022.
//

import Foundation
import HL7Swift
import ArgumentParser
import NIO
import Yams


/**
 Fills a HL7 template message with terser path values from a given HL7 message.
 The template message is a HL7 message with fields replaced by terser path like:

     {{/PATIENT_RESULT/PATIENT/PID-3}}
 
 See `mdm.hl7` file for more detailed examples.
 It simply returns a string, mostly to not modify the original template file.
 */
extension Message {
    func fillTemplateKeys(fromMessage message:Message) -> String? {
        var hl7String = description

        var regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: "\\{\\{(.*?)\\}\\}", options: [])
            
            let matches = regex.matches(in: hl7String, options: [], range: NSRange(location:0, length: hl7String.count))
            for result in matches.reversed(){
                let substring = (description as NSString).substring(with: result.range)
                let terserPath = String(substring.dropLast(2).dropFirst(2))
                let terser = Terser(message)
                
                if let value = try terser.get(terserPath) {
                    hl7String = (hl7String as NSString).replacingOccurrences(of: substring, with: value, options: [], range: result.range)
                }
            }
        } catch {
            return nil
        }
        
        return hl7String
    }
}



// Ugly, but eh.
let hl7 = try HL7()
var routes:[String: Any] = [:]

/**
 Mostly a clone of `HL7Server` but embeding a routing system based on the `routes.yaml` file.
 See `routesPath` parameter.
 */
struct HL7Router: ParsableCommand, HL7ServerDelegate {
    @Option(name: .shortAndLong, help: "Hostname the router binds (default 127.0.0.1)")
    var hostname: String = "127.0.0.1"
    
    @Option(name: .shortAndLong, help: "Port the router binds (default 2575)")
    var port: Int = 2575
    
    @Option(name: .shortAndLong, help: "Enable TLS")
    var tls: Bool = false
    
    @Option(name: .shortAndLong, help: "Certificate path for TLS")
    var certificate: String?
    
    @Option(name: [.customShort("k"), .long], help: "Private key path for TLS")
    var privateKey: String?
    
    @Option(name: [.customShort("s"), .long], help: "Passphrase for the private key")
    var passphrase: String = ""

    @Argument(help: "Path to the HL7 routes file")
    var routesPath:String = "~/hl7/routes.yaml"
    
    mutating func run() throws {
        Logger.setMaxLevel(.VERBOSE)
                
        do {
            // prepare routes
            let yamlString = try String(contentsOfFile: routesPath)
            let yaml = try? Yams.load(yaml: yamlString)
            if let rs = yaml as? [String: Any] {
                routes = rs
            }
            
            // config server
            var config = ServerConfiguration(hl7)
            
            config.TLSEnabled = tls
            config.certificatePath = certificate
            config.privateKeyPath = privateKey
            config.passphrase = passphrase

            // start the server
            let server = try HL7Swift.HL7Server( config, delegate: self)
            try server.start()
            
        } catch let e {
            print(e)
            Logger.error(e.localizedDescription)
        }
    }
    
        
    
    // MARK: -
    func server(_ server: HL7Swift.HL7Server, send message: Message, to: String?, channel:Channel) {
        
    }
    
    /**
     We do all the logic here. Looping over the routes, checking route conditions, then sending response back to destinations.
     */
    func server(_ server: HL7Swift.HL7Server, receive message: Message, from: String?, channel:Channel) {
        for (routeName, routeData) in routes {
            if let routeDict = routeData as? [String: Any] {
                var fromOK = false
                
                // check from address
                if let fromAddresses = routeDict["from_address"] as? String {
                    if fromAddresses == "*" {
                        fromOK = true
                    }
                    else if fromAddresses == channel.remoteAddress?.ipAddress {
                        fromOK = true
                    }
                }
                
                if fromOK {
                    // check message type
                    if let messageType = routeDict["incoming_message_type"] as? String,
                           message.type.name == messageType
                    {
                        // check terser condition
                        if  let matchingValue = routeDict["matching_value"] as? String,
                            let predicate     = routeDict["matching_predicate"] as? String,
                            let terserPath    = routeDict["terser_path"] as? String
                        {
                            let terser = Terser(message)
                            
                            do {
                                let value = try terser.get(terserPath)
                                var terserMatchOK = false
                                
                                // check with given predicate
                                switch predicate {
                                    case "EQUALS":
                                        if value == matchingValue {
                                            terserMatchOK = true
                                        }
                                    case "CONTAINS":
                                        if value!.contains(matchingValue) {
                                            terserMatchOK = true
                                        }
                                    case "STARTS":
                                        if value!.starts(with: matchingValue) {
                                            terserMatchOK = true
                                        }
                                    case "ENDS":
                                        if value!.hasSuffix(matchingValue) {
                                            terserMatchOK = true
                                        }
                                    default: break;
                                }
                                
                                
                                if terserMatchOK {
                                    var response = message
                                    
                                    // check for response template
                                    // if no response template, we just route the received message
                                    if var templatePath = routeDict["response_template"] as? String {
                                        templatePath = (templatePath as NSString).expandingTildeInPath
                                        
                                        if let hl7String = try? String(contentsOfFile: templatePath),
                                           let templateMessage = try? Message(hl7String, hl7: hl7) {
                                            
                                            // fill template with terser values from received message
                                            if let string = templateMessage.fillTemplateKeys(fromMessage: message) {
                                                if let r = try? Message(string, hl7: hl7) {
                                                    response = r
                                                }
                                            }
                                        }
                                    }
                                    
                                    Logger.info("\n\n* -> [\(routeName)] matched\n\n")
                                    
                                    // for every destination address
                                    if let destinations = routeDict["to_addresses"] as? [String] {
                                        for address in destinations {
                                            if let url = URL(string: address) {
                                                // check scheme (we may want to support HTTP/FHIR later)
                                                if let host = url.host, url.scheme == "hl7" {
                                                    channel.eventLoop.execute {
                                                        // send « response » to the destination address on the channel event-loop
                                                        var config = ClientConfiguration(hl7)
                                                        
                                                        config.host = host
                                                        config.port = url.port ?? 2575
                                                        config.TLSEnabled = false
                                                        
                                                        let client = try? HL7Swift.HL7CLient(config)
                                                        
                                                        try? client?.connect().whenSuccess({ _ in
                                                            _ = client?.channel?.writeAndFlush(response)
                                                        })
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            } catch let e {
                                print(e.localizedDescription)
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    func server(_ server: HL7Swift.HL7Server, ACKStatusFor message:Message, channel:Channel) -> AcknowledgeStatus {
        return .AA
    }
    
    func server(_ server: HL7Swift.HL7Server, channelDidBecomeInactive channel: Channel) {

    }
    
    func server(_ server: HL7Swift.HL7Server, channelDidBecomeActive channel: Channel) {

    }
}



// MARK: -

HL7Router.main()
