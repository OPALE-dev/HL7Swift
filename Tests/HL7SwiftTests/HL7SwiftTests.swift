    import XCTest
    import HL7Swift
    @testable import HL7Swift
    

    final class HL7SwiftTests: XCTestCase {
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

        
        
        func testParseACK() {
            let ackContent = "MSH|^~\\&||372523L|372520L|372521L|||ACK|1|D|2.5.1||||||\rMSA|AA|LRI_3.0_1.1-NG|"
            do {
                let msg = try Message(ackContent, hl7: hl7)
                
                print(msg.specMessage!.rootGroup.pretty())
                
                assert("ACK" == (msg.type.name))
            } catch let e {
                assertionFailure(e.localizedDescription)
            }
        }
        
        
        
        func testType() {
            let paths = Bundle.module.paths(forResourcesOfType: "txt", inDirectory: nil)
            
            for path in paths {
                
                do {
                    let content = try String(contentsOf: URL(fileURLWithPath: path))
                                        
                    let msg = try Message(content, hl7: hl7)
    
                    // seek for unknow message types
                    if msg.type.name == "Unknow" {
                        print("\((path as NSString).lastPathComponent): \(msg.type.name)")
                    }
                } catch let e {
                    assertionFailure(e.localizedDescription)
                }
            }
        }
        
        
        // TODO test all files
        func testSpecParse() {
            //for path in Bundle.module.paths(forResourcesOfType: "", inDirectory: "HL7-xml v2.5.1") {
            //}
            
            let oru = Bundle.module.url(forResource: "ORU_R01 - 3", withExtension: "txt")
            if let oruPath = oru {
                do {
                    let content = try String(contentsOf: oruPath)

                    _ = try Message(content, hl7: hl7)

                } catch let e {
                    assertionFailure(e.localizedDescription)
                }
            }
        }
        
        func testTerser() {
            let oru = Bundle.module.url(forResource: "ORU_R01 - 3", withExtension: "txt")
            if let oruPath = oru {
                do {
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
                        
                } catch let e {
                    assertionFailure(e.localizedDescription)
                }
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
        
        func testParse() {
            let paths = Bundle.module.paths(forResourcesOfType: "txt", inDirectory: nil)
            
            for path in paths {
                do {
                    let content = try String(contentsOf: URL(fileURLWithPath: path))
                                        
                    let msg = try Message(content, hl7: hl7)
                    
//                    print(content.trimmingCharacters(in: .newlines))
//                    print(msg.description.trimmingCharacters(in: .newlines))
                           
                    // TODDO: fix it up!
                    //assert(msg.description.trimmingCharacters(in: .newlines) == content.trimmingCharacters(in: .newlines))
                    
                } catch let e {
                    assertionFailure(e.localizedDescription)
                }
            }
        }
        
        func testSubscripts() {
            if let url = Bundle.module.url(forResource: "ORU_R01 - 3", withExtension: "txt") {
                do {
                    let message = try Message(withFileAt: url, hl7: hl7)

                    // SFT|Lab Information System^L^^^^LIS&2.16.840.1.113883.3.111&ISO^XX^^^123544|1.2.3|LIS|1.2.34||20150328|

                    let intSubscript = message[HL7.SFT]![2]!.description
                    print(intSubscript)
                    assert(intSubscript == "1.2.3")

                    let versionIntSubscript = message[HL7.MSH]![12]!.description
                    assert(versionIntSubscript == "2.5.1")

                    message[HL7.MSH]![HL7.Message_Type]! = "ACK"
                    let mshTest = message[HL7.MSH]![HL7.Message_Type]!
                    print(mshTest)
                    assert(mshTest == "ACK")

                    let stringSubscript = message[HL7.SFT]!["Software Certified Version or Release Number"]!
                    message[HL7.SFT]!["Software Certified Version or Release Number"]! = stringSubscript
                    assert(stringSubscript == "1.2.3")

                    let symbolSubscript = message[HL7.SFT]?[HL7.Software_Certified_Version_or_Release_Number]
                    message[HL7.SFT]![HL7.Software_Certified_Version_or_Release_Number]! = symbolSubscript!
                    assert(symbolSubscript! == "1.2.3")

                    let stringSegment = message["PID"]?["Patient Name"]
                    message["PID"]?["Patient Name"]? = stringSegment!
                    assert(stringSegment == "WILLS^CYRUS^MARIO^^^^L")

                    let symbolSegment = message[HL7.PID]![HL7.Patient_Name]!
                    assert(symbolSegment == "WILLS^CYRUS^MARIO^^^^L")

                } catch let e {
                    assertionFailure(e.localizedDescription)
                }
            }
            
            do {
                let message = try Message(HL7.V25.ACK(), spec: hl7.spec(ofVersion: .v25)!, preloadSegments: [HL7.MSH, HL7.MSA])
                                
                message[HL7.MSA]![HL7.Acknowledgment_Code] = AcknowledgeStatus.AA.rawValue
        
                message[HL7.MSA]![HL7.Acknowledgment_Code] = AcknowledgeStatus.AR.rawValue
                                
            } catch let e {
                assertionFailure(e.localizedDescription)
            }
        }
        
        func testTypable() {
            let type = HL7.V251.ACK()
            let spec = try? HL7.V251(.v251)
            
            let generated = spec?.type(forName: "ACK") as! HL7.V251.ACK
            
            print(type)

            assert("\(generated.self)" == "\(type.self)")
        }
        
        
        
        
        func testPopulate() {
            if let url = Bundle.module.url(forResource: "ORU_R01 - 3", withExtension: "txt") {
                do {
                    let message = try Message(withFileAt: url, hl7: hl7)
                    
                    print(message.rootGroup!.prettyTree())
                    
                } catch {
                    
                }
            }
        }
        
        
        
        func testValidator() {
            let paths = Bundle.module.paths(forResourcesOfType: "txt", inDirectory: nil)
            
            for path in paths {
                do {
                    let content = try String(contentsOf: URL(fileURLWithPath: path))
                                        
                    let message = try Message(content, hl7: hl7)
                    let validator = DefaultValidator()
                    
                    let results = validator.validate(message, level: .datatypes)

                    for vr in results {
                        print("\(vr.type) \(vr.text)")
                    }
                    
                } catch {
                    
                }
            }
        }
        
        
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
