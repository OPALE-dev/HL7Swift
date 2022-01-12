//
//  File.swift
//  
//
//  Created by Rafael Warnault on 12/01/2022.
//

import Foundation

public enum ResultType {
    case notice
    case warning
    case error
}

public struct ValidationResult {
    let type:ResultType
    let text:String
    let date:Date = Date()
}


public protocol HL7Validator {
    func validate(_ message:Message) -> [ValidationResult]
}


public class DefaultValidator:HL7Validator {
    public func validate(_ message:Message) -> [ValidationResult] {
        return []
    }
}
