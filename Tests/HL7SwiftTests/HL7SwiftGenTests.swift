//
//  File.swift
//  
//
//  Created by Rafael Warnault on 05/01/2022.
//

import XCTest
import HL7Swift
@testable import HL7Swift

final class HL7SwiftGenTests: XCTestCase {
    var hl7:HL7!
    
    override func setUp() {
        super.setUp()

        do {
            self.hl7 = try HL7()
        } catch let e {
            NSLog("Cannot load HL7 spec \(e.localizedDescription)")
            assertionFailure(e.localizedDescription)
        }
    }

    
    
    func testGenerateEnums() {
        let code = Generator.generateEnums(
            name: "MessageType",
            type: String.self,
            list: hl7.spec(ofVersion: .v21).messages.keys.sorted(),
            vivibility: .Public)
        
        print(code)
    }
    
    func testGenerateStructs() {
        let code = Generator.generateStructs(
            protocols: ["Typable"],
            list: hl7.spec(ofVersion: .v21).messages.keys.sorted(),
            vivibility: .Public)
        
        print(code)
    }
    
    func testGenerateClasses() {
        let code = Generator.generateClasses(
            inherits: ["Typable"],
            list: hl7.spec(ofVersion: .v21).messages.keys.sorted(),
            vivibility: .Public)
        
        print(code)
    }
    
    
    func testGenerateStructs2() {
        var namespace = Generator.Struct(name: "HL7")
        var version = Generator.Struct(name: "V23", protocols: ["Versionable"])
        
        for messageType in hl7.spec(ofVersion: .v23).messages.keys.sorted() {
            version.nodes.append(
                Generator.Struct(name: messageType, protocols: ["MessageType"])
            )
        }
        
        namespace.nodes.append(version)
        
        print(namespace.generate())
    }
}
