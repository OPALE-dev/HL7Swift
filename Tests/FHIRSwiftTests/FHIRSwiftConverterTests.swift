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
            
            if let string = try converter.convert(message: message, formatting: .prettyPrinted) {
                print(string)
            }
        }
    }
    
    
    /**
     This test converts a HL7 ORU_R01 message to a FHIR bundle then send it to local HAPI FHIR server
     */
    func testHL72FHIRR4ConvertORUToBundleAndSend() throws {
        if let url = Bundle.module.url(forResource: "ORU_R01 - 3", withExtension: "txt") {
            let expectation = XCTestExpectation(description: "Connect to server")
            
            expectation.expectedFulfillmentCount = 1
            
            let message   = try Message(withFileAt: url, hl7: hl7)
            let converter = try HL72FHIRR4Converter()
            
            if let bundle = try converter.convert(message) {
                if let url = URL(string: "http://localhost:8080/fhir/") {
                    fhirClient = FHIRClient(url)
                    
                    try fhirClient.create(bundle) { result in
                        switch result {
                        
                        case .error(let error):
                            print(error)
                            expectation.fulfill()
                            
                        case .success(let id, let url, _):
                            print("New created ID : \(id) \(url)")
                            expectation.fulfill()
                        }
                    }
                }

                wait(for: [expectation], timeout: 10.0)
            }
        }
    }
    
    
    func testHL72FHIRR4Client() throws {
        if let url = Bundle.module.url(forResource: "ORU_R01 - 3", withExtension: "txt") {
            let expectation = XCTestExpectation(description: "Connect to server")
            
            expectation.expectedFulfillmentCount = 1
            
            let message = try Message(withFileAt: url, hl7: hl7)
            
            if let url = URL(string: "http://localhost:8080/fhir/") {
                fhirClient = FHIRClient(url)
                
                let converter = try HL72FHIRR4Client(fhirClient)
                
                try converter.translate(message)
            }
        }
    }
}
