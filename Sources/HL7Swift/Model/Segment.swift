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
public class Segment {
    public var code: String = ""
    public var fields: [Field] = []
    var specMessage:SpecMessage? = nil
    
    public var isHeader:Bool {
        code == "MSH" || code == "FHS" || code == "BHS"
    }
    
    init(_ str: String, specMessage:SpecMessage? = nil) {
        self.specMessage = specMessage
        
        // see ORU 1 txt file, contains a ^ at the last line
        if !str.contains("|") {
            code = str
            return
        }
        
        // separator can be dynamic
        if let separator = str.prefix(4).last {
            var strCloneSplit = str.split(separator: separator, maxSplits: 50, omittingEmptySubsequences: false)
        
            code = String(strCloneSplit.remove(at: 0))
                        
            if isHeader {
                fields.append(Field([Cell(String(separator))])) // append separator field (MSH-1)
                fields.append(Field([Cell(String(strCloneSplit.remove(at: 0)), isEncoding: true)]))
            }
            
            for field in strCloneSplit {
                fields.append(Field(String(field)))
            }
        }
    }
    
    
    /// Subscript that get/set segment fields by their index (1-n) as defined in the HL7 specification.
    public subscript(index: Int) -> Field? {
        get {
            if index == 0 {
                return nil
            }
            return fields[index-1]
        }
        set {
            if let newValue = newValue {
                fields[index-1] = newValue
            }
        }
    }
    
    /// Subscript that get/set segment fields by their specification long names as defined in the HL7 specification.
    public subscript(name: String) -> Field? {
        get {
            if let specMessage = specMessage {
                // we loop over all known segments in the spec (specMessage.rootGroup)
                for segment in specMessage.rootGroup.segments {
                    if segment.code == code {
                        // we search for a matching field in the spec
                        for f in segment.fields {
                            if f.longName == name {
                                // if found, return field by index
                                // be careful of header segment (-2)
                                return fields[f.index-1]
                            }
                        }
                    }
                }
            }
            
            return nil
        }
        set {
            // same as getter
            if let specMessage = specMessage {
                for segment in specMessage.rootGroup.segments {
                    if segment.code == code {
                        for f in segment.fields {
                            if f.longName == name {
                                if let newValue = newValue {
                                    // be careful of header segment (-2)
                                    fields[f.index-1] = newValue
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

extension Segment: CustomStringConvertible {
    public var description: String {
        var str = code + "|"
        
        if isHeader {
            // remove separator field
            fields.remove(at: 0)
        }

        for field in fields {
            str += field.description + "|"
        }
        
        // remove last |
        if !str.isEmpty {
            str.removeLast()
        }

        return str
    }
}
