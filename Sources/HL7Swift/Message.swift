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
 
 print(message["MSH"])
 # "MSH|^~\\&||372523L|372520L|372521L|||ACK|1|D|2.5.1||||||"
 ```
 */
public struct Message {
    var segments: [Segment] = []
    var sep:Character = "\r"

    var spec:HL7!
    var specMessage:SpecMessage?
    
    public var version:Version {
        return specMessage!.version
    }
    
    public var type:Typable {
        return specMessage!.type
    }
    
    init?(withFileAt path: String) throws {
        do {
            let content = try String(contentsOf: URL(fileURLWithPath: path))
                                
            try self.init(content)
            
        } catch let e {
            throw HL7Error.fileNotFound(message: e.localizedDescription)
        }
    }
    
    init(_ str: String) throws {
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
        
        print("\n\(str)\n")
                
        guard let version = try getVersion() else {
            throw HL7Error.unsupportedVersion(message: "Unknow")
        }
        
        let type = try getType()
        
        let hl7  = try HL7.load(version: version)
        
        guard let specMessage = hl7.messages[type] else {
            throw HL7Error.unsupportedMessage(message: str)
        }
        
        self.specMessage = specMessage
    }
    
    
    
    
    // MARK: -
    
    /*
     Easily get a segment of the message with a given code using subscript notation.
     
     Usage: `let segment = message["MSH"]`
     
     */
    subscript(code: String) -> Segment? {
        return getSegment(code)
    }
    
    
    
    
    
    // MARK: -
    
    /// Gets a segment with a given code
    func getSegment(_ code: String) -> Segment? {
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
    private func getType() throws -> String {
        var str = ""
        
        guard let segment = self["MSH"] else {
            throw HL7Error.unsupportedMessage(message: "MSH segment not found")
        }
        
        // ACK / NAK
        if segment.fields[7].cells[0].components.isEmpty {
            str = segment.fields[7].cells[0].text
        } else {
            if segment.fields[7].cells[0].components.count == 3 {
                str = segment.fields[7].cells[0].components[2].text
            } else {
                str = segment.fields[7].cells[0].components[0].text + "_" + segment.fields[7].cells[0].components[1].text
            }
        }
        
        return str
    }

    

    private func getVersion() throws -> Version? {
        guard let segment = self["MSH"] else {
            throw HL7Error.unsupportedMessage(message: "MSH segment not found")
        }
        
        var vString = segment.fields[10].cells[0].text
        
        if vString == "" {
            vString = segment.fields[10].cells[0].components[0].text
        }
        
        return Version(rawValue: vString)
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
        
        if !str.isEmpty {
            str.removeLast()
        }
        
        return str
    }
}
