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


final class FHIRSwiftClientTests: XCTestCase {
    var hl7:HL7!
    var fhirClient:FHIRClient!
    
    override func setUpWithError() throws {
        try super.setUpWithError()

        self.hl7 = try HL7()
    }
}
