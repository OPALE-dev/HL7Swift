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
    @Option(name: .shortAndLong, help: "Hostname the server binds")
    var hostname: String = "127.0.0.1"
    
    @Option(name: .shortAndLong, help: "Port the server binds")
    var port: Int = 2575
    
    mutating func run() throws {
        let server = HL7Swift.HL7Server(host: self.hostname, port: self.port)
        
        do {
            try server.start()
        } catch let e {
            Logger.error(e.localizedDescription)
        }
    }
}

HL7Server.main()
