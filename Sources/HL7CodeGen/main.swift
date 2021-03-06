//
//  File.swift
//  
//
//  Created by Rafael Warnault on 23/12/2021.
//

import Foundation
import HL7Swift
import SwiftGenerator
import ArgumentParser

struct HL7CodeGen: ParsableCommand {
    mutating func run() throws {
        Generator.HL7Generator().generateHL7Spec(at: "~/HL7CodeGen")
    }
}

HL7CodeGen.main()
