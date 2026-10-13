//
//  File.swift
//
//
//  Created by Rafael Warnault on 24/12/2021.
//

import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif



public struct HL7 {
    var validator:DefaultValidator
    
    // TODO: keep this static ?
    static var generator:Bool = false
    
    private var v21     :V21!
    private var v23     :V23!
    private var v231    :V231!
    private var v24     :V24!
    private var v25     :V25!
    private var v251    :V251!
    private var v26     :V26!
    private var v27     :V27!
    private var v271    :V271!
    private var v28     :V28!
    private var v281    :V281!
    private var v282    :V282!
    
    
    /// Creates a parser which is fully usable for ER7 messages without an HL7
    /// specification bundle. Pass a caller-owned source only when structural
    /// specification features are required.
    public init() throws {
        try self.init(specificationSource: nil)
    }

    public init(specificationSource: HL7V2SpecificationSource?) throws {
        self.v21  = try V21(.v21, specificationSource: specificationSource)
        self.v23  = try V23(.v23, specificationSource: specificationSource)
        self.v231 = try V231(.v231, specificationSource: specificationSource)
        self.v24  = try V24(.v24, specificationSource: specificationSource)
        self.v25  = try V25(.v25, specificationSource: specificationSource)
        self.v251 = try V251(.v251, specificationSource: specificationSource)
        self.v26  = try V26(.v26, specificationSource: specificationSource)
        self.v27  = try V27(.v27, specificationSource: specificationSource)
        self.v271 = try V271(.v271, specificationSource: specificationSource)
        self.v28  = try V28(.v28, specificationSource: specificationSource)
        self.v281 = try V281(.v281, specificationSource: specificationSource)
        self.v282 = try V282(.v282, specificationSource: specificationSource)
        
        self.validator = DefaultValidator()
    }
    
    
    public func spec(ofVersion version: Version) -> Versioned? {
        switch version {
        case .v21:  return v21
        case .v23:  return v23
        case .v231: return v231
        case .v24:  return v24
        case .v25:  return v25
        case .v251: return v251
        case .v26:  return v26
        case .v27:  return v27
        case .v271: return v271
        case .v28:  return v28
        case .v281: return v281
        case .v282: return v282
        default:
            return nil
        }
    }
    
    // DO NOT TOUCH!!!
    struct MessageType: Typable {
        var name: String
    }

    struct UnknowMessageType: Typable {
        var name: String
    }
    
    class UnknowVersion: Versioned {
        override init(_ version: Version, specificationSource: HL7V2SpecificationSource? = nil) throws {
            try super.init(.v21, specificationSource: specificationSource)
        }
    }
}



extension HL7 {
    public func parse(_ string:String, validator inValidator:HL7Validator? = nil) throws -> Message? {
        let message = try Message(string, hl7: self)
        
        if inValidator != nil {
            guard inValidator!.validate(message, level: .version).isEmpty else {
                return nil
            }
        }
        
        return message
    }

    
    public func build(_ type:Typable, version: Version, preloadSegments: [String] = []) throws -> Message? {
        guard let spec = spec(ofVersion: version) else { return nil }
        return try Message(type, spec: spec, preloadSegments: preloadSegments)
    }


    public func validate(_ message:Message) -> [ValidationResult] {
        return validator.validate(message, level: .version)
    }
}




public protocol Typable {
    var name:String { get }
}


public protocol Versionable {
    var version:Version { get }

    func loadXML() throws
    func type(forName name:String) -> Typable?
}


public class Versioned: NSObject, Versionable {    
    public func type(forName name:String) -> Typable? {
        return nil
    }
    
    public var version: Version
    /// The caller-owned source used for this version, if any.
    public let specificationSource: HL7V2SpecificationSource?
    
    public var messages:[String:SpecMessage] = [:]
    public var dataTypes:[String:DataType] = [:] // datatypes by name
    // TODO remove, don't use it
    public var fields:[String:[Field]] = [:] // fields by segment
    public var segments: [String: Segment] = [:]
    public var groups: [String: [String: Segment]] = [:]
    
    var loadMessagesFlag = false
    var loadSegmentsFlag = false
    var loadFieldsFlag = false
    var loadDataTypesFlag = false
    var loadCompositeTypesFlag = false
    var loadRepetitionsFlag = false
    
    var currentVersion:Version? = nil
    var currentSequence:String? = nil
    var currentField:Field? = nil
    var currentMessage:SpecMessage? = nil
    var currentDataType:DataType? = nil
    var currentElement:String? = nil
    var currentSegment: String? = nil
    var currentGroup: String? = nil
    
    var parentGroup:Group? = nil
    
    init(_ version: Version, specificationSource: HL7V2SpecificationSource? = nil) throws {
        self.version = version
        self.specificationSource = specificationSource
        
        super.init()
        
        try loadXML()
    }
    
    
    public func loadXML() throws {
        try loadDataTypes(forVersion: version)
        try loadCompositeTypes(forVersion: version)
        try loadFields(forVersion: version)
        try loadMessages(forVersion: version)
        try loadRepetitions(forVersion: version)
    }
    
    
    private func loadMessages(forVersion version: Version) throws {
        if let xmlURL = specificationURL("messages.xsd", version: version) {
            let xmlParser = try makeParser(at: xmlURL)
            
            xmlParser.delegate = self
            
            loadMessagesFlag = true
            currentVersion = version
            
            if !xmlParser.parse() {
                throw HL7Error.parserError(message: "Cannot parse")
            }
                    
            for (_, message) in messages {
                try loadSegments(forMessage: message, version: version)
            }
        }
    }
    
    
    private func loadRepetitions(forVersion version: Version) throws {
        if let xmlURL = specificationURL("segments.xsd", version: version) {
            let xmlParser = try makeParser(at: xmlURL)
            xmlParser.delegate = self
            
            loadRepetitionsFlag = true
            
            if !xmlParser.parse() {
                throw HL7Error.parserError(message: "Cannot parse")
            }
        }
    }
    
    private func loadSegments(forMessage message: SpecMessage, version: Version) throws {
        if let xmlURL = specificationURL("messages/\(message.type.name).xsd", version: version) {
            let xmlParser = try makeParser(at: xmlURL)
            
            xmlParser.delegate = self
            
            loadSegmentsFlag = true
            currentMessage = message
                        
            if !xmlParser.parse() {
                throw HL7Error.parserError(message: "Cannot parse")
            }
        }
    }
    
    private func loadFields(forVersion version: Version) throws {
        if let xmlURL = specificationURL("fields.xsd", version: version) {
            let xmlParser = try makeParser(at: xmlURL)
            
            xmlParser.delegate = self
            
            loadFieldsFlag = true
            currentVersion = version
            
            if !xmlParser.parse() {
                throw HL7Error.parserError(message: "Cannot parse")
            }
        }
    }
    
    private func loadDataTypes(forVersion version: Version) throws {
        if let xmlURL = specificationURL("datatypes.xsd", version: version) {
            let xmlParser = try makeParser(at: xmlURL)
            
            xmlParser.delegate = self
            
            loadDataTypesFlag = true
            currentVersion = version
            
            if !xmlParser.parse() {
                throw HL7Error.parserError(message: "Cannot parse")
            }
        }
    }
    
    private func loadCompositeTypes(forVersion version: Version) throws {
        if let xmlURL = specificationURL("datatypes.xsd", version: version) {
            let xmlParser = try makeParser(at: xmlURL)
            
            xmlParser.delegate = self
            
            loadCompositeTypesFlag = true
            currentVersion = version
            
            if !xmlParser.parse() {
                throw HL7Error.parserError(message: "Cannot parse")
            }
        }
    }

    private func specificationURL(_ path: String, version: Version) -> URL? {
        guard let specificationSource else { return nil }
        let url = specificationSource.url(for: "v\(version.rawValue)/\(path)")
        return FileManager.default.isReadableFile(atPath: url.path) ? url : nil
    }

    private func makeParser(at url: URL) throws -> XMLParser {
        let data = try Data(contentsOf: url)
        guard data.count <= 16 * 1024 * 1024 else { throw HL7Error.parserError(message: "Specification artefact exceeds size limit") }
        for encoding: String.Encoding in [.utf8, .utf16LittleEndian, .utf16BigEndian, .utf32LittleEndian, .utf32BigEndian] {
            if let text = String(data: data, encoding: encoding),
               text.contains("<!DOCTYPE") || text.contains("<!ENTITY") {
                throw HL7Error.parserError(message: "Specification DTD and entity declarations are not accepted")
            }
        }
        let parser = XMLParser(data: data)
        parser.shouldResolveExternalEntities = false
        parser.externalEntityResolvingPolicy = .never
        parser.allowedExternalEntityURLs = []
        return parser
    }
}
