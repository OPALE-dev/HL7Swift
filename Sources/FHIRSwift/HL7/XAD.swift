//
//  File.swift
//  
//
//  Created by Rafael Warnault on 14/02/2022.
//

import Foundation
import HL7Swift
import ModelsR4





/**
 Represents a postal address
 */
public extension XAD {
    var addressUse:AddressUse? {
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


