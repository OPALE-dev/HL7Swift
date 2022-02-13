//
//  File.swift
//  
//
//  Created by Rafael Warnault on 13/02/2022.
//

import Foundation
import ModelsR4
import SwiftCSV


public class HL7v2ToFHIR4Converter: Converter, CustomStringConvertible {
    public var description: String {
        "HL7 v2.x To FHIR Models R4 Converter"
    }
    
    public init() {
        load()
    }
    
    public func convert(_ message:Message) -> String? {
        return nil
    }
    
    public func convert(_ input:String) -> String? {
        return nil
    }
}


// MARK: - Load CSV
private extension HL7v2ToFHIR4Converter {
    func load() {
        loadMessages()
    }
    
    func loadMessages() {
        if let csvURLs = Bundle.module.urls(forResourcesWithExtension: "csv", subdirectory: nil) {
            print(csvURLs)
        }
    }
}
