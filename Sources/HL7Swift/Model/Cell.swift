//
//  Cell.swift
//  
//
//  Created by Paul on 22/12/2021.
//

import Foundation

/**
 `Cell` contains the data of the HL7 message. A cell can contain components which can contain subcomponents.
 Components may be sTODO
 */
public class Cell:Node {
    var text: String = ""
    public var name: String = ""
    public var parent: Node?
    public var components: [Cell] = []
    public var type: DataType? = nil
    public var minOccurs:Int = 0
    public var maxOccurs:Int = -1
    
    init(_ str: String, parent: Node, isEncoding: Bool = false) {
        self.parent = parent
        
        if isEncoding {
            text = str
        } else {

            if str.contains("^") {
                for component in str.split(separator: "^", maxSplits: 20, omittingEmptySubsequences: false) {
                    
                    if component.contains("&") {
                        let parentCell = Cell(text: "", parent: self, components: [])
                        
                        for subcomponent in component.split(separator: "&", maxSplits: 20, omittingEmptySubsequences: false) {
                            parentCell.components.append(Cell(text: String(subcomponent), parent: parentCell, components: []))
                        }
                        
                        components.append(parentCell)
                    } else {
                        components.append(Cell(text: String(component), parent: self, components: []))
                    }
                }
            } else {
                text = str
            }
        }
    }
    
    init(text: String, parent: Node, components: [Cell]) {
        self.parent = parent
        self.text = text
        self.components = components
    }
}


extension Cell: CustomStringConvertible {
    public var description: String {
        
        if components.isEmpty {
            return text
        }
        
        var str = ""
        
        for component in components {
            str += component.text
            for subcomponent in component.components {
                str += subcomponent.text

                str += "&"
            }
            if str.last == "&" {
                str.removeLast()
            }
            
            str += "^"
        }
        if str.last == "^" {
            str.removeLast()
        }
        
        return str
    }
}
