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

struct HL7Server: ParsableCommand {
    @Option(name: .shortAndLong, help: "Hostname the server binds (default 127.0.0.1)")
    var hostname: String = "127.0.0.1"
    
    @Option(name: .shortAndLong, help: "Port the server binds (default 2575)")
    var port: Int = 2575
    
    @Argument(help: "HL7 file output directory (default ~/hl7)")
    var dirPath: String = "~/hl7"
    
    
    mutating func run() throws {
        do {
            let server = try HL7Swift.HL7Server(
                host: self.hostname,
                port: self.port,
                dir: self.dirPath)
            
            try server.start()
        } catch let e {
            Logger.error(e.localizedDescription)
        }
    }
}

HL7Server.main()
