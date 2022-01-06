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

                    let msg = try Message(content, hl7: hl7)
                    
                    print(msg.specMessage!.rootGroup.pretty())

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
                    let group = msg.specMessage?.rootGroup
                    
                    print(group!)
                    
//                    let tersePath = "/ORU_R01.PATIENT_RESULT.CONTENT/ORU_R01.VISIT.CONTENT/PV1"
//                    let terser = Terser(msg)
                    //let pv1 = try terser.get(tersePath)
                    //print(pv1!)
                    //assert(pv1?.description == "PV1|1|I|G52^G52-08^^||||213322^KRAT^DAVID^JOHN^^^5871925^^LIS_LAB^L^^^DN|||||||||||I|11036427586|||||||||||||||||||||||||20251014030201-0400||||||||")
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
                    
                    //print(message.specMessage!.rootGroup!.pretty())
                    
                    print(message[HL7.PID]![HL7.V251.ORU_R01.Patient_Name]!)
                                                        
                    assert(message["SFT"]![1]!.cells[0].text                                                    == "1.2.3")
                    assert(message["SFT"]!["Software Certified Version or Release Number"]!.cells[0].text       == "1.2.3")
                    assert(message["ORC"]!["Filler Order Number"]!.cells[0].components[0].text                  == "R3464105_20181016131600")
                    assert(message["PID"]!["Patient Name"]!.cells[0].description                                == "WILLS^CYRUS^MARIO^^^^L")

                } catch let e {
                    assertionFailure(e.localizedDescription)
                }
            }
        }
        
        func testTypable() {
            let type = HL7.V251.ACK()
            let spec = try? HL7.V251(.v251)
            
            let generated = spec?.type(forName: "ACK") as! HL7.V251.ACK

            assert("\(generated.self)" == "\(type.self)")
            
            assert(Swift.type(of: type).Country_Code == HL7.V251.ACK.Country_Code)
        }
        
        
        func testSegmentCodesList() {
            var segments:[String] = []
            let spec = hl7.spec(ofVersion: .v282)
            
            for (_,m) in spec!.messages {
                for s in m.rootGroup.segments {
                    if !segments.contains(s.code) {
                        segments.append(s.code)
                    }
                }
            }
            
            var string = ""
            
            for s in segments.sorted() {
                string += "static let \(s) = \"\(s)\"\n"
            }
            
            print(string)
        }
    }
