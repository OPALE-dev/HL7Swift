    import XCTest
    import HL7Swift
    @testable import HL7Swift

    final class HL7SwiftTests: XCTestCase {
        func testExample() {
            // This is an example of a functional test case.
            // Use XCTAssert and related functions to verify your tests produce the correct
            // results.
            
            let path = "ADT_A01 - 1"
            let filePath = Bundle.module.path(forResource: path, ofType: "txt")

            if let f = filePath {

                do {
                    let content = try String(contentsOf: URL(fileURLWithPath: f))
                                        
                    let msg = Message(content)

                    assert(msg.description == content)
                    
                } catch {
                    print("a")
                }
            }
        }
    }
