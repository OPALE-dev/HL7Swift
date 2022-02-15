//
//  File.swift
//
//
//  Created by Rafael Warnault on 07/01/2022.
//

import Foundation
import SwiftGenerator

extension Generator {
    public class HL7Generator {
        public init() {
            
        }
        /**
         This function generates `Versionable` implementations based on the HL7 specification.
         It writes at `path` a set of `Versioned` subclasses, one for each embedded version of the specification (named, `V21`, `V23`, `V231`, etc).
         Each `Versioned` subclass provides a set of `Typable` classes that represents HL7 message types (`ADT_A01`, `ORU_R01`, etc).
         Each `Versioned` subclass provides a `type(forName:)` method that returns the desired `Typable` class for a given string.
         Everything is declared as extension of the `HL7` (sort of) namespace.
         */
        public func generateHL7Spec(at path:String) {
            HL7.generator = true
            
            let hl7 = try! HL7()
            
            let versions = [
                Version.v21 ,
                Version.v23,
                Version.v231,
                Version.v24,
                Version.v25,
                Version.v251,
                Version.v26,
                Version.v27,
                Version.v271,
                Version.v28,
                Version.v281,
                Version.v282]
            
            let forlderPath = (path as NSString).expandingTildeInPath
            
            try? FileManager.default.createDirectory(atPath: forlderPath, withIntermediateDirectories: true, attributes: nil)
            
            for version in versions {
                var namespaceExtension = Extension(name: "HL7")
                
                let versionName = Version.klass(forVersion: version)
                
                var implementation = Class(name: "\(versionName)", protocols: ["Versioned"])
                var function = Generator.Function(name: "type", parameters: ["forName name:String"], returnType: "Typable?", override: true)
                var typeSwitch = Generator.Switch(name: "name", defaultCase: "default: return nil")
                                
                for messageType in hl7.spec(ofVersion: version)!.messages.keys.sorted() {
                    typeSwitch.nodes.append(Generator.Case(name: "\"\(messageType)\"", value: "return \(messageType)()", separator: ":"))
                    
                    //break // Debug first message type
                }
                
                function.nodes.append(typeSwitch)
                
                implementation.nodes.append(function)
                
                for messageType in hl7.spec(ofVersion: version)!.messages.keys.sorted() {
                    var typableStruct = Generator.Class(name: messageType, protocols: ["Typable"])
                    let nameInstr = Generator.Instruction(name: "var name:String = \"\(messageType)\"")
                    
                    typableStruct.nodes.append(nameInstr)
                                    
                    implementation.nodes.append(typableStruct)
                    
                     //break // Debug first message type
                }
                
                namespaceExtension.nodes.append(implementation)
                
                let filePath = "\(forlderPath)/\(versionName).swift"
                
                try? namespaceExtension.generate().write(to: URL(fileURLWithPath: filePath), atomically: false, encoding: .utf8)
            }
        }
    }
}
