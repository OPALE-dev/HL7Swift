//
//  File.swift
//  
//
//  Created by Rafael Warnault on 14/02/2022.
//

import Foundation


/**
 Represents a Phone Number
 */
public struct XTN {
    var telephoneNumber:String?
    var telecommunicationUseCode:String?
    var telecommunicationEquipmentType:String?
    var emailAddress:String?
    var countryCode:String?
    var areaCityCode:String?
    var localNumber:String?
    var phoneExtension:String?
    var anyText:String?
    var extensionPrefix:String?
    var speedDialCode:String?
    var unformattedTelephoneNumber:String?
    
    var cell:Cell

    public init(_ cell:Cell) {
        self.cell = cell
        
        if cell.components.count > 0 {
            telephoneNumber = cell.components[0].description
        }
        
        if cell.components.count > 1 {
            telecommunicationUseCode = cell.components[1].description
        }
        
        if cell.components.count > 2 {
            telecommunicationEquipmentType = cell.components[2].description
        }
        
        if cell.components.count > 3 {
            emailAddress = cell.components[3].description
        }
        
        if cell.components.count > 4 {
            countryCode = cell.components[4].description
        }
        
        if cell.components.count > 5 {
            areaCityCode = cell.components[5].description
        }
        
        if cell.components.count > 6 {
            localNumber = cell.components[6].description
        }
        
        if cell.components.count > 7 {
            phoneExtension = cell.components[7].description
        }
        
        if cell.components.count > 8 {
            anyText = cell.components[8].description
        }
        
        if cell.components.count > 9 {
            extensionPrefix = cell.components[9].description
        }
        
        if cell.components.count > 10 {
            speedDialCode = cell.components[10].description
        }
        
        if cell.components.count > 11 {
            unformattedTelephoneNumber = cell.components[11].description
        }
    }
}
