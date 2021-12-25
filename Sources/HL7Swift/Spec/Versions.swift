//
//  File.swift
//  
//
//  Created by Rafael Warnault on 25/12/2021.
//

import Foundation

public enum Version:String {
    case v23    = "2.3"
    case v231   = "2.3.1"
    case v24    = "2.4"
    case v25    = "2.5"
    case v251   = "2.5.1"
    case v26    = "2.6"
    case v27    = "2.7"
    case v271   = "2.7.1"
    case v28    = "2.8"
    case v281   = "2.8.1"
    case v282   = "2.8.2"
    
    public static func klass(forVersion type: Version) -> HL7.Type {
        switch type {
        case .v23:    return V23.self
        case .v231:   return V231.self
        case .v24:    return V24.self
        case .v25:    return V25.self
        case .v251:   return V251.self
        case .v26:    return V26.self
        case .v27:    return V27.self
        case .v271:   return V271.self
        case .v28:    return V28.self
        case .v281:   return V281.self
        case .v282:   return V282.self
        }
    }
}
