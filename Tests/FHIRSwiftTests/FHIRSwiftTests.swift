//
//  File.swift
//  
//
//  Created by Rafael Warnault on 15/02/2022.
//

import XCTest
import HL7Swift
import ModelsR4
import AsyncHTTPClient

@testable import FHIRSwift


final class FHIRSwiftTests: XCTestCase {
    var hl7:HL7!
    var fhirClient:FHIRClient!
    
    override func setUpWithError() throws {
        try super.setUpWithError()

        self.hl7 = try HL7()
    }

    
    
    func testHL7v2ToFHIRR4Converter() throws {
        if let url = Bundle.module.url(forResource: "ORU_R01 - 3", withExtension: "txt") {
            let expectation = XCTestExpectation(description: "Connect to server")
            
            expectation.expectedFulfillmentCount = 1
            
            let message   = try Message(withFileAt: url, hl7: hl7)
            let converter = try HL7v2ToFHIRR4Converter()
            
            if let bundle  = try converter.convert(message) {
                if let url = URL(string: "http://localhost:8080/fhir/") {
                    fhirClient = FHIRClient(url)
                    
                    try fhirClient.create(bundle).whenComplete { result in
                        switch result {
                        case .failure(let error):
                            print("ERROR \(error)")
                            
                            expectation.fulfill()
                        case .success(let response):
                            expectation.fulfill()

                            if response.status == .ok {
                                // handle response
                            } else {

                            }
                        }
                    }
                }

                wait(for: [expectation], timeout: 10.0)
            }
        }
    }
}
