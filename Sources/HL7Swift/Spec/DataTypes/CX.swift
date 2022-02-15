//
//  File.swift
//  
//
//  Created by Rafael Warnault on 14/02/2022.
//

import Foundation

/**
 Represents a Patient Identifier
 */
public struct CX {
    public var id:String?
    public var checkDigit:String?
    public var checkDigitScheme:String?
    public var assigningAuthority:String?
    public var identifierTypeCode:String?
    public var assigningFacility:String?
    public var effectiveDate:Date?
    public var expirationDate:Date?
    
    public var cell:Cell

    public init(_ cell:Cell) {
        self.cell = cell
        
        if cell.components.count > 0 {
            id = cell.components[0].description
        }
        
        if cell.components.count > 1 {
            checkDigit = cell.components[1].description
        }
        
        if cell.components.count > 2 {
            checkDigitScheme = cell.components[2].description
        }
        
        if cell.components.count > 3 {
            assigningFacility = cell.components[3].description
        }
        
        if cell.components.count > 4 {
            identifierTypeCode = cell.components[4].description
        }
        
        if cell.components.count > 5 {
            assigningFacility = cell.components[5].description
        }
    }
}
