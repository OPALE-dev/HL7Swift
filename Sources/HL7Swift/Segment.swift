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
    
    init(_ str: String, specMessage:SpecMessage? = nil) {
        self.specMessage = specMessage
        
        // see ORU 1 txt file, contains a ^ at the last line
        if !str.contains("|") {
            code = str
            return
        }
        
        var strCloneSplit = str.split(separator: "|", maxSplits: 50, omittingEmptySubsequences: false)
        
        code = String(strCloneSplit.remove(at: 0))
                    
        if code == "MSH" || code == "FHS" || code == "BHS" {
            fields.append(Field([Cell(String(strCloneSplit.remove(at: 0)), isEncoding: true)]))
        }
        
        for field in strCloneSplit {
            fields.append(Field(String(field)))
        }
    }
    
    
    
    public subscript(index: Int) -> Field? {
        return fields[index]
    }
    
    public subscript(name: String) -> Field? {
        if let specMessage = specMessage {
            for segment in specMessage.rootGroup.segments {
                if segment.code == self.code {
                    for f in segment.fields {
                        if f.longName == name {
                            return self[f.index-1]
                        }
                    }
                }
            }
        }
        
        return nil
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
