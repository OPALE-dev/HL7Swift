//
//  File.swift
//
//
//  Created by Rafael Warnault on 15/01/2022.
//

import XCTest
import HL7Swift
import ModelsR4
import AsyncHTTPClient

@testable import HL7Swift


final class HL7SwiftTests: XCTestCase {
    var hl7:HL7!
    
    
    override func setUpWithError() throws {
        try super.setUpWithError()

        self.hl7 = try HL7()
    }

    
    
    func testParseACK() throws {
        let ackContent = "MSH|^~\\&||372523L|372520L|372521L|||ACK|1|D|2.5.1||||||\rMSA|AA|LRI_3.0_1.1-NG|"
        let msg = try Message(ackContent, hl7: hl7)
        
        print(msg.specMessage!.rootGroup.pretty())
        
        assert("ACK" == (msg.type.name))
    }
    
    
    
    func testType() throws {
        let paths = Bundle.module.paths(forResourcesOfType: "txt", inDirectory: nil)
        
        for path in paths {
            let content = try String(contentsOf: URL(fileURLWithPath: path))
                                
            let msg = try Message(content, hl7: hl7)

            // seek for unknow message types
            if msg.type.name == "Unknow" {
                print("\((path as NSString).lastPathComponent): \(msg.type.name)")
            }
        }
    }
    
    
    // TODO test all files
    func testSpecParse() throws {
        let oru = Bundle.module.url(forResource: "ORU_R01 - 3", withExtension: "txt")
        if let oruPath = oru {
            let content = try String(contentsOf: oruPath)

            let m = try Message(content, hl7: hl7)
            
            print(m.rootGroup!.prettyTree())
        }
    }
    
    func testTerser() throws {
        let oru = Bundle.module.url(forResource: "ORU_R01 - 3", withExtension: "txt")
        if let oruPath = oru {
            let content = try String(contentsOf: oruPath)
            let msg = try Message(content, hl7: hl7)
            
            // Initialisation of terser
            let terser = Terser(msg)
            
            
            // Get segment
            let pv1 = try terser.get("/PATIENT_RESULT/PATIENT/VISIT/PV1")
            let pv1Description = "PV1|1|I|G52^G52-08^^||||213322^KRAT^DAVID^JOHN^^^5871925^^LIS_LAB^L^^^DN|||||||||||I|11036427586|||||||||||||||||||||||||20251014030201-0400||||||||"
            assert(pv1?.description == pv1Description)
            
            // Regex assertions
            XCTAssertThrowsError(try terser.get(""))
            XCTAssertThrowsError(try terser.get("random"))
            XCTAssertThrowsError(try terser.get("/"))
            
            // Wrong paths
            let nonexistantPath = try terser.get("/something")
            assert(nonexistantPath == nil)
            let nonexistantPath2 = try terser.get("/PATIENT_RESULT/PATIENT/VISIT/PV0")
            assert(nonexistantPath2 == nil)
            
            // 1 /PATIENT_RESULT/PATIENT/VISIT/PV1-1
            let field = try terser.get("/PATIENT_RESULT/PATIENT/VISIT/PV1-1")
            assert(field == "1")
            
            // G52-08 /PATIENT_RESULT/PATIENT/VISIT/PV1-3-2
            let component = try terser.get("/PATIENT_RESULT/PATIENT/VISIT/PV1-3-2")
            assert(component == "G52-08")
            
            // ISO /PATIENT_RESULT/PATIENT/SFT-1-6-3
            let subcomponent = try terser.get("/PATIENT_RESULT/PATIENT/SFT-1-6-3")
            assert(subcomponent == "ISO")
            
            // 298113743^^^SSN^SS /PATIENT_RESULT/PATIENT/PID-3(2)
            let repetition = try terser.get("/PATIENT_RESULT/PATIENT/PID-3(2)")
            assert(repetition == "298113743^^^SSN^SS")
            
            // 298113743 /PATIENT_RESULT/PATIENT/PID-3(2)-1
            let repetitionWithComponent = try terser.get("/PATIENT_RESULT/PATIENT/PID-3(2)-1")
            assert(repetitionWithComponent == "298113743")
            
            // 42-55 /PATIENT_RESULT/ORDER_OBSERVATION/OBSERVATION(2)/OBX-7
            let segmentRepetition = try terser.get("/PATIENT_RESULT/ORDER_OBSERVATION/OBSERVATION(2)/OBX-7")
            assert(segmentRepetition == "42-55")
            let segmentRepetitionWithComponent = try terser.get("/PATIENT_RESULT/ORDER_OBSERVATION/OBSERVATION(19)/OBX-6-6")
            assert(segmentRepetitionWithComponent == "L")

        }
        
    }
    
    func testGroup() {
        var rootGroup = Group(name: "R1", items: [])
        assert(rootGroup.appendGroup(group: Group(name: "R2", items: []), underGroupName: "R1"))
        assert(rootGroup.appendGroup(group: Group(name: "R3", items: []), underGroupName: "R2"))
        assert(rootGroup.appendSegment(segment: Segment("FSH||||zefzef|||"), underGroupName: "R1"))
        assert(rootGroup.appendSegment(segment: Segment("FSH||||zefzef|||"), underGroupName: "R2"))
        assert(rootGroup.appendSegment(segment: Segment("FSH||||zefzef|||"), underGroupName: "R3"))
    }
    
    func testParse() throws {
        let paths = Bundle.module.paths(forResourcesOfType: "txt", inDirectory: nil)
        
        for path in paths {
            print(path)
        
            let content = try String(contentsOf: URL(fileURLWithPath: path))
                                
            let msg = try Message(content, hl7: hl7)
            
            print(content.trimmingCharacters(in: .newlines))
            print("")
            print(msg.description.trimmingCharacters(in: .newlines))
            print("")
            print("")
            
            // TODO: fix it up! exception on this file because newline in PID segment
            if path != "/Users/nark/Library/Developer/Xcode/DerivedData/hl7swift-cjxcccpiplnwuchbqtqqramhxfxz/Build/Products/Debug/HL7SwiftTests.xctest/Contents/Resources/HL7Swift_HL7SwiftTests.bundle/Contents/Resources/ADT-A01 Admit Patient (example from V2.8.2 base standard).txt" {
                assert(msg.description.trimmingCharacters(in: .newlines) == content.trimmingCharacters(in: .newlines))
            }
        }
    }

    func testSubscripts() throws {
        if let url = Bundle.module.url(forResource: "ORU_R01 - 3", withExtension: "txt") {
            let message = try Message(withFileAt: url, hl7: hl7)
            // SFT|Lab Information System^L^^^^LIS&2.16.840.1.113883.3.111&ISO^XX^^^123544|1.2.3|LIS|1.2.34||20150328|

            let intSubscript = message[HL7.SFT]?.fields[2]!.description
            assert(intSubscript == "1.2.3")

            let versionIntSubscript = message[HL7.MSH]![12]!.description
            assert(versionIntSubscript == "2.5.1")

            let stringSubscript = message[HL7.SFT]!["Software Certified Version or Release Number"]!
            message[HL7.SFT]!["Software Certified Version or Release Number"]! = stringSubscript
            assert(stringSubscript == message[HL7.SFT]!["Software Certified Version or Release Number"]!)

            let symbolSubscript = message[HL7.SFT]?[HL7.Software_Certified_Version_or_Release_Number]
            message[HL7.SFT]![HL7.Software_Certified_Version_or_Release_Number]! = symbolSubscript!
            assert(symbolSubscript! == message[HL7.SFT]![HL7.Software_Certified_Version_or_Release_Number]!)

            let stringSegment = message["PID"]?["Patient Name"]
            message["PID"]?["Patient Name"]? = stringSegment!
            assert(stringSegment == message["PID"]!["Patient Name"]!)

            let symbolSegment = message[HL7.PID]![HL7.Patient_Name]!
            assert(symbolSegment == "WILLS^CYRUS^MARIO^^^^L")
        }
        
        
        if let url = Bundle.module.url(forResource: "ADT_A01 - 1", withExtension: "txt") {
            let message = try Message(withFileAt: url, hl7: hl7)
            
            let symbolSegment = message[HL7.MSH]?[HL7.Character_Set]
            
            assert(symbolSegment == nil)
        }

        
        let message = try Message(HL7.V25.ACK(), spec: hl7.spec(ofVersion: .v25)!, preloadSegments: [HL7.MSH, HL7.MSA])
                                
        message[HL7.MSA]![HL7.Acknowledgment_Code] = AcknowledgeStatus.AA.rawValue
        
        assert(message[HL7.MSA]![HL7.Acknowledgment_Code]! == AcknowledgeStatus.AA.rawValue)

        message[HL7.MSA]![HL7.Acknowledgment_Code] = AcknowledgeStatus.AR.rawValue
        
        assert(message[HL7.MSA]![HL7.Acknowledgment_Code]! == AcknowledgeStatus.AR.rawValue)
        
        let message2 = try Message(HL7.V25.ADT_A02(), spec: hl7.spec(ofVersion: .v25)!, preloadSegmentsFromSpec: true)
        
        print(message2)
    }
    
    func testTypable() throws {
        let type = HL7.V251.ACK()
        let spec = try HL7.V251(.v251)
        
        let generated = spec.type(forName: "ACK") as! HL7.V251.ACK
        
        assert("\(generated.self)" == "\(type.self)")
    }
    
    
    
    
    func testValidator() throws {
        let paths = Bundle.module.paths(forResourcesOfType: "txt", inDirectory: nil)
        
        for path in paths {
            let content = try String(contentsOf: URL(fileURLWithPath: path))
            let message = try Message(content, hl7: hl7)
            let validator = DefaultValidator()
            let results = validator.validate(message, level: .datatypes)
            
            for vr in results {
                print("\(vr.type) \(vr.text)")
            }
        }
    }
    
    
    func testNonHL7Messages() {
        for m in ["", "ttt|aaa|aaa|fff|",
                  "<html></html>", "99 bottles…" ] {
            do {
                let _ = try Message(m, hl7: hl7)
            } catch let e {
                XCTAssertEqual((e as! HL7Error), HL7Error.unsupportedMessage(message: "Not HL7 message"))
            }
        }
    }
    
    func testMessageHeader() {
        // MSH|^~\\&|||||||ACK|||2.5.1|||||||||

        // message with incomplete header
        let string2 = "MSH|^~\\&||||"
                    
        do {
            let _ = try Message(string2, hl7: hl7)
        } catch let e {
            XCTAssertEqual((e as! HL7Error), HL7Error.unsupportedMessage(message: "Not enought field in segment MSH"))
        }
        
        // message with missing version
        let string1 = "MSH|^~\\&||||||||||||||||"
        do {
            let _ = try Message(string1, hl7: hl7)
        } catch let e {
            XCTAssertEqual((e as! HL7Error), HL7Error.unsupportedMessage(message: "Version field empty"))
        }
        
        // message with missing message type
        let string3 = "MSH|^~\\&||||||||||2.5.1|||||||||"
        let msg3 = try? Message(string3, hl7: hl7)
        assert((msg3?.type is HL7Swift.HL7.UnknowMessageType) == true)
    }
    
    
    func testDataTypeValidation() throws {
        let text = """
        MSH|^~\\&|NIST EHR^2.16.840.1.113883.3.72.5.22^ISO|NIST EHR Facility^2.16.840.1.113883.3.72.5.23^ISO|NIST Test Lab APP^2.16.840.1.113883.3.72.5.20^ISO|NIST Lab Facility^2.16.840.1.113883.3.72.5.21^ISO|20130211184101-0500||OML^O21^OML_O21|NIST-LOI_5.0_1.1-GU|T|2.5.1|||AL|AL|||||
        NK1|1||OTH^Other^HL70063|||||20205513|hbggggg||||County Women's Correctional Facility^^^^^CWCF&2.16.840.1.114222.4.50.12.4&ISO^XX^^^OID724
        """
        
        let msg = try Message(text, hl7: hl7)

        let validator = DefaultValidator()
        let results = validator.validate(msg, level: .datatypes)
        
        // wrong format for date
        assert(results.count == 1)
    }
    
    func testGetPosition() throws {
        if let url = Bundle.module.url(forResource: "ORU_R01 - 3", withExtension: "txt") {
            let message = try Message(withFileAt: url, hl7: hl7)
            
            // Get position in message for a given segment
            
            let msh = message[HL7.MSH]!
            let mshRange = message.getPositionInMessage(msh)
            assert(mshRange != nil)
            assert(message[HL7.MSH]!.description == message.description.substring(with: mshRange!)!)
            
            let sft = message[HL7.SFT]!
            let sftRange = message.getPositionInMessage(sft)
            assert(sftRange != nil)
            assert(message[HL7.SFT]!.description == message.description.substring(with: sftRange!)!)

            let pid = message[HL7.PID]!
            let pidRange = message.getPositionInMessage(pid)
            assert(pidRange != nil)
            assert(message[HL7.PID]!.description == message.description.substring(with: pidRange!)!)

            // Get position in message for a given field
            
            let f0 = message[HL7.MSH]?.fields[12]!
            let f0Range = message.getPositionInMessage(f0!)
            assert(f0Range != nil)
            assert("2.5.1" == message.description.substring(with: f0Range!)!)
            
            let f1 = message[HL7.SFT]?.fields[2]!
            let f1Range = message.getPositionInMessage(f1!)
            assert(f1Range != nil)
            assert("1.2.3" == message.description.substring(with: f1Range!)!)
            
            let f2 = message[HL7.MSH]?.fields[1]!
            let f2Range = message.getPositionInMessage(f2!)
            assert(f2Range != nil)
            assert("|" == message.description.substring(with: f2Range!)!)
            
            // Get position in message for a given cell

            let c1 = message[HL7.SFT]?.fields[1]?.cells[0].components[0]
            let c1Range = message.getPositionInMessage(c1!)
            assert(c1Range != nil)
            assert("Lab Information System" == message.description.substring(with: c1Range!)!)
        
            let c2 = message[HL7.SFT]?.fields[1]?.cells[0].components[5].components[0]
            let c2Range = message.getPositionInMessage(c2!)
            assert(c2Range != nil)
            assert("LIS" == message.description.substring(with: c2Range!)!)
        }
    }
    
    func testAutocompletion() throws {
        if let url = Bundle.module.url(forResource: "ORU_R01 - 3", withExtension: "txt") {
            let message = try Message(withFileAt: url, hl7: hl7)
            
            print(message.rootGroup?.autocomplete("/").keys)
            let r1 = message.rootGroup?.autocomplete("/P")
            assert(r1 != nil)
            print(Array(r1!.keys))
            assert(Array(r1!.keys).count == 15)
            
            let r2 = message.rootGroup?.autocomplete("/PI")
            assert(r2 != nil)
            assert(Array(r2!.keys) == [])
            
            let r3 = message.rootGroup?.autocomplete("/PATIENT_RESULT")
            assert(r3 != nil)
            assert(Array(r3!.keys).count == 15)
        }
    }
    
    
    
    func testHL7v2ToFHIRR4Converter() throws {
        if let url = Bundle.module.url(forResource: "ORU_R01 - 3", withExtension: "txt") {
            let expectation = XCTestExpectation(description: "Connect to server")
            
            expectation.expectedFulfillmentCount = 1
            
            let message = try Message(withFileAt: url, hl7: hl7)

            let converter = try HL7v2ToFHIRR4Converter()

            if let jsonString = try converter.convert(message) {
                let httpClient = HTTPClient(eventLoopGroupProvider: .createNew)
                
                defer {
                    try? httpClient.syncShutdown()
                }
                
                var request = try HTTPClient.Request(url: "http://localhost:8080/fhir/Bundle", method: .POST)
                request.headers.add(name: "Content-Type", value: "application/fhir+json")
                request.body = HTTPClient.Body.string(jsonString)

                httpClient.execute(request: request).whenComplete { result in
                    switch result {
                    case .failure(let error):
                        print("ERROR \(error)")
                        
                    case .success(let response):
                        print(response)
                        
                        expectation.fulfill()
                        
                        if response.status == .ok {
                            // handle response
                        } else {
                            // handle remote error
                        }
                    }
                }
                
                wait(for: [expectation], timeout: 5.0)
            }
        }
                
        
//        let patient = Patient()
//
//        patient.name = [HumanName()]
//        patient.name?[0].given = ["John"]
//        patient.name?[0].family = "Doe"
//
//        let encoder = JSONEncoder()
//        let data = try? encoder.encode(patient)
//        let string = String(data: data!, encoding: .utf8)
//
//        print(string!)
    }
    

    // TODO : put this elsewhere! (integrate in CodeGen binary?)
//        func testSegmentCodesList() {
//            var segments:[String] = []
//            let spec = hl7.spec(ofVersion: .v282)
//
//            for (_,m) in spec!.messages {
//                for s in m.rootGroup.segments {
//                    if !segments.contains(s.code) {
//                        segments.append(s.code)
//                    }
//                }
//            }
//
//            var string = ""
//
//            for s in segments.sorted() {
//                string += "static let \(s) = \"\(s)\"\n"
//            }
//
//            print(string)
//        }
//
//
//        func testFieldList() {
//            var symbols:[String] = []
//
//            let hl7 = try! HL7()
//
//            let versions = [
//                Version.v21 ,
//                Version.v23,
//                Version.v231,
//                Version.v24,
//                Version.v25,
//                Version.v251,
//                Version.v26,
//                Version.v27,
//                Version.v271,
//                Version.v28,
//                Version.v281,
//                Version.v282]
//
//            for version in versions {
//                for messageType in hl7.spec(ofVersion: version)!.messages.keys.sorted() {
//                    if let message = hl7.spec(ofVersion: version )!.messages[messageType] {
//                        for s in message.rootGroup.segments {
//                            for f in s.fields {
//                                let symbol = f.longName.symbolyze()
//                                let value  = f.longName.replacingOccurrences(of: "\"", with: "")
//
//                                if !symbols.contains(symbol) {
//                                    symbols.append(symbol)
//
//                                    print("static let \(symbol) = \"\(value)\"")
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//        }
}
