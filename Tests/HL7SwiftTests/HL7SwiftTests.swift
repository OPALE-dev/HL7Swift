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
                    

                    //debug
                    let group = msg.specMessage?.rootGroup
                    print("group \(group!.prettyTree(printFields: true))")
                    
                    // Initialisation of terser
                    let terser = Terser(msg)
                    
                    
                    // Get segment
                    let pv1 = try terser.geet("/PATIENT_RESULT/PATIENT/VISIT/PV1")
                    let pv1Description = "PV1|1|I|G52^G52-08^^||||213322^KRAT^DAVID^JOHN^^^5871925^^LIS_LAB^L^^^DN|||||||||||I|11036427586|||||||||||||||||||||||||20251014030201-0400||||||||"
                    assert(pv1?.description == pv1Description)
                    
                    // Regex assertions
                    XCTAssertThrowsError(try terser.geet(""))
                    XCTAssertThrowsError(try terser.geet("random"))
                    XCTAssertThrowsError(try terser.geet("/"))
                    
                    // Wrong paths
                    let nonexistantPath = try terser.geet("/something")
                    assert(nonexistantPath == nil)
                    let nonexistantPath2 = try terser.geet("/PATIENT_RESULT/PATIENT/VISIT/PV0")
                    assert(nonexistantPath2 == nil)
                    
                    // 1 /PATIENT_RESULT/PATIENT/VISIT/PV1-1
                    print(msg["PV1"]![0]!.description)
                    let field = try terser.geet("/PATIENT_RESULT/PATIENT/VISIT/PV1-1")
                    assert(field == "1")
                    // G52-08 /PATIENT_RESULT/PATIENT/VISIT/PV1-3-2
                    print(msg["PV1"]![2]!.cells[0].components[1].description)
                    let component = try terser.geet("/PATIENT_RESULT/PATIENT/VISIT/PV1-3-2")
                    assert(component == "G52-08")
                    // ISO /PATIENT_RESULT/PATIENT/SFT-1-6-3
                    print(msg["SFT"]![0]!.cells[0].components[5].components[2].description)
                    let subcomponent = try terser.geet("/PATIENT_RESULT/PATIENT/SFT-1-6-3")
                    assert(subcomponent == "ISO")
                    // L /PATIENT_RESULT/ORDER_OBSERVATION/OBSERVATION(2)/OBX-6-6
                    print(msg["OBX"]!.description)
                        
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
                                        
                    assert(msg.description.trimmingCharacters(in: .newlines) == content.trimmingCharacters(in: .newlines))
                } catch let e {
                    assertionFailure(e.localizedDescription)
                }
            }
        }
        
        func testSubscripts() {
            if let url = Bundle.module.url(forResource: "ORU_R01 - 3", withExtension: "txt") {
                do {
                    let message = try Message(withFileAt: url, hl7: hl7)
                    
                    print(message.specMessage!.rootGroup!.pretty())
                                                        
                    assert(message["SFT"]![1]!.cells[0].text                                                    == "1.2.3")
                    assert(message["SFT"]!["Software Certified Version or Release Number"]!.cells[0].text       == "1.2.3")
                    assert(message["ORC"]!["Filler Order Number"]!.cells[0].components[0].text                  == "R3464105_20181016131600")
                    assert(message["PID"]!["Patient Name"]!.cells[0].description                                == "WILLS^CYRUS^MARIO^^^^L")

                } catch let e {
                    assertionFailure(e.localizedDescription)
                }
            }
        }
    }
