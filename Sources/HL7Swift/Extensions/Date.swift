//
//  File.swift
//  
//
//  Created by Rafaël Warnault on 26/04/2022.
//

import Foundation

let dateOnlyFormatter = DateFormatter()
let dateAndTimeSimpleFormatter = DateFormatter()
let dateAndTimeLongFormatter = DateFormatter()

public extension Date {
    
    
    // Global.HL7DateTimeFormatter.dateFormat = "yyyyMMddHHmmss"
    
    static func HL7Date(from string: String) -> Date? {
        dateOnlyFormatter.dateFormat = "yyyyMMdd"
        dateAndTimeSimpleFormatter.dateFormat = "yyyyMMddHHmm"
        dateAndTimeLongFormatter.dateFormat = "yyyyMMddHHmmss"
        
        if string.count == 8 {
            return dateOnlyFormatter.date(from: string)
        }
        else if string.count == 12 {
            return dateAndTimeSimpleFormatter.date(from: string)
        }
        else if string.count == 14 {
            return dateAndTimeLongFormatter.date(from: string)
        }
        else if string.count == 19 {
            if string.contains("-") {
                if let comp = string.split(separator: "-").first {
                    return HL7Date(from: String(comp))
                }
            }
        }
        else if string.count == 23 {
            if string.contains(".") {
                if let comp = string.split(separator: ".").first {
                    return HL7Date(from: String(comp))
                }
            }
        }
        
        return nil
    }
}
