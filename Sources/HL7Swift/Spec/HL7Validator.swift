//
//  File.swift
//  
//
//  Created by Rafael Warnault on 12/01/2022.
//

import Foundation

/**
 Defines the type of results returned by the validator
 */
public enum ResultType: Int, CustomStringConvertible {
    case none = 0
    case notice
    case warning
    case error
    
    public var description: String {
        switch self {
        case .none:    return ""
        case .notice:  return "Notice"
        case .warning: return "Warning"
        case .error:   return "Error"
        }
    }
}

/**
 Represents the level of detail/complexity of the validation
 */
public enum ValidationLevel: Int, CustomStringConvertible {
    case version
    case segments
    case fields
    case datatypes
    
    public var description: String {
        switch self {
        case .version:      return "Version"
        case .segments:     return "Segments"
        case .fields:       return "Fields"
        case .datatypes:    return "DataTypes"
        }
    }
}

/**
 Represents a result item for the validation process
 */
public struct ValidationResult {
    public let message:Message
    public let type:ResultType
    public let level:ValidationLevel
    public let text:String
    public let date:Date = Date()
}

/**
 Abstract Validator to make it more extandable
 */
public protocol HL7Validator {
    func validate(_ message:Message, level: ValidationLevel) -> [ValidationResult]
}

/**
 The default validator class shipped with HL7Swift. It validates version, segments, fields and datatypes
 against its embedded specification.
 */
public class DefaultValidator:HL7Validator {
    public init() {
        
    }
    
    /// Validate a message at different levels of detail
    ///
    /// Return an array of `ValidationResult`
    public func validate(_ message:Message, level: ValidationLevel = .version) -> [ValidationResult] {
        var results:[ValidationResult] = []
        
        switch level {
        case .version:
            results.append(contentsOf: validateVersion(message))
            
        case .segments:
            results.append(contentsOf: validateVersion(message))
            results.append(contentsOf: validateSegments(message))
            
        case .fields:
            results.append(contentsOf: validateVersion(message))
            results.append(contentsOf: validateSegments(message))
            results.append(contentsOf: validateFields(message))
            
        case .datatypes:
            results.append(contentsOf: validateVersion(message))
            results.append(contentsOf: validateSegments(message))
            results.append(contentsOf: validateFields(message))
            results.append(contentsOf: validateDataTypes(message))
        }
        
        return results
    }
}

/**
 Privates methods
 */
private extension DefaultValidator {
    /**
     Validates the message type and version
     */
    func validateVersion(_ message:Message) -> [ValidationResult] {
        var results:[ValidationResult] = []
        
        if message.forcedVersion == nil {
            if message.specMessage == nil {
                let text = "Message of type \(message.type.name) is not part of version \(message.version.rawValue)"
                results.append(ValidationResult(
                                message: message,
                                type: .error,
                                level: .version,
                                text: text))
            }
            else {
                if message.version != message.messageVersion {
                    let text = "Message of type \(message.type.name) is not part of version \(message.messageVersion.rawValue). Fallback to version \(message.version.rawValue)"
                    results.append(ValidationResult(
                                    message: message,
                                    type: .warning,
                                    level: .version,
                                    text: text))
                }
            }
        } else {
            if message.specMessage == nil {
                let text = "Message of type \(message.type.name) is not part of version \(message.forcedVersion!.rawValue) (forced)"
                results.append(ValidationResult(
                                message: message,
                                type: .error,
                                level: .version,
                                text: text))
            }
        }
        
        return results
    }
    
    /**
     Validates required and missing segments for message type
     */
    func validateSegments(_ message:Message) -> [ValidationResult] {
        var results:[ValidationResult] = []
        
        results.append(contentsOf: validateMissingSegments(message))
        results.append(contentsOf: validateUnsupportedSegments(message))
        
        return results
    }
    
    /**
     Find missing required segments (segments that should be here but it is not)
     */
    func validateMissingSegments(_ message:Message, parent: Group? = nil) -> [ValidationResult] {
        var results:[ValidationResult] = []
        var group:Group? = parent
        
        if parent == nil {
            group = message.rootGroup!
        }
        
        if message.specMessage == nil || message.rootGroup == nil {
            return []
        }
        
        for item in group!.items {
            switch item {
            case .group(let subGroup):
                results.append(contentsOf: validateMissingSegments(message, parent: subGroup))
                
            case .segment(let segment):
                var count = 0
                for ms in message.segments {
                    if ms.code == segment.code {
                        count += 1
                    }
                }
                
                if count < segment.minOccurs {
                    let text = "Missing segment \(segment.code) in message of type \(message.type.name) (\(message.version.rawValue))"
                    results.append(ValidationResult(
                                    message: message,
                                    type: .warning,
                                    level: .segments,
                                    text: text))
                }
            }
        }
        
        return results
    }
    
    /**
     Find unsupported segemnts (segments that shouldn't be here but it is)
     */
    func validateUnsupportedSegments(_ message:Message, parent: Group? = nil) -> [ValidationResult] {
        var results:[ValidationResult] = []
//        var group:Group? = parent
//
//        if parent == nil {
//            group = message.rootGroup!
//        }
        
        if message.specMessage == nil || message.rootGroup == nil {
            return []
        }
            
        // segments that are used more than defined max occurences
        for specSegment in message.rootGroup!.segments {
            var count = 0
            for segment in message.segments {
                if segment.code == specSegment.code {
                    count += 1
                }
            }
                        
            if specSegment.maxOccurs != -1 && count > specSegment.maxOccurs {
                let text = "Too much occurences of segment \(specSegment.code) in message of type \(message.type.name) (\(message.version.rawValue))"
                results.append(ValidationResult(
                                message: message,
                                type: .warning,
                                level: .segments,
                                text: text))
            }
        }
        
        // segment that souldn't be used in this message
        for segment in message.segments {
            if message.rootGroup!.segments.map({ $0.code }).contains(segment.code) == false {
                // TODO: make use of maxOccurs, `message.rootGroup.segments` have to be populated properly first for that
                // if segment.maxOccurs != -1 && count > segment.maxOccurs { ... }
                
                let text = "Unsupported segment \(segment.code) in message of type \(message.type.name) (\(message.version.rawValue))"
                results.append(ValidationResult(
                                message: message,
                                type: .warning,
                                level: .segments,
                                text: text))
            }
        }
        
        return results
    }

    /**
     Validates required and missing fields for segments
     */
    func validateFields(_ message:Message) -> [ValidationResult] {
        return []
    }
    
    /**
     Validates datatypes of fields
     */
    func validateDataTypes(_ message:Message) -> [ValidationResult] {
        return []
    }
}
