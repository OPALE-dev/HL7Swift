//
//  Field.swift
//  
//
//  Created by Paul on 22/12/2021.
//

import Foundation

/**
 A field is a set of cells, it contains the data of the HL7 messages.
 
 Usage :
 ```
 let field = Field("LOI_Common_Component^LOI Base Profile^2.16.840.1.113883.9.66^ISO~LOI_NG_Component^LOI NG Profile^2.16.840.1.113883.9.79^ISO")
 
 print(field)
 # same as print(field.description)
 # "LOI_Common_Component^LOI Base Profile^2.16.840.1.113883.9.66^ISO~LOI_NG_Component^LOI NG Profile^2.16.840.1.113883.9.79^ISO"
 ```
 */
public class Field:Node {
    public var parent: Node?
    
    public var cells: [Cell] = []
    
    // TODO remove, not used
    public var segmentCode: String = ""
    public var name: String = ""
    public var longName: String = ""
    public var type: DataType? = nil
    public var item: String = ""
    public var minLength: Int = 0
    public var maxLength: Int = 0
    public var index: Int = 0
    
    public var minOccurs: Int = 0
    public var maxOccurs: Int = 0
    
    public lazy var fieldCode: String = {
        return parent!.name + "-" + String(self.index)
    }()
    
    init(name: String, parent: Node? = nil) {
        self.name = name
        self.parent = parent
    }
    
    init(_ str: String, parent: Node? = nil) {
        self.parent = parent
        
        if str.contains("~") {
            // 20 is a random number, could be anything; we want to take empty subsequences but we oughta specify a maximum number
            // of splits too, that's where the 20 is coming from
            for cell in str.split(separator: "~", maxSplits: 20, omittingEmptySubsequences: false) {
                cells.append(Cell(String(cell), parent: self))
            }
        } else {
            cells.append(Cell(str, parent: self))
        }
    }    
    
    init(_ cellsToCopy: [Cell], parent: Node? = nil) {
        self.parent = parent
        cells = cellsToCopy
    }
}

extension Field: CustomStringConvertible {
    public var description: String {
        var str = ""
        
        for cell in cells {
            str += cell.description + "~"
        }
        
        // remove last ~
        if !str.isEmpty {
            str.removeLast()
        }
        
        return str
    }
}
