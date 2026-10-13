import XCTest
import HL7V2

private actor TestInbox {
    var payloads: [Data] = []
    func store(_ input: V2InboundContext) -> ER7AcknowledgmentCode {
        payloads.append(input.sourceBytes)
        return .commitAccept
    }
}

final class V2InboundProcessorTests: XCTestCase {
    func testACKFollowsApplicationPersistenceAndRetainsExactPayload() async throws {
        let inbox = TestInbox()
        let processor = V2InboundProcessor(application: "PACS", facility: "HOSP", handle: { context in
            await inbox.store(context)
        })
        let data = Data("MSH|^~\\&|RIS|HOSP|PACS|HOSP|||ADT^A08|id|P|99.vendor\nPID|||123^^^HOSP\n".utf8)
        let ack = try await processor.process(data)
        let stored = await inbox.payloads
        XCTAssertEqual(stored, [data])
        XCTAssertEqual(ack.segment("MSA")?[1], "CA")
        XCTAssertEqual(ack.segment("MSA")?[2], "id")
        XCTAssertEqual(ack.declaredVersion, "99.vendor")
    }

    func testInvalidClinicalContractDoesNotCallInbox() async throws {
        let inbox = TestInbox()
        let processor = V2InboundProcessor(application: "PACS", facility: "HOSP", handle: { context in
            await inbox.store(context)
        })
        let ack = try await processor.process(Data("MSH|^~\\&|||||||ADT^A08|id|P|2.5.1\r".utf8))
        XCTAssertEqual(ack.segment("MSA")?[1], "AR")
        let stored = await inbox.payloads
        XCTAssertTrue(stored.isEmpty)
    }

    func testFailedPersistenceCannotProducePositiveACK() async throws {
        enum StorageError: Error { case unavailable }
        let processor = V2InboundProcessor(application: "PACS", facility: "HOSP", handle: { _ in
            throw StorageError.unavailable
        })
        do {
            _ = try await processor.process(Data("MSH|^~\\&|||||||ADT^A08|id|P|2.5.1\rPID|||123\r".utf8))
            XCTFail("Storage failure acknowledged")
        } catch StorageError.unavailable { }
    }
}
