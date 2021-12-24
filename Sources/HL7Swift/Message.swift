//
//  Message.swift
//  
//
//  Created by Paul on 22/12/2021.
//

import Foundation

public enum AcknowledgeStatus: String {
    case AA // accepted
    case AE // app error
    case AR // rejected
}


public struct Message {
    var segments: [Segment] = []
    var sep:Character = "\r"
    
    
    init?(withFileAt path: String) throws {
        do {
            let content = try String(contentsOf: URL(fileURLWithPath: path))
                                
            self.init(content)
            
        } catch let e {
            throw HL7Error.fileNotFound(message: e.localizedDescription)
        }
    }
    
    init(_ str: String) {
        if str.split(separator: "\r").count > 1 {
            sep = "\r"
        } else if str.split(separator: "\n").count > 1 {
            sep = "\n"
        } else if str.split(separator: "\r\n").count > 1 {
            sep = "\r\n"
        }

        // TODO separate by newline or \r ?
        for segment in str.split(separator: sep) {
            segments.append(Segment(String(segment)))
        }
    }
    
    /// Some messages have types on one cell, eg ACK
    /// Others have their type on two cells, eg PPR^PC1
    /// Others have their type on three cells, eg VXU^V04^VXU_V04
    public func getType() throws -> Version.MessageType {
        var str = ""
        
        guard let version = getVersion() else {
            throw HL7Error.unsupportedVersion(message: segments[0].fields[10].cells[0].text)
        }
        
        // ACK / NAK
        if segments[0].fields[7].cells[0].components.isEmpty {
            str = segments[0].fields[7].cells[0].text
        } else {
            if segments[0].fields[7].cells[0].components.count == 3 {
                str = segments[0].fields[7].cells[0].components[2].text
            } else {
                str = segments[0].fields[7].cells[0].components[0].text + "_" + segments[0].fields[7].cells[0].components[1].text
            }
        }
        
        return version.klass(forVersion: version).MessageType.init(rawValue: str)!
    }

    
    func getVersion() -> VersionType? {
        return VersionType(rawValue: segments[0].fields[10].cells[0].text)
    }
}

extension Message: CustomStringConvertible {
    public var description: String {
        var str = ""
        for segment in segments {
            str += segment.description + sep.description
        }
        str.removeLast()
        return str
    }
}
