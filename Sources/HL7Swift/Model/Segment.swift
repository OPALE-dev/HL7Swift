//
//  Segment.swift
//  
//
//  Created by Paul on 22/12/2021.
//

import Foundation

/**
 A segment is composed of a set of fields
 The first field is the code; the code is left out from the field array. The fields are separated by a pipe, you can retrieve the original format
 with the property `description`.
 
 Usage :
 ```
 let segment = Segment("MSH|^~\\&||372523L|372520L|372521L|||ACK|1|D|2.5.1||||||")
 
 print(segment) # same as segment.description
 # "MSH|^~\\&||372523L|372520L|372521L|||ACK|1|D|2.5.1||||||"
 
 print(segment.code)
 # "MSH"
 ```
 */
public class Segment: Node {
    public var name: String = ""
    public var parent: Node?
    
    public var code: String = ""
    public var fields: [Int:Field] = [:]
    public var sortedFields:[Field] {
        var array:[Field] = []
        for k in Array(fields.keys).sorted() {
            if let f = fields[k] {
                array.append(f)
            }
        }
        return array
    }
    
    // -1 means unbounded
    public var minOccurs:Int = 0
    public var maxOccurs:Int = -1
    
    var specMessage:SpecMessage? = nil
    
    public var isHeader:Bool {
        code == "MSH" || code == "FHS" || code == "BHS"
    }
    
    init(_ str: String, parent:Node? = nil, specMessage:SpecMessage? = nil) {
        self.specMessage = specMessage
        self.parent = parent
        
        // see ORU 1 txt file, contains a ^ at the last line
        if !str.contains("|") {
            code = str
            return
        }
        
        name = code
        
        // separator can be dynamic
        if let separator = str.prefix(4).last {
            var strCloneSplit = str.split(separator: separator, maxSplits: 50, omittingEmptySubsequences: false)
        
            code = String(strCloneSplit.remove(at: 0))
            name = code
            
            if isHeader {
                // append separator field (MSH-1)
                let sepField = Field([Cell(String(separator), parent: self)], parent: self)
                sepField.index = 1
                sepField.name = "\(self.code)-\(sepField.index)"
                sepField.cells[0].parent = sepField // (we  faked parent in Cell init)
                fields[fields.keys.count+1] = sepField
                
                // append encoding field (MSH-2)
                let encField = Field([Cell(String(strCloneSplit.remove(at: 0)), parent: self, isEncoding: true)], parent: self)
                encField.index = 2
                encField.name = "\(self.code)-\(encField.index)"
                encField.cells[0].parent = encField // (we  faked parent in Cell init)
                fields[fields.keys.count+1] = encField
            }
            
            // append other fields
            for field in strCloneSplit {
                let newField = Field(String(field), parent: self)
                newField.index = fields.keys.count+1
                newField.name = "\(self.code)-\(newField.index)"
                fields[newField.index] = newField
            }
        }
    }
    
     
    /// Subscript that get/set segment fields by their index (1-n) as defined in the HL7 specification.
    public subscript(index: Int) -> Field? {
        get {
            if index == 0 || index > fields.count {
                return nil
            }
            return fields[index]
        }
        set {
            if let newValue = newValue {
                fields[index] = newValue
            }
        }
    }
    
    /// Subscript that get/set segment fields by their specification long names as defined in the HL7 specification.
    public subscript(name: String) -> String? {
        get {
            if let specMessage = specMessage {
                // we loop over all known segments in the spec (specMessage.rootGroup)
                for segment in specMessage.rootGroup.segments {
                    if segment.code == code {
                        // we search for a matching field in the spec
                        for (_, f) in segment.fields {
                            if f.longName == name {
                                // if found, return field by index
                                if f.index-1 <= fields.count-1 {
                                    if let field = fields[f.index] {
                                        return field.description
                                    }
                                }
                            }
                        }
                    }
                }
            }

            return nil
        }
        set(newValue) {
            // same as getter
            if let specMessage = specMessage {
                // we loop over all known segments in the spec (specMessage.rootGroup)
                for segment in specMessage.rootGroup.segments {
                    if segment.code == code {
                        // we search for a matching field in the spec
                        for (_, f) in segment.fields {
                            if f.longName == name {
                                // if found, return field by index
                                if f.index-1 <= fields.count-1 {
                                    if let field = fields[f.index] {
                                        if let newVal = newValue {
                                            field.cells = Field(newVal).cells
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
                
//            if let specMessage = specMessage {
//                for segment in specMessage.rootGroup.segments {
//                    if segment.code == code {
//                        for (_, f) in segment.fields {
//                            if f.longName == name {
//                                if let newVal = newValue {
//                                    // TODO: test with overflow, extent array if needed, etc.
//                                    //print("\(type(of: newVal)) \(newVal)")
//                                    if let field = fields[f.index] {
//                                        field.cells = Field(newVal).cells
//                                    }
//                                }
//                            }
//                        }
//                    }
//                }
//            }
        }
    }
    
    public func tersePath() -> String {
        if let p = parent as? Group {
            return "\(p.tersePath(self))/\(code)"
        } else {
            return "\(code)"
        }
    }
}

extension Segment: CustomStringConvertible {
    public var description: String {
        var localFields: [Field] = sortedFields

        var str = code + "|"
        
        if isHeader {
            // remove separator field
            localFields.remove(at: 0)
        }
        
        for field in localFields {
            str += field.description + "|"
        }
        
        // remove last |
        if !str.isEmpty {
            str.removeLast()
        }

        return str
    }
}
