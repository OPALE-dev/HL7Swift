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

struct HL7Server: ParsableCommand, HL7ServerDelegate {
    @Option(name: .shortAndLong, help: "Hostname the server binds (default 127.0.0.1)")
    var hostname: String = "127.0.0.1"
    
    @Option(name: .shortAndLong, help: "Port the server binds (default 2575)")
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
    
    
    mutating func run() throws {
        Logger.setMaxLevel(.VERBOSE)
        
        do {
            let hl7 = try HL7()
            
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
        let timeInterval = NSDate().timeIntervalSince1970

        do {
            // store file
            let filePath = "\((self.dirPath as NSString).expandingTildeInPath)/\(message.type.name)-\(timeInterval).hl7"
        
            try message.description.write(toFile: filePath, atomically: true, encoding: .utf8)
        } catch let e {
            Logger.error("FS write error: \(e.localizedDescription)")
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

HL7Server.main()

