    import XCTest
    import HL7Swift
    @testable import HL7Swift

    final class HL7SwiftTests: XCTestCase {
        func testParseACK() {
            let ackContent = "MSH|^~\\&||372523L|372520L|372521L|||ACK|1|D|2.5.1||||||\rMSA|AA|LRI_3.0_1.1-NG|"
            let msg = Message(ackContent)
            assert("ACK" == msg.getType())
        }
        
        func testType() {
            let paths = Bundle.module.paths(forResourcesOfType: "txt", inDirectory: nil)
            
            for path in paths {
                
                do {
                    let content = try String(contentsOf: URL(fileURLWithPath: path))
                                        
                    let msg = Message(content)
    
                    _ = msg.getType()
                } catch {
                    print("x")
                }
            }
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
                    print(path)
                    print(msg.getType())
                } catch {
                    print("x")
                }
            }
        }
    }
