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
            
            let forlderPath = ("~/HL7SwiftVersion" as NSString).expandingTildeInPath
            
            try? FileManager.default.createDirectory(atPath: forlderPath, withIntermediateDirectories: true, attributes: nil)
            
            for version in versions {
                var namespaceExtension = Generator.Extension(name: "HL7")
                
                let versionName = Version.klass(forVersion: version)
                var implementation = Generator.Class(name: "\(versionName)", protocols: ["Versioned"], properties: [])
                var function = Generator.Function(
                    name: "type",
                    vivibility: .Unspecified,
                    protocols: [],
                    nodes: [],
                    override: true,
                    parameters: ["forName name:String"],
                    returnType: "Typable?")
                
                var typeSwitch = Generator.Switch(name: "name", defaultCase: "default: return nil")
                                
                for messageType in hl7.spec(ofVersion: version).messages.keys.sorted() {
                    typeSwitch.nodes.append(Generator.Case(name: "\"\(messageType)\"", value: "return \(messageType)()", separator: ":"))
                    
                    //break
                }
                
                function.nodes.append(typeSwitch) 
                
                implementation.nodes.append(function)
                
                for messageType in hl7.spec(ofVersion: version).messages.keys.sorted() {
                    var typableStruct = Generator.Class(name: messageType, protocols: ["Typable"])
                    let nameInstr = Generator.Instruction(name: "var name:String = \"\(messageType)\"")
                    
                    typableStruct.nodes.append(nameInstr)
                    
                    var fieldTypeEnum = Generator.Enum(name: "FieldType", type: "String")
                    
                    if let message = hl7.spec(ofVersion: version ).messages[messageType] {
                        for s in message.rootGroup.segments {
                            for f in s.fields {
                                let symbol = f.longName
                                    .replacingOccurrences(of: " ", with: "_")
                                    .replacingOccurrences(of: "/", with: "_")
                                    .replacingOccurrences(of: "+", with: "_")
                                    .replacingOccurrences(of: "-", with: "_")
                                    .replacingOccurrences(of: "–", with: "_")
                                    .replacingOccurrences(of: "'", with: "")
                                    .replacingOccurrences(of: "’", with: "")
                                    .replacingOccurrences(of: ".", with: "_")
                                    .replacingOccurrences(of: ",", with: "")
                                    .replacingOccurrences(of: "(", with: "")
                                    .replacingOccurrences(of: ")", with: "")
                                    .replacingOccurrences(of: "\"", with: "")
                                    .replacingOccurrences(of: "&", with: "And")
                                    .replacingOccurrences(of: "*", with: "All")
                                    .replacingOccurrences(of: "#", with: "Dash")
                                
                                let value = f.longName.replacingOccurrences(of: "\"", with: "")

                                // TODO: find a placeholder for « Type » field (reserved word in Swift)
                                if symbol != "Type" {
                                    fieldTypeEnum.append(
                                        Generator.Case(name: symbol, value: "\"\(value)\"")
                                    )
                                }

                            }
                        }
                    }
                            
                    typableStruct.nodes.append(fieldTypeEnum)
                    implementation.nodes.append(typableStruct)
                    
                     //break
                }
                
                namespaceExtension.nodes.append(implementation)
                
                let filePath = "\(forlderPath)/\(versionName).swift"
                
                try? namespaceExtension.generate().write(to: URL(fileURLWithPath: filePath), atomically: false, encoding: .utf8)
            }
        }
    
    
    func testFiteFait() {
        //let type = HL7.V251.ACK(name: "ACK")
//        let spec = try? HL7.V251(.v251)
//        let type = spec?.type(forName: "ACK") as! HL7.V251.ACK
//
//        print(Swift.type(of: type).FieldType.test)
    }
}
