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
    public var messageVersion:Version!
    public var forcedVersion:Version!
    
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
    
    
    public init(_ str: String, hl7: HL7, force forcedVersion:Version? = nil) throws {
        self.forcedVersion = forcedVersion
        
        // sanitize check to exclude non-HL7 strings
        guard (str.range(of: #"(^|\n)([A-Z]{2}[A-Z0-9]{1})(?=[\|])"#, options: .regularExpression) != nil) else {
            throw HL7Error.unsupportedMessage(message: "Not HL7 message")
        }
        
        // The separator depends on the implementation, not on the standard
        if str.split(separator: "\r").count > 1 {
            sep = "\r"
        } else if str.split(separator: "\n").count > 1 {
            sep = "\n"
        } else if str.split(separator: "\r\n").count > 1 {
            sep = "\r\n"
        }

        // parse raw segments
        for segment in str.split(separator: sep) {
            segments.append(Segment(String(segment)))
        }
        
        guard segments.count > 0 else {
            throw HL7Error.unsupportedMessage(message: "No segment found")
        }
        
        // check we have a header
        // TODO : special cases for FHS/BHS ?
        if let header = self[HL7.MSH] {
            // check we have a version
            guard header.fields.count > 11 else {
                throw HL7Error.unsupportedMessage(message: "Not enought field in segment \(segments[0].code)")
            }
        }
                        
        // read version form segments
        guard let version = try getVersion() else {
            throw HL7Error.unsupportedVersion(message: "Unknow/unsupported version")
        }
        
        // prefer forced if given
        self.version = forcedVersion ?? version
        // keep ref of the read message version here
        self.messageVersion = version
        
        // read type from segments
        let type = try getType()
                
        // try to load versioned spec
        guard let spec = hl7.spec(ofVersion: version) else {
            throw HL7Error.unsupportedVersion(message: version.rawValue)
        }
        
        // try to load matching message type in the versioned spec
        self.specMessage = spec.messages[type]
        
        // try to auto fallback on other spec versions
        // if no spec is found for the version given in the message
        // only if no already forced version given
        if specMessage == nil && forcedVersion == nil {
            for v in Version.allCases {
                if let spec = hl7.spec(ofVersion: v) {
                    self.specMessage = spec.messages[type]
                    
                    if self.specMessage != nil {
                        self.version = v // not sure ? :-/
                        break
                    }
                }
            }
        } else {
            if forcedVersion != nil {
                // try load forced spec
                if let spec = hl7.spec(ofVersion: forcedVersion!) {
                    self.specMessage = spec.messages[type]
                }
            }
        }

        if self.specMessage != nil {
            self.type = self.specMessage?.type
            
            // create the Message root group (different fromm the spec message root group)
            self.rootGroup = Group(name: type)
            
            // give ref of the spec to our segment objects
            for s in segments {
                s.specMessage = self.specMessage
            }
            
            // populate groups with message values and repetitions
            self.specMessage?.rootGroup.populate(group: self.rootGroup, root: self.rootGroup, from: self)
        } else {
            self.rootGroup = Group(name: type)
            
            // get a type anyway if none
            if self.type == nil {
                self.type = HL7.UnknowMessageType(name: type)
            }
            
            // as we do not have any spec to rely on, load raw segments into the root group for convenience
            for s in segments {
                self.rootGroup?.segments.append(s)
                self.rootGroup?.items.append(Item.segment(s))
            }
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
    /// Usage: `let segment = message[HL7.MSH]`
    public subscript(code: String, repetition: UInt = 1) -> Segment? {
        get {
            return getSegment(code, repetition: repetition) }
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
        var i:UInt = 0
        
        for segment in segments {
            if segment.code == code {
                if rep == 1 {
                    return segment
                } else {
                    rep -= 1
                    
                    return segments[Int(rep+i)]
                }
            }
            i += 1
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
        
        guard let field = segment.fields[9] else {
            throw HL7Error.unsupportedMessage(message: "Message Type field not found")
        }
        
        // ACK / NAK
        if field.cells[0].components.isEmpty {
            str = field.cells[0].text
        } else {
            if field.cells[0].components.count == 3 {
                str = field.cells[0].components[2].text
            } else {
                str = field.cells[0].components[0].text + "_" + field.cells[0].components[1].text
            }
        }
        
        return str
    }

    

    private func getVersion() throws -> Version? {
        guard let segment = self["MSH"] else {
            throw HL7Error.unsupportedMessage(message: "MSH segment not found")
        }
        
        guard let field = segment.fields[12] else {
            throw HL7Error.unsupportedMessage(message: "Version field not found")
        }
        
        var vString = field.cells[0].text
        
        if vString == "" {
            if field.cells[0].components.count > 0 {
                vString = field.cells[0].components[0].text
            }
            else {
                throw HL7Error.unsupportedMessage(message: "Version field empty")
            }
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
