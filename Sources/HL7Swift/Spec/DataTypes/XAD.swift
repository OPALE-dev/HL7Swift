//
//  File.swift
//  
//
//  Created by Rafael Warnault on 14/02/2022.
//

import Foundation
import ModelsR4





/**
 Represents a postal address
 */
public struct XAD {
    public var streetAddress:String?
    public var otherDesignation:String?
    public var city:String?
    public var stateOrProvince:String?
    public var zipOrPostalCode:String?
    public var country:String?
    public var addressType:String?
    public var otherGeographicDesignation:String?
    public var countyParishCode:String?
    public var censusTract:String?
    public var addressRepresentationCode:String?
    public var addressValidityRange:String?
    public var effectiveDate:String?
    public var expirationDate:String?
    
    public var cell:Cell

    public init(_ cell:Cell) {
        self.cell = cell
                
        if cell.components.count > 0 {
            streetAddress = cell.components[0].description
        }
        
        if cell.components.count > 1 {
            otherDesignation = cell.components[1].description
        }
        
        if cell.components.count > 2 {
            city = cell.components[2].description
        }
        
        if cell.components.count > 3 {
            stateOrProvince = cell.components[3].description
        }
        
        if cell.components.count > 4 {
            zipOrPostalCode = cell.components[4].description
        }
        
        if cell.components.count > 5 {
            country = cell.components[5].description
        }
        
        if cell.components.count > 6 {
            addressType = cell.components[6].description
        }

        if cell.components.count > 7 {
            otherGeographicDesignation = cell.components[7].description
        }

        if cell.components.count > 8 {
            countyParishCode = cell.components[8].description
        }

        if cell.components.count > 9 {
            censusTract = cell.components[9].description
        }

        if cell.components.count > 10 {
            addressRepresentationCode = cell.components[10].description
        }

        if cell.components.count > 11 {
            addressValidityRange = cell.components[11].description
        }

        if cell.components.count > 12 {
            effectiveDate = cell.components[12].description
        }

        if cell.components.count > 13 {
            expirationDate = cell.components[13].description
        }
    }
    
    
    public var addressUse:AddressUse? {
        if addressType?.lowercased() == "BA".lowercased() || addressType == "Bad address".lowercased() {
            return .old
        }
        else if addressType?.lowercased() == "L".lowercased() || addressType == "Legal address".lowercased() {
            return .billing
        }
        else if addressType?.lowercased() == "H".lowercased() || addressType == "Home".lowercased() {
            return .home
        }
        else if addressType?.lowercased() == "P".lowercased() || addressType == "Permanent".lowercased() {
            return .home
        }
        else if addressType?.lowercased() == "O".lowercased() || addressType == "Office".lowercased() {
            return .work
        }
        else if addressType?.lowercased() == "C".lowercased() || addressType == "Current".lowercased() {
            return .temp
        }
        
        return nil
    }
}


