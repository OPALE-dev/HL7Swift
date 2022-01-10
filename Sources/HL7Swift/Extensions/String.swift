//
//  File.swift
//  
//
//  Created by Rafael Warnault on 07/01/2022.
//

import Foundation

public extension String {
    func symbolyze() -> String {
        return  self.replacingOccurrences(of: " ", with: "_")
                    .replacingOccurrences(of: "/", with: "_")
                    .replacingOccurrences(of: "+", with: "_")
                    .replacingOccurrences(of: "-", with: "_")
                    .replacingOccurrences(of: "–", with: "_")
                    .replacingOccurrences(of: "'", with: "")
                    .replacingOccurrences(of: "’", with: "")
                    .replacingOccurrences(of: ".", with: "_")
                    .replacingOccurrences(of: ",", with: "")
                    .replacingOccurrences(of: "(", with: "")
                    .replacingOccurrences(of: ")", with: "")
                    .replacingOccurrences(of: "\"", with: "")
                    .replacingOccurrences(of: "&", with: "And")
                    .replacingOccurrences(of: "*", with: "All")
                    .replacingOccurrences(of: "#", with: "Dash")
    }
}
