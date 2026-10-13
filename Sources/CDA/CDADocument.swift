import Foundation
@_exported import HL7Core
#if canImport(FoundationXML)
import FoundationXML
#endif

/// Minimal CDA R2 document metadata.
///
/// This deliberately models the stable document envelope first. Clinical
/// sections and entries can be added without introducing the complete HL7 v3
/// RIM into the public API.
public struct CDADocument: Equatable, Sendable {
    public struct Identifier: Equatable, Sendable {
        public var root: String
        public var extensionValue: String?

        public init(root: String, extensionValue: String? = nil) {
            self.root = root
            self.extensionValue = extensionValue
        }
    }

    public var identifier: Identifier?
    public var templateIdentifiers: [Identifier]
    public var typeCode: String?
    public var typeCodeSystem: String?
    public var title: String?
    public var effectiveTime: String?
    public var confidentialityCode: String?
    public var languageCode: String?
    public var recordTargets: [CDARecordTarget] = []
    public var sections: [CDASection] = []

    public init(
        identifier: Identifier? = nil,
        templateIdentifiers: [Identifier] = [],
        typeCode: String? = nil,
        typeCodeSystem: String? = nil,
        title: String? = nil,
        effectiveTime: String? = nil,
        confidentialityCode: String? = nil,
        languageCode: String? = nil
    ) {
        self.identifier = identifier
        self.templateIdentifiers = templateIdentifiers
        self.typeCode = typeCode
        self.typeCodeSystem = typeCodeSystem
        self.title = title
        self.effectiveTime = effectiveTime
        self.confidentialityCode = confidentialityCode
        self.languageCode = languageCode
    }
}

public enum CDAError: Error, Equatable, Sendable {
    case invalidXML(String)
    case missingClinicalDocument
    case invalidNamespace
    case prohibitedDeclaration
    case resourceLimit
}

/// The parsed envelope, if available, and the scope of the checks performed.
public struct CDAParseResult: Equatable, Sendable {
    public let document: CDADocument?
    public let report: HL7DiagnosticReport

    public init(document: CDADocument?, report: HL7DiagnosticReport) {
        self.document = document
        self.report = report
    }
}

/// Parses the CDA R2 document envelope while preserving a small, explicit
/// qualification boundary. It does not claim schema or template validation.
public struct CDAParser: Sendable {
    public let maximumBytes: Int
    public let maximumDepth: Int
    public init(maximumBytes: Int = 16 * 1024 * 1024, maximumDepth: Int = 128) {
        precondition(maximumBytes > 0 && maximumDepth > 0)
        self.maximumBytes = maximumBytes; self.maximumDepth = maximumDepth
    }

    /// Parses the current envelope model and reports its explicit limits.
    /// The XML and root-name stages do not imply CDA R2 schema conformance.
    public func parseWithReport(_ data: Data) -> CDAParseResult {
        let unrunStages: [HL7ValidationStage] = [
            .init(identifier: "cda.schema", status: .notRun),
            .init(identifier: "cda.templates", status: .notRun),
            .init(identifier: "cda.narrative", status: .notRun),
        ]

        do {
            let document = try parse(data)
            return CDAParseResult(
                document: document,
                report: HL7DiagnosticReport(stages: [
                    .init(identifier: "cda.xml", status: .complete),
                    .init(identifier: "cda.root-name", status: .complete),
                    .init(identifier: "cda.namespace", status: .complete),
                    .init(identifier: "cda.xml-security", status: .complete),
                    .init(identifier: "cda.envelope", status: .incomplete),
                ] + unrunStages)
            )
        } catch {
            let code: String
            let message: String
            let stage: String
            let causeCode: String
            let xmlStatus: HL7ValidationStageStatus
            let rootStatus: HL7ValidationStageStatus
            let namespaceStatus: HL7ValidationStageStatus
            let securityStatus: HL7ValidationStageStatus

            if case CDAError.missingClinicalDocument = error {
                code = "CDA-ROOT-NAME-MISSING"
                message = "The document root is not ClinicalDocument."
                stage = "cda.root-name"
                causeCode = "ROOT_NAME_MISMATCH"
                xmlStatus = .complete
                rootStatus = .incomplete
                namespaceStatus = .notRun
                securityStatus = .complete
            } else if case CDAError.invalidNamespace = error {
                code = "CDA-NAMESPACE-MISMATCH"
                message = "The ClinicalDocument root is not in the CDA namespace."
                stage = "cda.namespace"
                causeCode = "NAMESPACE_MISMATCH"
                xmlStatus = .complete
                rootStatus = .complete
                namespaceStatus = .incomplete
                securityStatus = .complete
            } else if case CDAError.prohibitedDeclaration = error {
                code = "CDA-XML-DECLARATION-FORBIDDEN"
                message = "DTD and entity declarations are not accepted."
                stage = "cda.xml-security"
                causeCode = "XML_DECLARATION_FORBIDDEN"
                xmlStatus = .incomplete
                rootStatus = .notRun
                namespaceStatus = .notRun
                securityStatus = .incomplete
            } else {
                code = "CDA-XML-PARSE-FAILED"
                message = "The XML document could not be parsed."
                stage = "cda.xml"
                causeCode = "XML_PARSE_FAILED"
                xmlStatus = .incomplete
                rootStatus = .notRun
                namespaceStatus = .notRun
                securityStatus = .incomplete
            }

            return CDAParseResult(
                document: nil,
                report: HL7DiagnosticReport(stages: [
                    .init(identifier: "cda.xml", status: xmlStatus),
                    .init(identifier: "cda.root-name", status: rootStatus),
                    .init(identifier: "cda.namespace", status: namespaceStatus),
                    .init(identifier: "cda.xml-security", status: securityStatus),
                    .init(identifier: "cda.envelope", status: .notRun),
                ] + unrunStages, diagnostics: [HL7Diagnostic(
                    code: code,
                    severity: .error,
                    message: message,
                    standard: .cda,
                    stage: stage,
                    version: "R2",
                    location: .init(path: "/ClinicalDocument"),
                    causeCode: causeCode
                )])
            )
        }
    }

    public func parseWithReport(_ xml: String) -> CDAParseResult {
        parseWithReport(Data(xml.utf8))
    }

    public func parse(_ data: Data) throws -> CDADocument {
        guard data.count <= maximumBytes else { throw CDAError.resourceLimit }
        if Self.containsDoctype(data) {
            throw CDAError.prohibitedDeclaration
        }
        let delegate = CDAXMLDelegate(maximumDepth: maximumDepth)
        let parser = XMLParser(data: data)
        parser.shouldProcessNamespaces = true
        parser.shouldResolveExternalEntities = false
        parser.externalEntityResolvingPolicy = .never
        parser.allowedExternalEntityURLs = []
        parser.delegate = delegate

        let parsed = parser.parse()
        // FoundationXML on Linux may recover a malformed tree and still return
        // true. Treat any recorded parser error or unclosed root as a failure.
        guard parsed, parser.parserError == nil, delegate.didCloseRoot else {
            if delegate.sawLimitExceeded { throw CDAError.resourceLimit }
            if delegate.sawProhibitedEntityDeclaration {
                throw CDAError.prohibitedDeclaration
            }
            throw CDAError.invalidXML(parser.parserError?.localizedDescription ?? "Unknown XML parser error")
        }
        guard delegate.didFindRootName else {
            throw CDAError.missingClinicalDocument
        }
        guard delegate.didFindCDANamespace else {
            throw CDAError.invalidNamespace
        }
        return delegate.document
    }

    public func parse(_ xml: String) throws -> CDADocument {
        try parse(Data(xml.utf8))
    }

    /// Fail closed for DTDs before XMLParser processes them. External entity
    /// callbacks are not guaranteed when entity resolution is disabled.
    /// These byte patterns cover UTF-8/ASCII-compatible, UTF-16 and UTF-32 XML.
    private static func containsDoctype(_ data: Data) -> Bool {
        let marker = Array("<!DOCTYPE".utf8)
        let bytePatterns: [[UInt8]] = [
            marker,
            marker.flatMap { [0, $0] },
            marker.flatMap { [$0, 0] },
            marker.flatMap { [0, 0, 0, $0] },
            marker.flatMap { [$0, 0, 0, 0] },
        ]
        return bytePatterns.contains { data.range(of: Data($0)) != nil }
    }
}

private final class CDAXMLDelegate: NSObject, XMLParserDelegate {
    private static let cdaNamespace = "urn:hl7-org:v3"

    var document = CDADocument()
    var didFindRootName = false
    var didFindCDANamespace = false
    var didCloseRoot = false
    var sawProhibitedEntityDeclaration = false
    var sawLimitExceeded = false
    let maximumDepth: Int
    init(maximumDepth: Int) { self.maximumDepth = maximumDepth }
    private var depth = 0
    private var titleDepth: Int?
    private var title = ""
    private var path: [String] = []
    private var namespaces: [String?] = []
    private var recordTargetIndex: Int?
    private var sectionStack: [(index: Int, depth: Int)] = []
    private var capture: (kind: String, depth: Int, text: String)?
    private var narrativeDepth: Int?

    func parser(
        _ parser: XMLParser,
        foundInternalEntityDeclarationWithName name: String,
        value: String?
    ) {
        rejectEntityDeclaration(parser)
    }

    func parser(
        _ parser: XMLParser,
        foundExternalEntityDeclarationWithName name: String,
        publicID: String?,
        systemID: String?
    ) {
        rejectEntityDeclaration(parser)
    }

    private func rejectEntityDeclaration(_ parser: XMLParser) {
        sawProhibitedEntityDeclaration = true
        parser.abortParsing()
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        guard depth < maximumDepth else {
            sawLimitExceeded = true
            parser.abortParsing()
            return
        }
        path.append(elementName)
        namespaces.append(namespaceURI)
        defer { depth += 1 }
        readClinicalStart(elementName, namespaceURI: namespaceURI, attributes: attributeDict)

        if depth == 0 {
            didFindRootName = elementName == "ClinicalDocument"
            didFindCDANamespace = namespaceURI == Self.cdaNamespace
            return
        }
        guard didFindRootName, didFindCDANamespace,
              depth == 1, namespaceURI == Self.cdaNamespace else { return }

        switch elementName {
        case "templateId":
            if let identifier = identifier(from: attributeDict) {
                document.templateIdentifiers.append(identifier)
            }
        case "id":
            document.identifier = identifier(from: attributeDict)
        case "code":
            document.typeCode = attributeDict["code"]
            document.typeCodeSystem = attributeDict["codeSystem"]
        case "title":
            titleDepth = depth
            title = ""
        case "effectiveTime":
            document.effectiveTime = attributeDict["value"]
        case "confidentialityCode":
            document.confidentialityCode = attributeDict["code"]
        case "languageCode":
            document.languageCode = attributeDict["code"]
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard namespaces.allSatisfy({ $0 == Self.cdaNamespace }) else { return }
        if titleDepth != nil {
            title += string
        }
        if capture != nil { capture?.text += string }
        if narrativeDepth != nil, let current = sectionStack.last {
            document.sections[current.index].narrativeText += string
        }
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        if let text = String(data: CDATABlock, encoding: .utf8) { self.parser(parser, foundCharacters: text) }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        guard !sawLimitExceeded, !path.isEmpty else { return }
        depth -= 1
        if depth == 0 { didCloseRoot = true }
        defer { path.removeLast(); namespaces.removeLast() }
        readClinicalEnd(elementName, namespaceURI: namespaceURI)
        if titleDepth == depth,
           elementName == "title", namespaceURI == Self.cdaNamespace {
            document.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            titleDepth = nil
        }
    }

    private func readClinicalStart(_ name: String, namespaceURI: String?, attributes: [String: String]) {
        guard namespaces.allSatisfy({ $0 == Self.cdaNamespace }) else { return }
        if path == ["ClinicalDocument", "recordTarget", "patientRole"] {
            document.recordTargets.append(.init())
            recordTargetIndex = document.recordTargets.count - 1
        }
        if let index = recordTargetIndex {
            let base = ["ClinicalDocument", "recordTarget", "patientRole"]
            if path == base + ["id"], let id = identifier(from: attributes) {
                document.recordTargets[index].identifiers.append(id)
            } else if path == base + ["patient", "name"] {
                document.recordTargets[index].names.append(.init())
            } else if path == base + ["patient", "birthTime"] {
                document.recordTargets[index].birthTime = attributes["value"]
            } else if path == base + ["patient", "administrativeGenderCode"] {
                document.recordTargets[index].administrativeGenderCode = attributes["code"]
            } else if ["given", "family", "prefix", "suffix"].contains(name), path == base + ["patient", "name", name] {
                capture = (name, depth, "")
            }
        }
        if name == "section", path.prefix(4) == ["ClinicalDocument", "component", "structuredBody", "component"],
           path.dropLast().last == "component", depth == 4 || depth == (sectionStack.last?.depth ?? -100) + 2 {
            let index = document.sections.count
            document.sections.append(.init(parentIndex: sectionStack.last?.index))
            sectionStack.append((index, depth))
        }
        if let current = sectionStack.last, depth == current.depth + 1 {
            switch name {
            case "id": document.sections[current.index].identifier = identifier(from: attributes)
            case "templateId":
                if let id = identifier(from: attributes) { document.sections[current.index].templateIdentifiers.append(id) }
            case "code":
                document.sections[current.index].code = attributes["code"]
                document.sections[current.index].codeSystem = attributes["codeSystem"]
            case "title": capture = ("sectionTitle", depth, "")
            case "text": narrativeDepth = depth
            case "entry": document.sections[current.index].entryCount += 1
            default: break
            }
        }
        if narrativeDepth != nil, let current = sectionStack.last, ["br", "paragraph", "item", "tr"].contains(name) {
            document.sections[current.index].narrativeText += "\n"
        }
    }

    private func readClinicalEnd(_ name: String, namespaceURI: String?) {
        if let captured = capture, captured.depth == depth {
            let text = captured.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if captured.kind == "sectionTitle", let current = sectionStack.last {
                document.sections[current.index].title = text
            } else if let index = recordTargetIndex, let last = document.recordTargets[index].names.indices.last {
                switch captured.kind {
                case "given": document.recordTargets[index].names[last].given.append(text)
                case "family": document.recordTargets[index].names[last].family.append(text)
                case "prefix": document.recordTargets[index].names[last].prefix.append(text)
                case "suffix": document.recordTargets[index].names[last].suffix.append(text)
                default: break
                }
            }
            capture = nil
        }
        if narrativeDepth == depth {
            if let current = sectionStack.last {
                document.sections[current.index].narrativeText = document.sections[current.index].narrativeText.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            narrativeDepth = nil
        }
        if sectionStack.last?.depth == depth { sectionStack.removeLast() }
        if path == ["ClinicalDocument", "recordTarget", "patientRole"] { recordTargetIndex = nil }
    }

    private func identifier(from attributes: [String: String]) -> CDADocument.Identifier? {
        guard let root = attributes["root"], !root.isEmpty else { return nil }
        return CDADocument.Identifier(root: root, extensionValue: attributes["extension"])
    }
}
