//
//  File.swift
//  
//
//  Created by Rafaël Warnault on 28/04/2022.
//

import Foundation
import Dispatch
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
private extension Message {
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


/**
 The kinds of predicate the router supports
 */
private enum RouterPredicate:String {
    case EQUALS     = "EQUALS"
    case CONTAINS   = "CONTAINS"
    case STARTS     = "STARTS"
    case ENDS       = "ENDS"
}

/**
 String helpers to symbolize YAML keys
 */
private extension String {
    static let from_hostname            = "from_hostname"
    static let incoming_message_type    = "incoming_message_type"
    static let and_conditions           = "and_conditions"
    
    static let matching_value           = "matching_value"
    static let matching_predicate       = "matching_predicate"
    static let terser_path              = "terser_path"
    
    static let response_template        = "response_template"
    static let to_addresses             = "to_addresses"
}


// MARK: -

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
            HL7Router.reloadRoutes(routesPath)
            
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
    
    static func reloadRoutes(_ path:String) {
        do {
            let yamlString = try String(contentsOfFile: path)
            let yaml = try Yams.load(yaml: yamlString)
            if let rs = yaml as? [String: Any] {
                routes = rs
            }
        } catch {
            
        }
    }
    
    
    // MARK: -
    /**
     We do all the logic here. Looping over the routes, checking route conditions, then sending response back to destinations.
     */
    func server(_ server: HL7Swift.HL7Server, receive message: Message, from: String?, channel:Channel) {
        for (routeName, routeData) in routes {
            if let routeDict = routeData as? [String: Any] {
                var fromOK = false
                
                // check from address
                if let fromHotname = routeDict[.from_hostname] as? String {
                    if fromHotname == "*" {
                        fromOK = true
                    }
                    else if fromHotname == channel.remoteAddress?.ipAddress {
                        fromOK = true
                    }
                }
                
                if fromOK {
                    // check message type
                    if let messageType = routeDict[.incoming_message_type] as? String,
                           message.type.name == messageType
                    {
                        var conditionsOK = false
                        
                        // check AND conditions
                        if let andConditions = routeDict[.and_conditions] as? [[String: String]] {
                            for condition in andConditions {
                                // check terser value
                                if  let matchingValue = condition[.matching_value],
                                    let predicate     = condition[.matching_predicate],
                                    let terserPath    = condition[.terser_path]
                                {
                                    let terser = Terser(message)
                                    
                                    do {
                                        let value = try terser.get(terserPath)
                                        let predicate = RouterPredicate(rawValue: predicate) ?? .EQUALS
                                        // check with given predicate
                                        switch predicate {
                                            case .EQUALS:   conditionsOK = value == matchingValue
                                            case .CONTAINS: conditionsOK = value!.contains(matchingValue)
                                            case .STARTS:   conditionsOK = value!.starts(with: matchingValue)
                                            case .ENDS:     conditionsOK = value!.hasSuffix(matchingValue)
                                        }
                                    } catch { /* conditionsOK is false */ }
                                }
                            }
                        } else {
                            // if none AND conditons found in route
                            conditionsOK = true
                        }
                        
                        // continue
                        if conditionsOK {
                            var response = message
                            // check for response template
                            // if no response template, we just route the received message
                            if var templatePath = routeDict[.response_template] as? String {
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
                            
                            Logger.info("\n\n* -> [\(routeName)] matched\n")
                            
                            // for every destination address
                            if let destinations = routeDict[.to_addresses] as? [String] {
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
                    }
                }
            }
        }
    }
    
    
    func server(_ server: HL7Swift.HL7Server, send message: Message, to: String?, channel:Channel) {
        
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
