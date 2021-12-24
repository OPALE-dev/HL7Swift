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

/**
 HL7 message. A message is a set of segments. The separator of the segments depends on the implementation : `\r`, `\n` or `\r\n`. The standard says `\r` but not all implementations follows that.
 
 Usage :
 ```
 let message = Message("MSH|^~\\&||372523L|372520L|372521L|||ACK|1|D|2.5.1||||||\rMSA|AA|LRI_3.0_1.1-NG|")
 
 print(message.getType())
 # "ACK"
 
 print(message.getVersion())
 # "2.5.1"
 
 print(message.segments[0])
 # "MSH|^~\\&||372523L|372520L|372521L|||ACK|1|D|2.5.1||||||"
 ```
 */
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
        // The separator depends on the implementation, not on the standard
        if str.split(separator: "\r").count > 1 {
            sep = "\r"
        } else if str.split(separator: "\n").count > 1 {
            sep = "\n"
        } else if str.split(separator: "\r\n").count > 1 {
            sep = "\r\n"
        }

        for segment in str.split(separator: sep) {
            segments.append(Segment(String(segment)))
        }
    }
    
    init?(withType type: Version.MessageType?) throws {
        do {
            guard let items = try group()?.items else {
                throw HL7Error.initError(message: "Cannot build message of type \(type)")
            }
            
            for index in items.indices {
                switch items[index] {
                case .segment(let segment):
                    segments.append(segment)
                default: continue
                }
            }
            
        } catch let e {
            throw e
        }
    }
    
    /// Gets a segment with a given code
    func getSegment(code: String) -> Segment? {
        for segment in segments {
            if segment.code == code {
                return segment
            }
        }
        
        return nil
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
        
        return VersionType.klass(forVersion: version).MessageType.init(rawValue: str)!
    }

    

    func getVersion() -> VersionType? {
        return VersionType(rawValue: segments[0].fields[10].cells[0].text)
    }
    
    
    /// Gets the group of the message : parses the spec file 
    func group() throws -> Group? {
        let parser = MessageSpecParser()
        
        try parser.runParser(forMessage: self)
        
        return parser.rootGroup
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
