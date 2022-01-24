//
//  File.swift
//  
//
//  Created by Rafael Warnault on 24/01/2022.
//

import Foundation
import XCTest
import HL7Swift
@testable import HL7Swift


final class HL7SwiftNetworkTests: XCTestCase {
    var hl7:HL7!
    var host = "127.0.0.1"
    var port = 7777
    
    override func setUpWithError() throws {
        try super.setUpWithError()

        self.hl7 = try HL7()
    }
    
    
    func testServer() throws {
        let queue = DispatchQueue(label: "hl7swift-test.serial.queue", attributes: .concurrent)
        let expectation = XCTestExpectation(description: "Stop the server")

        var server:HL7Server? = nil
        
        server = try HL7Server(host: host, port: port)
        
        queue.async {
            do {
                try server?.start()
            } catch let e {
                XCTAssertThrowsError(e)
            }
        }
        
        sleep(3)
            
        try server?.stop()
        
        expectation.fulfill()
        
        server = nil
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    
    func testClient() throws {
        let serialQueue = DispatchQueue(label: "hl7swift-test.serial.queue")
        let expectation = XCTestExpectation(description: "Connect to server")
        
        expectation.expectedFulfillmentCount = 3
        
        var server:HL7Server? = nil
        var client:HL7CLient? = nil
        
        client = try HL7CLient(host: host, port: port)
        server = try HL7Server(host: host, port: port)
        
        serialQueue.async {
            do {
                print("start")
                try server?.start()
            } catch let e {
                XCTAssertThrowsError(e)
            }
        }
        
        
        
        sleep(3)
        
        print("connect")
        
        try client?.connect().wait()
        
        expectation.fulfill()

        
        
        sleep(3)
    
        print("disconnect")
        
        client?.disconnect()
        
        expectation.fulfill()

        
        
        sleep(3)
        
        print("stop")

        try server?.stop()
            
        expectation.fulfill()
        
        sleep(3)
            
        server = nil
        client = nil
            
        wait(for: [expectation], timeout: 35.0)
    }
}
