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
    public var sep:Character = "\r"
    public var spec:HL7!
    public var specMessage:SpecMessage?
    public var rootGroup: Group?

    public var version:Version!
    public var type:Typable!

    var segments: [Segment] = []
    var internalType:Typable?
    
    public init(withFileAt url: URL, hl7: HL7) throws {
        do {
            let content = try String(contentsOf: url)
                                
            try self.init(content, hl7: hl7)
            
        } catch let e {
            throw HL7Error.fileNotFound(message: e.localizedDescription)
        }
    }
    
    
    public init(withFileAt path: String, hl7: HL7) throws {
        try self.init(withFileAt: URL(fileURLWithPath: path), hl7: hl7)
    }
    
    
    public init(_ str: String, hl7: HL7) throws {
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
                        
        guard let version = try getVersion() else {
            throw HL7Error.unsupportedVersion(message: "Unknow")
        }
        
        self.version = version
        
        let type = try getType()

        if let spec = hl7.spec(ofVersion: version) {
            self.specMessage = spec.messages[type]
            self.type = self.specMessage?.type
            self.rootGroup = self.specMessage?.rootGroup
                    
            for s in segments {
                s.specMessage = self.specMessage
            }

            // get a type anyway
            if self.type == nil {
                self.type = HL7.UnknowMessageType(name: type)
            }
            
            // populate message groups with values
            self.rootGroup?.populate(with: self)
        }
    }
    
    public init(_ type: Typable, spec: Versioned, preloadSegments: [String]) throws {
        self.internalType = type
        self.specMessage  = spec.messages[type.name]
        self.version = spec.version
        
        // populate segments ?
        if self.specMessage != nil {
            for s in self.specMessage!.rootGroup.segments {
                for ps in preloadSegments {
                    if s.code == ps {
                        segments.append(s)
                    }
                }
            }
        }
    }
    
    
    // MARK: -
    

    /// Easily get/set a segment of the message with a given code using subscript notation.
    /// Usage: `let segment = message["MSH"]`
    public subscript(code: String) -> Segment? {
        get {
            return getSegment(code) }
        set {
            // something wrong here?
            // delete if exist
            if let index = segments.firstIndex(where: { seg in seg.code == code }) {
                let oldSegment = segments.remove(at: index)
                
                if let newValue = newValue {
                    newValue.fields = oldSegment.fields
                    segments.insert(newValue, at: index)
                }
            } else {
                if let newValue = newValue {
                    segments.append(newValue)
                }
            }
        }
    }

    
    
    
    /// Validates a message
    func validate() -> Bool {
        if self.specMessage == nil {
            return false
        }
        
        // TODO: Validate message against the HL7 spec
        // 1. check required segments
        // 2. check required fields/components
        // 3. check datatypes and values
        
        return true
    }
    
    
    
    // MARK: -
    
    /**
     Gets a segment with a given code. Takes into account the number of repetition of the segment. By default, if there's no repetition,
     the repetition is 1, so the group `OBSERVATION` is equivalent to `OBSERVATION(1)` (you'll never see it in practice)
     
     Example :
     ```
     message.getSegment("MSH")
     message.getSegment("OBX", repetition: 2)
     ```
    */
    func getSegment(_ code: String, repetition: UInt = 1) -> Segment? {
        var rep = repetition
        
        for segment in segments {
            if segment.code == code {
                if rep == 1 {
                    return segment
                } else {
                    rep -= 1
                }
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
        if segment.fields[8].cells[0].components.isEmpty {
            str = segment.fields[8].cells[0].text
        } else {
            if segment.fields[8].cells[0].components.count == 3 {
                str = segment.fields[8].cells[0].components[2].text
            } else {
                str = segment.fields[8].cells[0].components[0].text + "_" + segment.fields[8].cells[0].components[1].text
            }
        }
        
        return str
    }

    

    private func getVersion() throws -> Version? {
        guard let segment = self["MSH"] else {
            throw HL7Error.unsupportedMessage(message: "MSH segment not found")
        }
        
        var vString = segment.fields[11].cells[0].text
        
        if vString == "" {
            vString = segment.fields[11].cells[0].components[0].text
        }
        
        return Version(rawValue: vString)
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
