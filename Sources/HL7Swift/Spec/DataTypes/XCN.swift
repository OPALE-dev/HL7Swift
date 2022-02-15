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
public struct XCN {
    var idNumber:String?
    var familyName:String?
    var givenName:String?
    var secondAndFurtherGivenNamesOrInitialsThereof:String?
    var suffix:String?
    var prefix:String?
    var degree:String?
    var sourceTable:String?
    var assigningAuthority:String?
    var nameTypeCode:String?
    var identifierCheckDigit:String?
    var checkDigitScheme:String?
    var identifierTypeCode:String?
    var assigningFacility:String?
    var nameRepresentationCode:String?
    var nameContext:String?
    var nameValidityRange:String?
    var nameAssenblyOrder:String?
    var effectiveDate:String?
    var expirationDate:String?
    var professionalSuffix:String?
    var assigningJurisdiction:String?
    var assigningAgencyOrDepartment:String?
    
    var cell:Cell
    
    public init(_ cell:Cell) {
        self.cell = cell
        
        if cell.components.count > 0 {
            idNumber = cell.components[0].description
        }
                
        if cell.components.count > 1 {
            familyName = cell.components[1].description
        }
        
        if cell.components.count > 2 {
            givenName = cell.components[2].description
        }
        
        if cell.components.count > 3 {
            secondAndFurtherGivenNamesOrInitialsThereof = cell.components[3].description
        }
        
        if cell.components.count > 4 {
            suffix = cell.components[4].description
        }
        
        if cell.components.count > 5 {
            prefix = cell.components[5].description
        }
        
        if cell.components.count > 6 {
            degree = cell.components[6].description
        }
        
        if cell.components.count > 7 {
            sourceTable = cell.components[7].description
        }
        
        if cell.components.count > 8 {
            assigningAuthority = cell.components[8].description
        }
        
        if cell.components.count > 9 {
            nameTypeCode = cell.components[9].description
        }
        
        if cell.components.count > 10 {
            identifierCheckDigit = cell.components[10].description
        }
        
        if cell.components.count > 11 {
            checkDigitScheme = cell.components[11].description
        }
        
        if cell.components.count > 12 {
            identifierTypeCode = cell.components[12].description
        }
        
        if cell.components.count > 13 {
            assigningFacility = cell.components[13].description
        }
        
        if cell.components.count > 14 {
            nameRepresentationCode = cell.components[14].description
        }
        
        if cell.components.count > 15 {
            nameContext = cell.components[15].description
        }
        if cell.components.count > 16 {
            nameValidityRange = cell.components[16].description
        }
        
        if cell.components.count > 17 {
            nameAssenblyOrder = cell.components[17].description
        }
        
        if cell.components.count > 18 {
            effectiveDate = cell.components[18].description
        }
        
        if cell.components.count > 19 {
            expirationDate = cell.components[19].description
        }
        if cell.components.count > 20 {
            professionalSuffix = cell.components[20].description
        }
        if cell.components.count > 21 {
            assigningJurisdiction = cell.components[21].description
        }
        if cell.components.count > 22 {
            assigningAgencyOrDepartment = cell.components[22].description
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
