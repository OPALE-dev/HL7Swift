//
//  File.swift
//  
//
//  Created by Rafael Warnault on 25/12/2021.
//

import Foundation

public struct Version:OptionSet, CustomStringConvertible, CaseIterable, Hashable {
    public static var allCases: [Version] = [.v23, .v231, .v24, .v25,
                                             .v251, .v26, .v27, .v271,
                                             .v28, .v281, .v282]
    
    public let rawValue: Int

    public static let v23           = Version(rawValue: 1 << 0)
    public static let v231          = Version(rawValue: 1 << 1)
    public static let v24           = Version(rawValue: 1 << 2)
    public static let v25           = Version(rawValue: 1 << 3)
    public static let v251          = Version(rawValue: 1 << 4)
    public static let v26           = Version(rawValue: 1 << 5)
    public static let v27           = Version(rawValue: 1 << 6)
    public static let v271          = Version(rawValue: 1 << 7)
    public static let v28           = Version(rawValue: 1 << 8)
    public static let v281          = Version(rawValue: 1 << 9)
    public static let v282          = Version(rawValue: 1 << 10)
    public static let all:Version   = [.v23, .v231, .v24, .v25,
                                       .v251, .v26, .v27, .v271,
                                       .v28, .v281, .v282]
    
    public init(rawValue:Int) {
        self.rawValue = rawValue
    }
    
    public init(string:String) {
        switch string {
        case   "2.3": self.rawValue = Version.v23.rawValue
        case "2.3.1": self.rawValue = Version.v231.rawValue
        case   "2.4": self.rawValue = Version.v24.rawValue
        case   "2.5": self.rawValue = Version.v25.rawValue
        case "2.5.1": self.rawValue = Version.v251.rawValue
        case   "2.6": self.rawValue = Version.v26.rawValue
        case   "2.7": self.rawValue = Version.v27.rawValue
        case "2.7.1": self.rawValue = Version.v271.rawValue
        case   "2.8": self.rawValue = Version.v28.rawValue
        case "2.8.1": self.rawValue = Version.v281.rawValue
        case "2.8.2": self.rawValue = Version.v282.rawValue
        
        default:
            self.rawValue = 1 << 10
        }

    }
    
    public var description: String {
        switch self {
            case .v23:    return "2.3"
            case .v231:   return "2.3.1"
            case .v24:    return "2.4"
            case .v25:    return "2.5"
            case .v251:   return "2.5.1"
            case .v26:    return "2.6"
            case .v27:    return "2.7"
            case .v271:   return "2.7.1"
            case .v28:    return "2.8"
            case .v281:   return "2.8.1"
            case .v282:   return "2.8.2"
        default:
            return "undefined"
        }
    }
    
    
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
        default:
            return V282.self
        }
    }
}
