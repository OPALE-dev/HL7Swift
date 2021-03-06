//
//  File.swift
//  
//
//  Created by Rafael Warnault on 23/12/2021.
//

import Foundation
import HL7Swift
import ArgumentParser
import NIO

struct HL7Client: ParsableCommand {
    @Option(name: .shortAndLong, help: "Hostname client connects to")
    var hostname: String = "127.0.0.1"
    
    @Option(name: .shortAndLong, help: "Port client connects to")
    var port: Int = 2575
    
    @Option(name: .shortAndLong, help: "Enable TLS")
    var tls: Bool = false
    
    @Argument(help: "HL7 file to send")
    var filePaths: [String]
    
    mutating func run() throws {
        do {
            let hl7 = try HL7()
            
            var config = ClientConfiguration(hl7)
            
            config.host = hostname
            config.port = port
            config.TLSEnabled = tls
//            config.certificatePath = certificate
//            config.privateKeyPath = privateKey
//            config.passphrase = passphrase
//
            let client = try HL7Swift.HL7CLient(config)
                        
            let future = try client.connect()
            try future.wait()
            
            Logger.info("Connected to \(hostname):\(port)...")
            
            for filePath in filePaths {
                Logger.info("Send file: \(filePath)")
                
                if let response = try client.send(fileAt: filePath) {
                    Logger.info("### Received \(response.type.name)")
                    Logger.debug("\n\n\(response.description)\n")
                }
            }

            client.disconnect()
        } catch let e {
            print(e)
            Logger.error(e.localizedDescription)
        }
    }
}

HL7Client.main()
