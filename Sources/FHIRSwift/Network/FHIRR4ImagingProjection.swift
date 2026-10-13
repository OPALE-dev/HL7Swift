import Foundation
import ModelsR4

/// Metadata snapshot, not a DICOM parser. `instances == nil` means not loaded;
/// an array means the complete instance list for this represented series.
public struct FHIRR4ImagingSeriesInput {
    public let uid: String
    public let modality: String
    public let instances: [FHIRR4ImagingInstanceInput]?
    public init(uid: String, modality: String, instances: [FHIRR4ImagingInstanceInput]? = nil) {
        self.uid = uid; self.modality = modality; self.instances = instances
    }
}

public struct FHIRR4ImagingInstanceInput {
    public let uid: String
    public let sopClassUID: String
    public init(uid: String, sopClassUID: String) { self.uid = uid; self.sopClassUID = sopClassUID }
}

public enum FHIRR4ImagingProjectionError: Error {
    case invalidIdentifier, invalidUID, invalidModality, duplicateUID, invalidEndpoint
}

/// Explicit PACS exchange projection. Does not read DICOM, resolve patients,
/// infer availability, assign resource identities or generate XHTML narrative.
public enum FHIRR4ImagingProjection {
    /// `series == nil` leaves series/counts unknown. Supplied series and instance
    /// arrays describe the complete represented subset; counts reflect that
    /// subset, never the number of frames or an unauthorized whole-study total.
    public static func imagingStudy(id: String, studyUID: String, patientID: String,
                                    status: ImagingStudyStatus, endpointIDs: [String] = [],
                                    started: DateTime? = nil, description: String? = nil,
                                    series: [FHIRR4ImagingSeriesInput]? = nil) throws -> ImagingStudy {
        guard validID(id), validID(patientID), endpointIDs.allSatisfy(validID),
              Set(endpointIDs).count == endpointIDs.count else { throw FHIRR4ImagingProjectionError.invalidIdentifier }
        guard validUID(studyUID) else { throw FHIRR4ImagingProjectionError.invalidUID }
        let subject = Reference(); subject.reference = .init(FHIRString("Patient/" + patientID))
        let result = ImagingStudy(status: .init(status), subject: subject)
        result.id = .init(FHIRString(id))
        let identifier = Identifier(); identifier.system = .init(FHIRURI(stringLiteral: "urn:dicom:uid"))
        identifier.value = .init(FHIRString("urn:oid:" + studyUID)); result.identifier = [identifier]
        if !endpointIDs.isEmpty {
            result.endpoint = endpointIDs.map { id in
                let reference = Reference(); reference.reference = .init(FHIRString("Endpoint/" + id)); return reference
            }
        }
        if let started { result.started = .init(started) }
        if let description, !description.isEmpty { result.description_fhir = .init(FHIRString(description)) }
        if let series {
            guard series.count <= 10000 else { throw FHIRR4ImagingProjectionError.invalidIdentifier }
            var seriesUIDs = Set<String>(); var instanceUIDs = Set<String>()
            result.series = try series.map { input in
                guard validUID(input.uid) else { throw FHIRR4ImagingProjectionError.invalidUID }
                guard seriesUIDs.insert(input.uid).inserted else { throw FHIRR4ImagingProjectionError.duplicateUID }
                guard !input.modality.isEmpty, input.modality.utf8.count <= 16,
                      input.modality.allSatisfy({ $0.isASCII && ($0.isUppercase || $0.isNumber || $0 == "_") }) else {
                    throw FHIRR4ImagingProjectionError.invalidModality
                }
                let modality = Coding(); modality.system = .init(FHIRURI(stringLiteral: "http://dicom.nema.org/resources/ontology/DCM"))
                modality.code = .init(FHIRString(input.modality))
                let output = ImagingStudySeries(modality: modality, uid: .init(FHIRString(input.uid)))
                if let instances = input.instances {
                    guard instances.count <= 100000 else { throw FHIRR4ImagingProjectionError.invalidIdentifier }
                    output.instance = try instances.map { instance in
                        guard validUID(instance.uid), validUID(instance.sopClassUID) else { throw FHIRR4ImagingProjectionError.invalidUID }
                        guard instanceUIDs.insert(instance.uid).inserted else { throw FHIRR4ImagingProjectionError.duplicateUID }
                        let sopClass = Coding(); sopClass.system = .init(FHIRURI(stringLiteral: "urn:ietf:rfc:3986"))
                        sopClass.code = .init(FHIRString("urn:oid:" + instance.sopClassUID))
                        return ImagingStudySeriesInstance(sopClass: sopClass, uid: .init(FHIRString(instance.uid)))
                    }
                    output.numberOfInstances = .init(FHIRUnsignedInteger(Int32(instances.count)))
                    if instances.isEmpty { output.instance = nil }
                }
                return output
            }
            result.numberOfSeries = .init(FHIRUnsignedInteger(Int32(series.count)))
            if series.isEmpty { result.series = nil }
            if series.allSatisfy({ $0.instances != nil }) {
                let count = series.reduce(0) { $0 + ($1.instances?.count ?? 0) }
                guard count <= Int(Int32.max) else { throw FHIRR4ImagingProjectionError.invalidIdentifier }
                result.numberOfInstances = .init(FHIRUnsignedInteger(Int32(count)))
            }
            var modalities = Set<String>()
            result.modality = result.series?.compactMap { item in
                guard let code = item.modality.code?.value?.string, modalities.insert(code).inserted else { return nil }
                return item.modality
            }
        }
        return result
    }

    /// Public service base only, never embedded credentials or bearer headers.
    /// HTTPS by default; HTTP must be explicitly enabled for local deployments.
    public static func wadoRSEndpoint(id: String, address: URL, status: EndpointStatus,
                                      name: String? = nil, allowHTTP: Bool = false) throws -> Endpoint {
        guard validID(id) else { throw FHIRR4ImagingProjectionError.invalidIdentifier }
        guard address.host != nil, address.user == nil, address.password == nil,
              address.query == nil, address.fragment == nil,
              address.scheme == "https" || (allowHTTP && address.scheme == "http") else {
            throw FHIRR4ImagingProjectionError.invalidEndpoint
        }
        let connection = Coding(); connection.system = .init(FHIRURI(stringLiteral: "http://terminology.hl7.org/CodeSystem/endpoint-connection-type"))
        connection.code = .init(FHIRString("dicom-wado-rs"))
        let payload = CodeableConcept(); payload.text = .init(FHIRString("DICOM WADO-RS"))
        let endpoint = Endpoint(address: .init(FHIRURI(stringLiteral: address.absoluteString)),
                                connectionType: connection, payloadType: [payload], status: .init(status))
        endpoint.id = .init(FHIRString(id)); endpoint.payloadMimeType = ["application/dicom"]
        if let name, !name.isEmpty { endpoint.name = .init(FHIRString(name)) }
        return endpoint
    }

    private static func validID(_ value: String) -> Bool {
        !value.isEmpty && value != "." && value != ".." && value.utf8.count <= 64 && value.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-" || $0 == ".") }
    }
    private static func validUID(_ value: String) -> Bool {
        let components = value.split(separator: ".", omittingEmptySubsequences: false)
        return !value.isEmpty && value.utf8.count <= 64 && components.count >= 2
            && components.allSatisfy { !$0.isEmpty && ($0.count == 1 || $0.first != "0") && $0.allSatisfy { $0.isASCII && $0.isNumber } }
    }
}
