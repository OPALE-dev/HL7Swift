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
public struct Cell {
    var text: String = ""
    var components: [Cell] = []
    
    init(_ str: String, isEncoding: Bool = false) {
        if isEncoding {
            text = str
        } else {

            if str.contains("^") {
                for component in str.split(separator: "^", maxSplits: 20, omittingEmptySubsequences: false) {
                    
                    if component.contains("&") {
                        var componentsArray: [Cell] = []
                        for subcomponent in component.split(separator: "&", maxSplits: 20, omittingEmptySubsequences: false) {
                            componentsArray.append(Cell(text: String(subcomponent), components: []))
                        }
                        components.append(Cell(text: "", components: componentsArray))
                    } else {
                        components.append(Cell(text: String(component), components: []))
                    }
                }
            } else {
                text = str
            }
        }
    }
    
    init(text: String, components: [Cell]) {
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
