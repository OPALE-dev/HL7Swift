//
//  Message.swift
//  
//
//  Created by Paul on 22/12/2021.
//

import Foundation

public struct Message {
    var segments: [Segment] = []
    var sep:Character = "\r"
    
    init(_ str: String) {
        if str.split(separator: "\r").count > 1 {
            sep = "\r"
        } else if str.split(separator: "\n").count > 1 {
            sep = "\n"
        } else if str.split(separator: "\r\n").count > 1 {
            sep = "\r\n"
        }

        // TODO separate by newline or \r ?
        for segment in str.split(separator: sep) {
            segments.append(Segment(String(segment)))
        }
    }
    
    func getType() -> String {
        return segments[0].fields[7].cells[0].components[2].text
    }
    
    func getVersion() -> String {
        return segments[0].fields[10].cells[0].text
    }
}

extension Message: CustomStringConvertible {
    public var description: String {
        var str = ""
        for segment in segments {
            str += segment.description + sep.description
        }
        str.removeLast()
        return str
    }
}
