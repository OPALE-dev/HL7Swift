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
    var code: String = ""
    var fields: [Field] = []
    var specMessage:SpecMessage? = nil
    
    var isHeader:Bool {
        code == "MSH" || code == "FHS" || code == "BHS"
    }
    
    init(_ str: String, specMessage:SpecMessage? = nil) {
        self.specMessage = specMessage
        
        // see ORU 1 txt file, contains a ^ at the last line
        if !str.contains("|") {
            code = str
            return
        }
        
        var strCloneSplit = str.split(separator: "|", maxSplits: 50, omittingEmptySubsequences: false)
        
        code = String(strCloneSplit.remove(at: 0))
                    
        if isHeader {
            fields.append(Field([Cell(String(strCloneSplit.remove(at: 0)), isEncoding: true)]))
        }
        
        for field in strCloneSplit {
            fields.append(Field(String(field)))
        }
    }
    
    
    
    public subscript(index: Int) -> Field? {
        get {
            return fields[index]
        }
        set {
            if let newValue = newValue {
                fields[index] = newValue
            }
        }
    }
    
    public subscript(name: String) -> Field? {
        get {
            if let specMessage = specMessage {
                for segment in specMessage.rootGroup.segments {
                    if segment.code == self.code {
                        for f in segment.fields {
                            if f.longName == name {
                                return self.fields[isHeader ? f.index-2 : f.index-1]
                            }
                        }
                    }
                }
            }
            
            return nil
        }
        set {
            if let specMessage = specMessage {
                for segment in specMessage.rootGroup.segments {
                    if segment.code == self.code {
                        for f in segment.fields {
                            if f.longName == name {
                                //print("\(name) : \(f.index)")
                                if let newValue = newValue {
                                    self.fields[isHeader ? f.index-2 : f.index-1] = newValue
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
