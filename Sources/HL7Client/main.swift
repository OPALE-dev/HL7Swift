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
    @Option(name: .shortAndLong, help: "Hostname the client connects")
    var hostname: String = "127.0.0.1"
    
    @Option(name: .shortAndLong, help: "Port the client connects")
    var port: Int = 2575
    
    @Argument(help: "HL7 file to send")
    var filePath: String
    
    mutating func run() throws {
        
    }
}

HL7Client.main()
