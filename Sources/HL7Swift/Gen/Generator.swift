//
//  File.swift
//  
//
//  Created by Rafael Warnault on 05/01/2022.
//

import Foundation

enum Visibility:String {
    case Public         = "public"
    case Private        = "private"
    case Internal       = "internal"
    case Unspecified    = ""
}

protocol Node {
    var name:String { get set }
    var vivibility:Visibility { get set }
    var protocols: [String] { get set }
    var nodes:[Node] { get set }
    
    func generate(_ level:Int) -> String
}


/*
 A Swift code generator to ease generation of specification
 related enums, class and other structures.
 */
public struct Generator {
    public struct Struct: Node {
        var name: String
        
        var nodes: [Node] = []
        var protocols: [String] = []
        var vivibility:Visibility = .Unspecified
        
        func generate(_ level:Int = 0) -> String {
            var code = ""
            var prefix = ""
            
            for _ in 0..<level {
                prefix += "\t"
            }
            
            if vivibility != .Unspecified {
                code += "\(vivibility.rawValue) "
            }
            
            code += "\(prefix)struct \(name)"
            
            if !protocols.isEmpty {
                code += ": "
                for p in protocols {
                    code += p
                    
                    if p != protocols.last {
                        code += ", "
                    }
                }
            }
            
            code += " {\n"
            
            for node in nodes {
                code += "\(prefix)\(node.generate(level+1))"
            }
            
            code += "\n\(prefix)}\n\n"
            
            return code
        }
    }
    
    
    static func generateEnums(name: String, type: Any, list:[String], vivibility:Visibility) -> String {
        var code = "\(vivibility.rawValue) enum \(name): \(type.self) {\n"
        
        for item in list {
            code += "\tcase \(item) = \"\(item)\"\n"
        }
        
        code += "\n}"
        
        return code
    }

    static func generateStructs(protocols: [String], list:[String], vivibility:Visibility) -> String {
        var code = ""
        
        for item in list {
            code += "\(vivibility.rawValue) struct \(item)"
            
            if !protocols.isEmpty {
                code += ": "
                for p in protocols {
                    code += p
                    
                    if p != protocols.last {
                        code += ", "
                    }
                }
            }
            
            code += " {\n"
            code += "\n}\n\n"
        }        
        
        return code
    }
    
    static func generateClasses(inherits: [String], list:[String], vivibility:Visibility) -> String {
        var code = ""
        
        for item in list {
            code += "\(vivibility.rawValue) class \(item)"
            
            if !inherits.isEmpty {
                code += ": "
                for p in inherits {
                    code += p
                    
                    if p != inherits.last {
                        code += ", "
                    }
                }
            }
            
            code += " {\n"
            code += "\n}\n\n"
        }
        
        return code
    }
}

