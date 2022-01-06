//
//  File.swift
//  
//
//  Created by Rafael Warnault on 25/12/2021.
//

import Foundation

/**
 Represents a HL7 standard versions.
 */
public struct Version: RawRepresentable, Hashable {
    public var rawValue: String
    
    public typealias RawValue = String
    
    public init?(rawValue: String) {
        if      rawValue != "2.1"       &&
                rawValue != "2.3"       &&
                rawValue != "2.3.1"     &&
                rawValue != "2.4"       &&
                rawValue != "2.5"       &&
                rawValue != "2.5.1"     &&
                rawValue != "2.6"       &&
                rawValue != "2.7"       &&
                rawValue != "2.7.1"     &&
                rawValue != "2.8"       &&
                rawValue != "2.8.1"     &&
                rawValue != "2.8.2"     {
            return nil
        }
        
        self.rawValue = rawValue
    }
    
    public static let all    = Version(rawValue: "*")!
    public static let v21    = Version(rawValue: "2.1")!
    public static let v23    = Version(rawValue: "2.3")!
    public static let v231   = Version(rawValue: "2.3.1")!
    public static let v24    = Version(rawValue: "2.4")!
    public static let v25    = Version(rawValue: "2.5")!
    public static let v251   = Version(rawValue: "2.5.1")!
    public static let v26    = Version(rawValue: "2.6")!
    public static let v27    = Version(rawValue: "2.7")!
    public static let v271   = Version(rawValue: "2.7.1")!
    public static let v28    = Version(rawValue: "2.8")!
    public static let v281   = Version(rawValue: "2.8.1")!
    public static let v282   = Version(rawValue: "2.8.2")!
    public static let last   = v282
    
    public static func klass(forVersion type: Version) -> Versionable.Type {
        switch type {
        case v21:    return HL7.V21.self as Versionable.Type
        case v23:    return HL7.V23.self as Versionable.Type
        case v231:   return HL7.V231.self as Versionable.Type
        case v24:    return HL7.V24.self as Versionable.Type
        case v25:    return HL7.V25.self as Versionable.Type
        case v251:   return HL7.V251.self as Versionable.Type
        case v26:    return HL7.V26.self as Versionable.Type
        case v27:    return HL7.V27.self as Versionable.Type
        case v271:   return HL7.V271.self as Versionable.Type
        case v28:    return HL7.V28.self as Versionable.Type
        case v281:   return HL7.V281.self as Versionable.Type
        case v282:   return HL7.V282.self as Versionable.Type
        default:
            return HL7.V282.self as Versionable.Type
        }
    }
}
