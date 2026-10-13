import Foundation

/// Handwritten implementation metadata for the compatibility API's common
/// field access and construction. This is not a converted schema or an embedded
/// specification. Detailed validation lives in the native HL7V2 APIs.
enum NativeV2Models {
    static let fieldNames: [String: [Int: String]] = [
        "MSH": [1: "Field Separator", 2: "Encoding Characters", 3: HL7.Sending_Application,
            4: HL7.Sending_Facility, 5: HL7.Receiving_Application, 6: HL7.Receiving_Facility,
            7: "Date/Time of Message", 9: HL7.Message_Type, 10: HL7.Message_Control_ID,
            11: "Processing ID", 12: HL7.Version_ID, 15: "Accept Acknowledgment Type",
            16: "Application Acknowledgment Type", 18: HL7.Character_Set],
        "MSA": [1: HL7.Acknowledgment_Code, 2: HL7.Message_Control_ID, 3: "Text Message"],
        "PID": [3: HL7.Patient_Identifier_List, 5: HL7.Patient_Name, 7: HL7.Date_Time_of_Birth,
            8: "Administrative Sex", 11: "Patient Address", 13: "Phone Number - Home",
            14: "Phone Number - Business", 18: "Patient Account Number"],
        "PV1": [2: "Patient Class", 3: "Assigned Patient Location", 7: "Attending Doctor", 19: "Visit Number", 44: "Admit Date/Time", 45: "Discharge Date/Time"],
        "ORC": [1: HL7.Order_Control, 2: HL7.Placer_Order_Number, 3: HL7.Filler_Order_Number, 5: "Order Status", 9: "Date/Time of Transaction", 12: "Ordering Provider"],
        "OBR": [2: HL7.Placer_Order_Number, 3: HL7.Filler_Order_Number, 4: HL7.Universal_Service_Identifier,
            7: "Observation Date/Time", 16: "Ordering Provider", 18: "Placer Field 1", 25: "Result Status"],
        "OBX": [2: "Value Type", 3: "Observation Identifier", 5: "Observation Value", 6: "Units", 11: "Observation Result Status", 14: "Date/Time of the Observation"],
        "MRG": [1: "Prior Patient Identifier List"], "EVN": [2: "Recorded Date/Time"],
        "NTE": [3: "Comment"], "TXA": [2: "Document Type", 12: "Unique Document Number", 17: "Document Completion Status"],
        "ERR": [7: HL7.Diagnostic_Information, 8: HL7.User_Message],
        "IPC": [1: "Accession Identifier", 2: "Requested Procedure ID", 3: "Study Instance UID", 4: "Scheduled Procedure Step ID", 5: "Modality", 9: "Scheduled AE Title"]
    ]

    static func segment(_ code: String, owner: SpecMessage) -> Segment {
        let names = fieldNames[code] ?? [:]
        let count = names.keys.max() ?? 1
        let wire = code == "MSH" ? "MSH|^~\\&" + String(repeating: "|", count: count - 2) : code + String(repeating: "|", count: count)
        let segment = Segment(wire, parent: owner.rootGroup, specMessage: owner)
        for field in segment.sortedFields {
            field.longName = names[field.index] ?? ""
            field.maxLength = -1; field.maxOccurs = -1
        }
        segment.minOccurs = code == "MSH" ? 1 : 0
        return segment
    }

    static func install(on model: Versioned) {
        let adtEvents = ["A01", "A02", "A03", "A04", "A05", "A08", "A28", "A31", "A40"]
        let families: [(String, [String])] = [
            ("ACK", ["MSH", "MSA", "ERR"]),
            ("ORM_O01", ["MSH", "PID", "PV1", "ORC", "OBR", "OBX", "NTE"]),
            ("OMI_O23", ["MSH", "PID", "PV1", "ORC", "OBR", "IPC", "OBX", "NTE"]),
            ("ORU_R01", ["MSH", "PID", "PV1", "ORC", "OBR", "OBX", "NTE"]),
            ("MDM_T02", ["MSH", "EVN", "PID", "PV1", "TXA", "OBX", "NTE"])
        ] + adtEvents.map { ("ADT_" + $0, ["MSH", "EVN", "PID", "PV1", "MRG", "NTE"]) }
        for (name, codes) in families {
            let owner = SpecMessage(type: model.type(forName: name) ?? HL7.MessageType(name: name), version: model.version)
            for code in codes {
                let item = segment(code, owner: owner)
                owner.rootGroup.items.append(.segment(item))
                owner.rootGroup.segments.append(item)
            }
            model.messages[name] = owner
        }
    }
}
