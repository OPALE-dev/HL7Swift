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
            // else try load forced spec
            if forcedVersion != nil {
                if let spec = hl7.spec(ofVersion: forcedVersion!) {
                    self.specMessage = spec.messages[type]
                }
            }
        }

        if self.specMessage != nil {
            populateRootGroup()
            
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
        self.type = type
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
            
            populateRootGroup()
            
            self[HL7.MSH]?[HL7.Version_ID] = version.rawValue
            self[HL7.MSH]?[HL7.Message_Type] = type.name
            self[HL7.MSH]?[HL7.Sending_Application] = "HL7Swift"
        }
    }
    
    
    public init(_ type: Typable, spec: Versioned, preloadSegmentsFromSpec:Bool = true) throws {
        self.internalType = type
        self.type = type
        self.specMessage  = spec.messages[type.name]
        self.version = spec.version
        
        // populate segments ?
        if preloadSegmentsFromSpec && self.specMessage != nil {
            for s in self.specMessage!.rootGroup.segments {
                segments.append(s)
            }
            
            populateRootGroup()
            
            self[HL7.MSH]?[HL7.Version_ID] = version.rawValue
            self[HL7.MSH]?[HL7.Message_Type] = type.name
            self[HL7.MSH]?[HL7.Sending_Application] = "HL7Swift"
        }
    }
    
    
    
    private mutating func populateRootGroup() {
        self.type = self.specMessage?.type
        
        // create the Message root group (different fromm the spec message root group)
        self.rootGroup = Group(name: self.type.name)
        
        // give ref of the spec to our segment objects
        for s in segments {
            s.specMessage = self.specMessage
        }
        
        // populate groups with message values and repetitions
        self.specMessage?.rootGroup.populate(group: self.rootGroup, root: self.rootGroup, from: self)
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

    /**
     Returns the start index and the end index of the given segment in the message string
     
     ```
     let mshRange = message.getPositionInMessage(msh)
     
     var i = message.description.index(start, offsetBy: mshRange!.0)
     var j = message.description.index(start, offsetBy: mshRange!.1)
 
     let mshString = message.description[i..<j])
     ```
     */    
    public func getPositionInMessage(_ ofSegment: Segment) -> NSRange? {
        var index = -1
        var sum = 0
        
        for (i, s) in segments.enumerated() where index == -1 {
            if s.code == ofSegment.code {
                index = i
            }
        }
        
        // Segment not found
        if index == -1 {
            return nil
        }
        
        // sum(segments[0..<index].description.count)
        for j in 0..<index {
            sum += segments[j].description.utf16.count + 2//"\r\n".utf16.description.count + 1 // TODO replace by sep.count, but it's a char :/
        }
        
        return NSRange(location: sum, length: ofSegment.description.utf16.count)
    }
    
    /**
     Returns the start index and the end index of the given field in the message string
     */
    public func getPositionInMessage(_ ofField: Field) -> NSRange? {
        let index = ofField.index
        var sum = 0
        guard let segment = ofField.parent as? Segment else {
            return nil
        }
        
        guard let pos = self.getPositionInMessage(segment) else {
            return nil
        }
        
        sum = pos.location
        
        // sum(segment.fields[0..<ofField.index].description.count + 1)
        for i in 0..<index {
            if let field = segment.fields[i] {
                sum += field.description.utf16.count + 1// for the pipe
            } else {
                sum += 1
            }
        }
        
        // If it's the field separator, |, We shouldn't count the empty field (check the else just above)
        // TODO handle other segments than MSH, ie BST.1 ?
        if segment.code == "MSH" {
            if ofField.name == "MSH.1" {
                sum -= 1
            } else {
                sum -= 2
            }
        }
        
        sum += segment.code.utf16.count
        
        return NSRange(location: sum, length: ofField.description.utf16.count)
    }
 
    public func getPositionInMessage(_ ofCell: Cell) -> NSRange? {
        var field: Field? = nil
        var parentCell: Cell? = nil
        
        var repetition = false
        var component = false
        var subcomponent = false
        
        var cellIndex = -1
        var componentIndex = -1
        var subcomponentIndex = -1
        
        var sum = 0
        
        if let f = ofCell.parent as? Field {
            repetition = true
            field = f
            
            
            for (i, c) in field!.cells.enumerated() where cellIndex == -1 {
                if c.description == ofCell.description {
                    cellIndex = i
                }
            }
            
        } else if let pc = ofCell.parent as? Cell {
            component = true
            parentCell = pc
            
            if let gpc = pc.parent as? Cell {
                subcomponent = true
                parentCell = gpc
             
                guard let f = gpc.parent as? Field else {
                    return nil
                }
                field = f
                
                for (i, c) in pc.components.enumerated() where subcomponentIndex == -1 {
                    if c.description == ofCell.description {
                        subcomponentIndex = i
                    }
                }
                
                for (i, c) in parentCell!.components.enumerated() where componentIndex == -1 {
                    if c.description == pc.description {
                        componentIndex = i
                    }
                }
                
                for (i, c) in field!.cells.enumerated() where cellIndex == -1 {
                    if c.description == parentCell!.description {
                        cellIndex = i
                    }
                }
                
                
            } else {
                guard let f = pc.parent as? Field else {
                    return nil
                }
                
                field = f
                
                for (i, c) in parentCell!.components.enumerated() where componentIndex == -1 {
                    if c.description == ofCell.description {
                        componentIndex = i
                    }
                }
                
                for (i, c) in field!.cells.enumerated() where cellIndex == -1 {
                    if c.description == parentCell!.description {
                        cellIndex = i
                    }
                }
            }
            
            
        }
        
        sum = self.getPositionInMessage(field!)!.location
        
        if repetition || component || subcomponent {// ~
            sum += field!.cells[0..<cellIndex].map({$0.description.utf16.count + 1}).reduce(0, +)
            
            if component || subcomponent {// ^
                sum += field!.cells[cellIndex].components[0..<componentIndex].map({$0.description.utf16.count + 1}).reduce(0, +)
                
                if subcomponent {// &
                    sum += field!.cells[cellIndex].components[componentIndex].components[0..<subcomponentIndex].map({$0.description.utf16.count + 1}).reduce(0, +)
                }
            }
        }
        
        return NSRange(location: sum, length: ofCell.description.utf16.count)
    }
 
 
    public func desc() -> String {
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

// TODO move elsewhere
extension String {
    func substring(with nsrange: NSRange) -> Substring? {
        guard let range = Range(nsrange, in: self) else { return nil }
        return self[range]
    }
}

extension String {
    func range(from nsRange: NSRange) -> Range<String.Index>? {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location + nsRange.length, limitedBy: utf16.endIndex),
            let from = from16.samePosition(in: self),
            let to = to16.samePosition(in: self)
            else { return nil }
        return from ..< to
    }
    
    func substr(with nsrange: NSRange) -> Substring? {
        guard let range = self.range(from: nsrange) else { return nil }
        return self[range]
    }
}
