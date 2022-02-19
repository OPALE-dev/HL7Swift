//
//  File.swift
//  
//
//  Created by Rafael Warnault on 14/02/2022.
//

import Foundation

/**
 Represents a Person Name
 */
public struct XPN: CustomStringConvertible {
    public var familyName:String?
    public var givenName:String?
    public var secondAndFurtherGivenNamesOrInitialsThereof:String?
    public var suffix:String?
    public var prefix:String?
    public var degree:String?
    public var nameTypeCode:String?
    public var nameRepresentationCode:String?
    public var nameContext:String?
    public var nameValidityRange:String?
    public var nameAssemblyOrder:String?
    public var cell:Cell
    
    public var description: String {
        var names:[String] = []
        
        if let fn = familyName {
            names.append(fn)
        }
        
        if let sn = secondAndFurtherGivenNamesOrInitialsThereof {
            names.append(sn)
        }
            
        if let gn = givenName {
            names.append(gn)
        }
        
        return names.joined(separator: " ")
    }
    
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
}
