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
    case notice = 0
    case warning
    case error
    case none
    
    public var description: String {
        switch self {
        case .notice:  return "Notice"
        case .warning: return "Warning"
        case .error:   return "Error"
        case .none:   return ""
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
        
        if message.specMessage == nil {
            let text = "Message of type \(message.type.name) is not part of version \(message.version.rawValue)"
            results.append(ValidationResult(
                            message: message,
                            type: .error,
                            level: .version,
                            text: text))
        }
        
        return results
    }
    
    /**
     Validates required and missing segments for message type
     */
    func validateSegments(_ message:Message) -> [ValidationResult] {
        return []
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
