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
    public var namespaceID:String?
    public var universalID:String?
    public var universalIDType:String?

    public var cell:Cell

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
