//
//  File.swift
//  
//
//  Created by Rafael Warnault on 23/12/2021.
//

import Foundation

public enum HL7Error: LocalizedError {
    case fileNotFound(message: String)
    case networkError(message: String)
    case encondingFailed(message: String)
    case unexpectedMessage(message: String)
    case unsupportedVersion(message: String)
    case parserError(message: String)
    
    public var errorDescription: String? {
        switch self {
  
        case .fileNotFound(message: let message):
            return "File not found: \(message)"
            
        case .networkError(message: let message):
            return "Network error: \(message)"
            
        case .encondingFailed(message: let message):
            return "Endocing of message failed: \(message)"
            
        case .unexpectedMessage(message: let message):
            return "Unexpected message: \(message)"
        
        case .unsupportedVersion(message: let message):
            return "Unsupported version: \(message)"

        case .parserError(message: let message):
            return "Parser error: \(message)"
            
        }
    }
}
