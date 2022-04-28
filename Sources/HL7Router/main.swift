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


extension Message {
    func fillTemplateKeys(fromMessage message:Message) -> String? {
        var hl7String = description

        var regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: "\\{\\{(.*?)\\}\\}", options: [])
        } catch {
            return nil
        }
        
        let matches = regex.matches(in: hl7String, options: [], range: NSRange(location:0, length: hl7String.count))
        
        for result in matches.reversed(){
            let substring = (description as NSString).substring(with: result.range)
            let terserPath = String(substring.dropLast(2).dropFirst(2))
            let terser = Terser(message)
            
            if let value = try? terser.get(terserPath) {
                //print("\(terserPath) \(value)")
                hl7String = (hl7String as NSString).replacingOccurrences(of: substring, with: value, options: [], range: result.range)
            }
        }
        
        return hl7String
    }
}


let routesYAML = """
---
orur01_to_mdmt10:
  incoming_message_type: "ORU_R01" # careful to match every variation with _, -, ^, etc.
  from_address: "*"
  terser_path: "/PID-3-1" # optional: if no terser path given, the matching is done on the whole message
  matching_predicate: "CONTAINS" # EQUALS, STARTS, STOPS, CONTAINS
  matching_value: "PATID5421" # the string to match with
  to_addresses: # list of remote destinations
    - "hl7://127.0.0.1:2577"
  response_template: "~/hl7/templates/hl7/mdm.hl7" # optional: given template file with special terser path variables
  # filled up on the fly by values from the incoming message. Ex: PID|||000AB-{{/PATIENT/PID-3}}|...
  
adt_route:
  incoming_message_type: "ADT_A01"
  incoming_message_version: "2.3" # optional
  from_address: "hl7://127.0.0.1:2089"
  terser_path: "/PATIENT/PID-3"
  matching_predicate: "CONTAINS"
  matching_value: "001345"
  to_addresses:
    - "https://127.0.0.1:8080/fhir"
  response_template: "~/hl7/templates/fhir/admission.json"
"""

let hl7 = try HL7()

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
    
    @Argument(help: "HL7 file output directory (default ~/hl7)")
    var dirPath: String = "~/hl7"
    
    @Argument(help: "Path to the HL7 routes file")
    var routesPath:String = ""
    
    mutating func run() throws {
        Logger.setMaxLevel(.VERBOSE)
                
        do {
            // make sure dir exists, else try to create it
            if !FileManager.default.fileExists(atPath: (self.dirPath as NSString).expandingTildeInPath) {
                try FileManager.default.createDirectory(
                    at: URL(fileURLWithPath: self.dirPath),
                    withIntermediateDirectories: true,
                    attributes: nil)
            }
            
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
    
    func server(_ server: HL7Swift.HL7Server, receive message: Message, from: String?, channel:Channel) {
        if let routes = try? Yams.load(yaml: routesYAML) as? [String: Any] {
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
