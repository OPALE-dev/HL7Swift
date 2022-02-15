//
//  File.swift
//  
//
//  Created by Rafael Warnault on 14/02/2022.
//

import Foundation

/**
 Represents a Time String
 */
public struct TS {
    public var time:String?
    public var degreeOfPrecision:String?
    
    public var field:Field

    public init(_ field:Field) {
        self.field = field
        
        if self.field.cells[0].components.count == 0 {
            time = self.field.cells[0].description
            
        } else {
            if self.field.cells[0].components.count > 0 {
                time = self.field.cells[0].components[0].description
            }
            
            if self.field.cells[0].components.count > 1 {
                degreeOfPrecision = self.field.cells[0].components[3].description
            }
        }
    }
}
