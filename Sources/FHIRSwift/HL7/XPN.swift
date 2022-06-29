//
//  File.swift
//  
//
//  Created by Rafael Warnault on 14/02/2022.
//

import Foundation
import ModelsR4
import HL7Swift


/**
 Represents a Person Name
 */
public extension XPN {
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
