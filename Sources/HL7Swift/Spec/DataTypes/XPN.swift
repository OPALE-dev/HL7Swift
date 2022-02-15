//
//  File.swift
//  
//
//  Created by Rafael Warnault on 14/02/2022.
//

import Foundation
import ModelsR4

/**
 Represents a Person Name
 */
public struct XPN {
    var familyName:String?
    var givenName:String?
    var secondAndFurtherGivenNamesOrInitialsThereof:String?
    var suffix:String?
    var prefix:String?
    var degree:String?
    var nameTypeCode:String?
    var nameRepresentationCode:String?
    var nameContext:String?
    var nameValidityRange:String?
    var nameAssemblyOrder:String?
    
    var cell:Cell
    
    public init(_ cell:Cell) {
        self.cell = cell
                
        if cell.components.count > 0 {
            familyName = cell.components[0].description
        }
        
        if cell.components.count > 1 {
            givenName = cell.components[1].description
        }
        
        if cell.components.count > 2 {
            secondAndFurtherGivenNamesOrInitialsThereof = cell.components[2].description
        }
        
        if cell.components.count > 3 {
            suffix = cell.components[3].description
        }
        
        if cell.components.count > 4 {
            prefix = cell.components[4].description
        }
        
        if cell.components.count > 5 {
            degree = cell.components[5].description
        }
        
        if cell.components.count > 6 {
            nameTypeCode = cell.components[6].description
        }
        
        if cell.components.count > 7 {
            nameRepresentationCode = cell.components[7].description
        }
        
        if cell.components.count > 8 {
            nameContext = cell.components[8].description
        }
        
        if cell.components.count > 9 {
            nameValidityRange = cell.components[9].description
        }
        
        if cell.components.count > 10 {
            nameAssemblyOrder = cell.components[10].description
        }
    }
    
    
    var nameUse:NameUse? {
        if nameTypeCode == "B" {
            return .usual
        }
        else if nameTypeCode == "U" {
            return .anonymous
        }
        else if nameTypeCode == "M" {
            return .maiden
        }
        else if nameTypeCode == "A" {
            return .nickname
        }
        else if nameTypeCode == "N" {
            return .nickname
        }
        else if nameTypeCode == "L" {
            return .official
        }
        
        return .official
    }
}
