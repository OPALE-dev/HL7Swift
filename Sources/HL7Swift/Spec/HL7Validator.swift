//
//  File.swift
//  
//
//  Created by Rafael Warnault on 12/01/2022.
//

import Foundation

public enum ResultType: Int {
    case notice = 0
    case warning
    case error
}


public enum ValidationLevel: Int {
    case version
    case segments
    case fields
    case datatypes
}


public struct ValidationResult {
    let type:ResultType
    let text:String
    let date:Date = Date()
}


public protocol HL7Validator {
    func validate(_ message:Message, level: ValidationLevel) -> [ValidationResult]
}


public class DefaultValidator:HL7Validator {
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


private extension DefaultValidator {
    /*
     Validates the message type and version
     */
    func validateVersion(_ message:Message) -> [ValidationResult] {
        return []
    }
    
    /*
     Validates required and missing segments for message type
     */
    func validateSegments(_ message:Message) -> [ValidationResult] {
        return []
    }
    
    /*
     Validates required and missing fields for segments
     */
    func validateFields(_ message:Message) -> [ValidationResult] {
        return []
    }
    
    /*
     Validates datatypes of fields
     */
    func validateDataTypes(_ message:Message) -> [ValidationResult] {
        return []
    }
}
