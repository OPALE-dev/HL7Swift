    import XCTest
    import HL7Swift
    @testable import HL7Swift

    final class HL7SwiftTests: XCTestCase {
        func testParseACK() {
            let ackContent = "MSH|^~\\&||372523L|372520L|372521L|||ACK|1|D|2.5.1||||||\rMSA|AA|LRI_3.0_1.1-NG|"
            let msg = Message(ackContent)
            assert("ACK" == (try? msg.getType().rawValue))
        }
        
        func testType() {
            let paths = Bundle.module.paths(forResourcesOfType: "txt", inDirectory: nil)
            
            for path in paths {
                
                do {
                    let content = try String(contentsOf: URL(fileURLWithPath: path))
                                        
                    let msg = Message(content)
    
                    _ = try? msg.getType().rawValue
                } catch {
                    print("x")
                }
            }
        }
        
        func testSpecParse() {
            //for path in Bundle.module.paths(forResourcesOfType: "", inDirectory: "HL7-xml v2.5.1") {
            //}
            
            let oru = Bundle.module.url(forResource: "ORU_R01 - 3", withExtension: "txt")
            if let oruPath = oru {
                do {
                    let content = try String(contentsOf: oruPath)
                    var msg = Message(content)
                    
                    print(try msg.group()!.pretty())
                } catch {
                    print("x")
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
            // This is an example of a functional test case.
            // Use XCTAssert and related functions to verify your tests produce the correct
            // results.
            
            let paths = Bundle.module.paths(forResourcesOfType: "txt", inDirectory: nil)
            
            for path in paths {
                
                do {
                    let content = try String(contentsOf: URL(fileURLWithPath: path))
                                        
                    let msg = Message(content)
                                        
                    assert(msg.description.trimmingCharacters(in: .newlines) == content.trimmingCharacters(in: .newlines))
                } catch {
                    print("x")
                }
            }
        }
        
        func testSpec() {
            let _ = try? HL7(.v23)
            let _ = try? HL7(.v231)
            let _ = try? HL7(.v24)
            let _ = try? HL7(.v25)
            let _ = try? HL7(.v251)
            let _ = try? HL7(.v26)
            let _ = try? HL7(.v27)
            let _ = try? HL7(.v271)
            let _ = try? HL7(.v28)
            let _ = try? HL7(.v281)
            let _ = try? HL7(.v282)
        }
    }
