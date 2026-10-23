import Foundation
import ModelsR4
import ModelsR4B
import ModelsR5

/// Wire versions supported by the bounded PACS adapter, not a general FHIR converter.
public enum FHIRRelease: String, Codable, CaseIterable, Sendable {
    case r4 = "4.0.1", r4b = "4.3.0", r5 = "5.0.0"
    public var pathComponent: String { switch self { case .r4: return "R4"; case .r4b: return "R4B"; case .r5: return "R5" } }
}

public struct FHIRPACSConversionError: Error, LocalizedError, Sendable {
    public let path: String
    public let reason: String
    public var errorDescription: String? { "\(path): \(reason)" }
}

/// Loss-detecting adapter for PACS resources. R4 is an interchange representation,
/// not a clinical store. Does not validate profiles, invariants or terminology.
/// Unknown/unrepresentable fields are rejected rather than silently discarded.
public enum FHIRPACSCodec {
    public static let resourceTypes: Set<String> = ["Patient", "ImagingStudy", "Endpoint", "ServiceRequest", "DiagnosticReport", "Appointment", "Task", "Procedure", "Bundle", "OperationOutcome", "CapabilityStatement"]

    public static func convert(_ data: Data, from source: FHIRRelease, to target: FHIRRelease) throws -> Data {
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw error("$", "Expected a JSON resource") }
        try checkModel(object, version: source)
        if source == target { return data }
        let r4 = source == .r5 ? try transform(object, toR5: false) : object
        var output = target == .r5 ? try transform(r4, toR5: true) : r4
        if output["resourceType"] as? String == "CapabilityStatement" { output["fhirVersion"] = target.rawValue }
        try checkModel(output, version: target)
        return try JSONSerialization.data(withJSONObject: output, options: [.sortedKeys])
    }

    private static func error(_ path: String, _ reason: String) -> FHIRPACSConversionError { .init(path: path, reason: reason) }
    private static func checkModel(_ object: [String: Any], version: FHIRRelease) throws {
        guard let type = object["resourceType"] as? String, resourceTypes.contains(type) else { throw error("$.resourceType", "Resource outside the PACS adapter scope") }
        let children = (object["contained"] as? [[String: Any]] ?? []) + (object["entry"] as? [[String: Any]] ?? []).compactMap { $0["resource"] as? [String: Any] }
        for child in children { try checkModel(child, version: version) }
        let data = try JSONSerialization.data(withJSONObject: object)
        let encoded: Data
        do {
            switch version {
            case .r4: encoded = try JSONEncoder().encode(JSONDecoder().decode(ModelsR4.ResourceProxy.self, from: data))
            case .r4b: encoded = try JSONEncoder().encode(JSONDecoder().decode(ModelsR4B.ResourceProxy.self, from: data))
            case .r5: encoded = try JSONEncoder().encode(JSONDecoder().decode(ModelsR5.ResourceProxy.self, from: data))
            }
        } catch { throw self.error("$", "Invalid \(version.pathComponent) \(type) model") }
        try preserveKeys(object, encoded: JSONSerialization.jsonObject(with: encoded), path: "$")
    }
    private static func preserveKeys(_ input: Any, encoded: Any, path: String) throws {
        if let fields = input as? [String: Any] {
            guard let result = encoded as? [String: Any] else { throw error(path, "Unrepresentable object") }
            for (key, value) in fields {
                guard let next = result[key] else { throw error(path + "." + key, "Unsupported field; conversion would discard it") }
                try preserveKeys(value, encoded: next, path: path + "." + key)
            }
        } else if let values = input as? [Any] {
            guard let result = encoded as? [Any], result.count == values.count else { throw error(path, "Unrepresentable array") }
            for (index, value) in values.enumerated() { try preserveKeys(value, encoded: result[index], path: "\(path)[\(index)]") }
        }
    }
    private static func transform(_ input: [String: Any], toR5 up: Bool) throws -> [String: Any] {
        var o = input
        let type = o["resourceType"] as? String ?? ""
        func rename(_ old: String, _ new: String) throws {
            let a = up ? old : new, b = up ? new : old
            if let value = o.removeValue(forKey: a) {
                guard o[b] == nil else { throw error("$." + b, "Conflicting version-specific fields") }
                o[b] = value
            }
        }
        func concept(_ value: Any, path: String) throws -> Any {
            if up { return ["concept": value] }
            guard let item = value as? [String: Any], Set(item.keys) == ["concept"], let content = item["concept"] else {
                throw error(path, "Only an inline concept can be represented by this PACS interaction")
            }
            return content
        }
        func reference(_ value: Any, path: String) throws -> Any {
            if up { return ["reference": value] }
            guard let item = value as? [String: Any], Set(item.keys) == ["reference"], let content = item["reference"] as? [String: Any] else {
                throw error(path, "Only a reference can be represented by this PACS interaction")
            }
            return content
        }
        func coding(_ value: Any, path: String) throws -> Any {
            if up { return ["coding": [value]] }
            guard let item = value as? [String: Any], Set(item.keys) == ["coding"], let codes = item["coding"] as? [Any], codes.count == 1 else {
                throw error(path, "Exactly one coding is required for lossless conversion")
            }
            return codes[0]
        }
        func reasons(_ oldCode: String = "reasonCode", _ oldReference: String = "reasonReference", _ new: String = "reason", single: Bool = false, singleReference: Bool = false) throws {
            if up {
                var values: [[String: Any]] = []
                if let value = o.removeValue(forKey: oldCode) {
                    values += (single ? [value] : value as? [Any] ?? []).map { ["concept": $0] }
                }
                if let value = o.removeValue(forKey: oldReference) {
                    values += ((single || singleReference) ? [value] : value as? [Any] ?? []).map { ["reference": $0] }
                }
                if !values.isEmpty { guard o[new] == nil else { throw error("$." + new, "Conflicting fields") }; o[new] = values }
            } else if let values = o.removeValue(forKey: new) as? [[String: Any]] {
                var codes: [Any] = [], references: [Any] = []
                for item in values {
                    guard item.count == 1 else { throw error("$." + new, "Combined concepts/references cannot be split without loss") }
                    if let value = item["concept"] { codes.append(value) }
                    else if let value = item["reference"] { references.append(value) }
                    else { throw error("$." + new, "Unsupported CodeableReference") }
                }
                guard (!single || codes.count <= 1) && (!(single || singleReference) || references.count <= 1) else { throw error("$." + new, "R4 cardinality exceeded") }
                if !codes.isEmpty { o[oldCode] = single ? codes[0] : codes }
                if !references.isEmpty { o[oldReference] = (single || singleReference) ? references[0] : references }
            }
        }
        switch type {
        case "ServiceRequest":
            if let value = o["code"] { o["code"] = try concept(value, path: "$.code") }
            if let values = o["supportingInfo"] as? [Any] { o["supportingInfo"] = try values.map { try reference($0, path: "$.supportingInfo") } }
            try reasons(); try reasons("locationCode", "locationReference", "location")
        case "ImagingStudy":
            if let values = o["modality"] as? [Any] { o["modality"] = try values.map { try coding($0, path: "$.modality") } }
            if let values = o["series"] as? [[String: Any]] {
                o["series"] = try values.map { original in
                    var item = original
                    if let v = item["modality"] { item["modality"] = try coding(v, path: "$.series.modality") }
                    if let v = item["laterality"] { item["laterality"] = try coding(v, path: "$.series.laterality") }
                    if let v = item["bodySite"] {
                        item["bodySite"] = up ? ["concept": try coding(v, path: "$.series.bodySite")] : try coding(concept(v, path: "$.series.bodySite"), path: "$.series.bodySite")
                    }
                    return item
                }
            }
            try reasons(); try reasons("procedureCode", "procedureReference", "procedure", singleReference: true)
        case "DiagnosticReport":
            try rename("imagingStudy", "study")
            if !up, let refs = o["imagingStudy"] as? [[String: Any]], refs.contains(where: { ($0["reference"] as? String)?.contains("ImagingSelection/") == true }) {
                throw error("$.study", "ImagingSelection is outside the PACS adapter scope")
            }
        case "Endpoint":
            if up {
                if let value = o["connectionType"] { o["connectionType"] = [try coding(value, path: "$.connectionType")] }
                var payload: [String: Any] = [:]
                payload["type"] = o.removeValue(forKey: "payloadType")
                payload["mimeType"] = o.removeValue(forKey: "payloadMimeType")
                if !payload.isEmpty { o["payload"] = [payload] }
            } else {
                guard let connections = o["connectionType"] as? [Any], connections.count == 1 else { throw error("$.connectionType", "One connection type required") }
                o["connectionType"] = try coding(connections[0], path: "$.connectionType")
                if let payload = o.removeValue(forKey: "payload") as? [[String: Any]] {
                    guard payload.count == 1, Set(payload[0].keys).isSubset(of: ["type", "mimeType"]) else { throw error("$.payload", "One simple payload required") }
                    o["payloadType"] = payload[0]["type"]; o["payloadMimeType"] = payload[0]["mimeType"]
                }
            }
        case "Appointment":
            try rename("cancelationReason", "cancellationReason")
            if let values = o["serviceType"] as? [Any] { o["serviceType"] = try values.map { try concept($0, path: "$.serviceType") } }
            try reasons()
            if up, let value = o.removeValue(forKey: "comment") { o["note"] = [["text": value]] }
            else if !up, let notes = o.removeValue(forKey: "note") as? [[String: Any]] {
                guard notes.count == 1, Set(notes[0].keys) == ["text"] else { throw error("$.note", "One plain note required") }
                o["comment"] = notes[0]["text"]
            }
        case "Task":
            try reasons(single: true)
            if up, let values = o.removeValue(forKey: "performerType") as? [Any] { o["requestedPerformer"] = values.map { ["concept": $0] } }
            else if !up, let values = o.removeValue(forKey: "requestedPerformer") as? [Any] { o["performerType"] = try values.map { try concept($0, path: "$.requestedPerformer") } }
        case "Procedure":
            for suffix in ["DateTime", "Period", "Age", "Range", "String"] { try rename("performed" + suffix, "occurrence" + suffix); try rename("_performed" + suffix, "_occurrence" + suffix) }
            try reasons(); try reasons("usedCode", "usedReference", "used")
        case "CapabilityStatement": o["fhirVersion"] = up ? FHIRRelease.r5.rawValue : FHIRRelease.r4.rawValue
        default: break
        }
        if let values = o["contained"] as? [[String: Any]] { o["contained"] = try values.map { try transform($0, toR5: up) } }
        if type == "Bundle", let entries = o["entry"] as? [[String: Any]] {
            o["entry"] = try entries.map { original in var item = original; if let resource = item["resource"] as? [String: Any] { item["resource"] = try transform(resource, toR5: up) }; return item }
        }
        return o
    }
}
