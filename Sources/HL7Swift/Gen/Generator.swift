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
    
    mutating func append(_ child: Node)
    
    func generate(_ level:Int) -> String
}


extension Node {
    mutating func append(_ child: Node) {
        if !nodes.contains(where: { node in node.name == child.name }) {
            self.nodes.append(child)
        }
    }
}


/*
 A Swift code generator to ease generation of specification
 related enums, class and other structures.
 */
public struct Generator {
    public struct Switch: Node {
        var name: String
        var defaultCase:String = "default: break"
        
        var vivibility: Visibility = .Unspecified
        var protocols: [String] = []
        var nodes: [Node] = []
        
        func generate(_ level: Int = 0) -> String {
            var code = ""
            var prefix = ""
            
            // compute indentation prefix
            for _ in 0..<level {
                prefix += "  "
            }
            
            // start struct
            code += "\(prefix)switch \(name) {\n"
            
            // recurscively append child nodes
            for node in nodes {
                code += "\(prefix)\(node.generate(level+1))"
            }
            
            code += "\(prefix)\(defaultCase)"
        
            // close struct bracket
            code += "\n\(prefix)}\n\n"
            
            return code
        }
    }
    
    
    public struct Instruction: Node {
        var name: String
        
        var vivibility: Visibility = .Unspecified
        var protocols: [String] = []
        var nodes: [Node] = []
        
        func generate(_ level: Int = 0) -> String {
            var prefix = ""
            
            // compute indentation prefix
            for _ in 0..<level {
                prefix += "  "
            }
            
            return "\(prefix)\(name)\n"
        }
    }
    
    public struct Function: Node {
        var name: String
        
        var vivibility: Visibility = .Unspecified
        var protocols: [String] = []
        var nodes: [Node] = []
        
        var override:Bool = false
        var parameters: [String] = []
        var returnType: String
        
        func generate(_ level: Int = 0) -> String {
            var code = ""
            var prefix = ""
            
            // compute indentation prefix
            for _ in 0..<level {
                prefix += "  "
            }

            // deal with visibility
            if vivibility != .Unspecified {
                code += "\(vivibility.rawValue) "
            }
                        
            // start func
            code += "\(prefix)\(override ? "override " : "")func \(name)(\(parameters.joined())) -> \(returnType) {\n"
            
            // recurscively append child nodes
            for node in nodes {
                code += "\(prefix)\(node.generate(level+1))"
            }
            
            // close func bracket
            code += "\n\(prefix)}\n\n"
            
            return code
        }
    }
    
    public struct Extension: Node {
        var name: String
        
        var vivibility: Visibility = .Unspecified
        var protocols: [String] = []
        var nodes: [Node] = []
        
        func generate(_ level: Int = 0) -> String {
            var code = ""
            var prefix = ""
            
            // compute indentation prefix
            for _ in 0..<level {
                prefix += "  "
            }

            // deal with visibility
            if vivibility != .Unspecified {
                code += "\(vivibility.rawValue) "
            }
            
            // start struct
            code += "\(prefix)extension \(name) {\n"
            
            // recurscively append child nodes
            for node in nodes {
                code += "\(prefix)\(node.generate(level+1))"
            }
            
            // close struct bracket
            code += "\n\(prefix)}\n\n"
            
            return code
        }
    }
    
    
    public struct Case: Node {
        var name: String
        var value: String
        var separator:String = "="
        
        var vivibility: Visibility = .Unspecified
        var protocols: [String] = []
        var nodes: [Node] = []
        
        func generate(_ level: Int = 0) -> String {
            var prefix = ""
            
            // compute indentation prefix
            for _ in 0..<level {
                prefix += "  "
            }
            
            return "\(prefix)case \(name) \(separator) \(value)\n"
        }
    }
    
    public struct Enum: Node {
        var name: String
        var type: String
        var cases:[Case] = []
        
        var vivibility: Visibility = .Unspecified
        var protocols: [String] = []
        var nodes: [Node] = []
        
        func generate(_ level: Int = 0) -> String {
            var code = ""
            var prefix = ""
            
            // compute indentation prefix
            for _ in 0..<level {
                prefix += "  "
            }

            // deal with visibility
            if vivibility != .Unspecified {
                code += "\(vivibility.rawValue) "
            }
            
            // start struct
            code += "\(prefix)enum \(name):\(type) {\n"
            
            // recurscively append child nodes
            for node in nodes {
                code += "\(prefix)\(node.generate(level+1))"
            }
            
            // close struct bracket
            code += "\n\(prefix)}\n\n"
            
            return code
        }
    }
    
    public struct Class: Node {
        var name: String
        
        var nodes: [Node] = []
        var protocols: [String] = []
        var properties: [String] = []
        var vivibility:Visibility = .Unspecified
        
        func generate(_ level:Int = 0) -> String {
            var code = ""
            var prefix = ""
            
            // compute indentation prefix
            for _ in 0..<level {
                prefix += "  "
            }

            // deal with visibility
            if vivibility != .Unspecified {
                code += "\(vivibility.rawValue) "
            }
            
            // start struct
            code += "\(prefix)class \(name)"
            
            // add protocols before opening bracket
            if !protocols.isEmpty {
                code += ": "
                for p in protocols {
                    code += p
                    
                    if p != protocols.last {
                        code += ", "
                    }
                }
            }
            
            // open struct bracket
            code += " {\n"
            
            // append propoerties
            for p in properties {
                code += "\(prefix)\(prefix)\(p)\n"
            }
            
            // recurscively append child nodes
            for node in nodes {
                code += "\(prefix)\(node.generate(level+1))"
            }
            
            // close struct bracket
            code += "\n\(prefix)}\n\n"
            
            return code
        }
    }
    
    public struct Struct: Node {
        var name: String
        
        var nodes: [Node] = []
        var protocols: [String] = []
        var properties: [String] = []
        var vivibility:Visibility = .Unspecified
        
        func generate(_ level:Int = 0) -> String {
            var code = ""
            var prefix = ""
            
            // compute indentation prefix
            for _ in 0..<level {
                prefix += "  "
            }

            // deal with visibility
            if vivibility != .Unspecified {
                code += "\(vivibility.rawValue) "
            }
            
            // start struct
            code += "\(prefix)struct \(name)"
            
            // add protocols before opening bracket
            if !protocols.isEmpty {
                code += ": "
                for p in protocols {
                    code += p
                    
                    if p != protocols.last {
                        code += ", "
                    }
                }
            }
            
            // open struct bracket
            code += " {\n"
            
            // append propoerties
            for p in properties {
                code += "\(prefix)\(prefix)\(p)\n"
            }
            
            // recurscively append child nodes
            for node in nodes {
                code += "\(prefix)\(node.generate(level+1))"
            }
            
            // close struct bracket
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

