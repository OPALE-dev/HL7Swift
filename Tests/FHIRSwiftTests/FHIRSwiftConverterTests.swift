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


final class FHIRSwiftConverterTests: XCTestCase {
    var hl7:HL7!
    var fhirClient:FHIRClient!
    
    override func setUpWithError() throws {
        try super.setUpWithError()

        self.hl7 = try HL7()
    }

    
    
    func testHL72FHIRR4Converter() throws {
        if let url = Bundle.module.url(forResource: "ORU_R01 - 3", withExtension: "txt") {
            let expectation = XCTestExpectation(description: "Connect to server")
            
            expectation.expectedFulfillmentCount = 1
            
            let message   = try Message(withFileAt: url, hl7: hl7)
            let converter = try HL72FHIRR4Converter()
            
            if let string = try converter.convert(message) {
                print(string)
            }
        }
    }
    
    
    /**
     This test converts a HL7 ORU_R01 message to a FHIR bundle then send it to local HAPI FHIR server
     */
    func testHL72FHIRR4ConvertORUAndSend() throws {
        if let url = Bundle.module.url(forResource: "ORU_R01 - 3", withExtension: "txt") {
            let expectation = XCTestExpectation(description: "Connect to server")
            
            expectation.expectedFulfillmentCount = 1
            
            let message   = try Message(withFileAt: url, hl7: hl7)
            let converter = try HL72FHIRR4Converter()
            
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
