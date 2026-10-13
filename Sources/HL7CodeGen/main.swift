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
    @Option(help: "Directory of caller-owned licensed v<version> XSD artefacts")
    var specificationDirectory: String

    @Option(help: "Output directory for generated Swift symbols")
    var outputDirectory: String

    mutating func run() throws {
        try Generator.HL7Generator().generateHL7Spec(at: outputDirectory,
            specificationSource: .init(directory: URL(fileURLWithPath: specificationDirectory)))
    }
}

HL7CodeGen.main()
