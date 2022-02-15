//
//  File.swift
//  
//
//  Created by Rafael Warnault on 14/02/2022.
//

import Foundation


/**
 Represents a Person Location
 */
public struct PL {
    var pointOfCare:String?
    var room:String?
    var bed:String?
    var facility:String?
    var locationStatus:String?
    var personLocationType:String?
    var building:String?
    var floor:String?
    var locationDescription:String?
    var comprehensiveLocationIdentifier:String?
    var assigningAuthorityForLocation:String?
    
    var cell:Cell

    public init(_ cell:Cell) {
        self.cell = cell
        
        if cell.components.count > 0 {
            pointOfCare = cell.components[0].description
        }
        
        if cell.components.count > 1 {
            room = cell.components[1].description
        }
        
        if cell.components.count > 2 {
            bed = cell.components[2].description
        }
        
        if cell.components.count > 3 {
            facility = cell.components[3].description
        }
        
        if cell.components.count > 4 {
            locationStatus = cell.components[4].description
        }
        
        if cell.components.count > 5 {
            personLocationType = cell.components[5].description
        }
        
        if cell.components.count > 6 {
            building = cell.components[6].description
        }
        
        if cell.components.count > 7 {
            floor = cell.components[7].description
        }
        
        if cell.components.count > 8 {
            locationDescription = cell.components[8].description
        }
        
        if cell.components.count > 9 {
            comprehensiveLocationIdentifier = cell.components[9].description
        }
        
        if cell.components.count > 10 {
            assigningAuthorityForLocation = cell.components[10].description
        }
    }
}
