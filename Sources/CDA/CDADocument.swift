import Foundation
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
}

/// Parses the CDA R2 document envelope while preserving a small, explicit
/// qualification boundary. It does not claim schema or template validation.
public struct CDAParser: Sendable {
    public init() {}

    public func parse(_ data: Data) throws -> CDADocument {
        let delegate = CDAXMLDelegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate

        guard parser.parse() else {
            throw CDAError.invalidXML(parser.parserError?.localizedDescription ?? "Unknown XML parser error")
        }
        guard delegate.didFindClinicalDocument else {
            throw CDAError.missingClinicalDocument
        }
        return delegate.document
    }

    public func parse(_ xml: String) throws -> CDADocument {
        try parse(Data(xml.utf8))
    }
}

private final class CDAXMLDelegate: NSObject, XMLParserDelegate {
    var document = CDADocument()
    var didFindClinicalDocument = false
    private var depth = 0
    private var titleDepth: Int?
    private var title = ""

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        defer { depth += 1 }

        if depth == 0 {
            didFindClinicalDocument = elementName == "ClinicalDocument" || elementName.hasSuffix(":ClinicalDocument")
            return
        }
        guard didFindClinicalDocument, depth == 1 else { return }

        switch elementName.split(separator: ":").last.map(String.init) ?? elementName {
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
        if titleDepth != nil {
            title += string
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        depth -= 1
        if titleDepth == depth,
           (elementName == "title" || elementName.hasSuffix(":title")) {
            document.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            titleDepth = nil
        }
    }

    private func identifier(from attributes: [String: String]) -> CDADocument.Identifier? {
        guard let root = attributes["root"], !root.isEmpty else { return nil }
        return CDADocument.Identifier(root: root, extensionValue: attributes["extension"])
    }
}
