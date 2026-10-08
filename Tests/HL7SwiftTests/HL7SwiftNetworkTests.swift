//
//  File.swift
//  
//
//  Created by Rafael Warnault on 24/01/2022.
//

import Foundation
import NIO
import XCTest
import HL7Swift
@testable import HL7Swift


private final class NetworkTestDelegate: HL7ServerDelegate {
    var onStart: (() -> Void)?
    var onStop: (() -> Void)?

    func server(serverStarted server: HL7Server) {
        onStart?()
    }

    func server(serverStopped server: HL7Server) {
        onStop?()
    }

    func server(_ server: HL7Server, receive message: Message, from: String?, channel: Channel) {}
    func server(_ server: HL7Server, send message: Message, to: String?, channel: Channel) {}
    func server(_ server: HL7Server, ACKStatusFor message: Message, channel: Channel) -> AcknowledgeStatus { .AA }
    func server(_ server: HL7Server, channelDidBecomeActive channel: Channel) {}
    func server(_ server: HL7Server, channelDidBecomeInactive channel: Channel) {}
}


final class HL7SwiftNetworkTests: XCTestCase {
    private let testPort = 27_777
    var hl7: HL7!
    var config: ClientConfiguration!
    
    override func setUpWithError() throws {
        try super.setUpWithError()

        Logger.setMaxLevel(.ERROR)
        self.hl7 = try HL7()
        
        self.config = ClientConfiguration(self.hl7)
        self.config.host = "127.0.0.1"
        self.config.port = testPort
    }

    private func makeServer(delegate: HL7ServerDelegate? = nil) throws -> HL7Server {
        var serverConfig = ServerConfiguration(hl7)
        serverConfig.host = "127.0.0.1"
        serverConfig.port = testPort
        return try HL7Server(serverConfig, delegate: delegate)
    }

    private func start(_ server: HL7Server, delegate: NetworkTestDelegate) {
        let started = expectation(description: "Server started")
        delegate.onStart = { started.fulfill() }

        DispatchQueue.global().async {
            do {
                try server.start()
            } catch {
                XCTFail("Server failed: \(error)")
            }
        }

        wait(for: [started], timeout: 10.0)
    }

    func testServerListen() throws {
        let delegate = NetworkTestDelegate()
        let server = try makeServer(delegate: delegate)

        start(server, delegate: delegate)
        try server.stop()
    }

    func testClientConnect() throws {
        let delegate = NetworkTestDelegate()
        let server = try makeServer(delegate: delegate)
        let client = try HL7CLient(config)

        start(server, delegate: delegate)
        defer {
            client.disconnect()
            try? server.stop()
        }
        try client.connect().wait()
    }
    
    
    func testSendAllTestMessages() throws {
        let paths = Bundle.module.paths(forResourcesOfType: "txt", inDirectory: nil)

        let delegate = NetworkTestDelegate()
        let server = try makeServer(delegate: delegate)
        let client = try HL7CLient(config)

        start(server, delegate: delegate)
        defer {
            client.disconnect()
            try? server.stop()
        }
        try client.connect().wait()

        for path in paths {
            let content = try String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8)
            let message = try Message(content, hl7: hl7)

            let response = try XCTUnwrap(client.send(message), "No response for \(path)")
            XCTAssertTrue(response.type.name.hasPrefix("ACK"), "Unexpected response for \(path)")
        }

    }
}
