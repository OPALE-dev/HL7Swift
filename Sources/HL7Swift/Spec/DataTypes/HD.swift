//
//  File.swift
//  
//
//  Created by Rafael Warnault on 14/02/2022.
//

import Foundation
/**
 Represents a Hierarchic Designator
 */
public struct HD {
    var namespaceID:String?
    var universalID:String?
    var universalIDType:String?

    var cell:Cell

    public init(_ cell:Cell) {
        self.cell = cell
        
        if cell.components.count > 0 {
            namespaceID = cell.components[0].description
        }
        
        if cell.components.count > 1 {
            universalID = cell.components[1].description
        }
        
        if cell.components.count > 2 {
            universalIDType = cell.components[2].description
        }
    }
}
