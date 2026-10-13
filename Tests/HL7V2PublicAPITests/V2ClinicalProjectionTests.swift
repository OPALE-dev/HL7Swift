import XCTest
import HL7V2

final class V2ClinicalProjectionTests: XCTestCase {
    func testMultiplePatientsOrdersAndObservationsKeepTheirBoundaries() throws {
        let message = try ER7Message("MSH|^~\\&|||||||ORU^R01|id|P|2.5.1\rPID|||123^^^HOSP&1.2.3&ISO^MR||Été^Zoé\rORC|NW|p1^RIS|f1^PACS\rOBR|1|p1^RIS|f1^PACS|CT^Thorax\rOBX|1|TX|report||First~Second||||||F\rNTE|1||note\rOBR|2|p2^RIS|f2^PACS|MR^Brain\rOBX|2|TX|report||Third\rPID|||456^^^OTHER^MR\rOBR|1|p3^RIS||US\rOBX|1|TX|report||Fourth\r")
        let projection = V2ClinicalProjection(message)
        XCTAssertEqual(projection.patients.count, 2)
        XCTAssertEqual(projection.patients[0].identifiers.first?.universalID, "1.2.3")
        XCTAssertEqual(projection.orders.count, 3)
        XCTAssertEqual(projection.orders.map(\.patientIndex), [0, 0, 1])
        XCTAssertEqual(projection.observations.map(\.orderIndex), [0, 1, 2])
        XCTAssertEqual(projection.observations[0].rawValues, ["First", "Second"])
        XCTAssertEqual(projection.unprojectedSegmentIndices, [5])
    }

    func testMergeIsAnAssertionAndCancellationWithoutOBRIsRetained() throws {
        let projection = V2ClinicalProjection(try ER7Message("MSH|^~\\&|||||||ADT^A40|id|P|2.5.1\rPID|||123\rMRG|old^^^HOSP^MR\rORC|CA|order^RIS\r"))
        XCTAssertEqual(projection.patients.first?.priorIdentifiers.first?.value, "old")
        XCTAssertEqual(projection.orders.first?.orderControl, "CA")
        XCTAssertTrue(projection.notices.contains("V2-PATIENT-AUTHORITY-MISSING"))
        XCTAssertTrue(projection.notices.contains("V2-MERGE-REQUIRES-APPLICATION-POLICY"))
    }
}
