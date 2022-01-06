//
//  File.swift
//
//
//  Created by Rafael Warnault on 05/01/2022.
//

import Foundation

public enum Visibility:String {
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
    public init() {
        
    }
    
    public func generateHL7Spec(at path:String) {
        let hl7 = try! HL7()
        
        let versions = [
            Version.v21 ,
            Version.v23,
            Version.v231,
            Version.v24,
            Version.v25,
            Version.v251,
            Version.v26,
            Version.v27,
            Version.v271,
            Version.v28,
            Version.v281,
            Version.v282]
        
        let forlderPath = (path as NSString).expandingTildeInPath
        
        try? FileManager.default.createDirectory(atPath: forlderPath, withIntermediateDirectories: true, attributes: nil)
        
        for version in versions {
            var namespaceExtension = Generator.Extension(name: "HL7")
            
            let versionName = Version.klass(forVersion: version)
            var implementation = Generator.Class(name: "\(versionName)", protocols: ["Versioned"], properties: [])
            var function = Generator.Function(
                name: "type",
                vivibility: .Unspecified,
                protocols: [],
                nodes: [],
                override: true,
                parameters: ["forName name:String"],
                returnType: "Typable?")
            
            var typeSwitch = Generator.Switch(name: "name", defaultCase: "default: return nil")
                            
            for messageType in hl7.spec(ofVersion: version).messages.keys.sorted() {
                typeSwitch.nodes.append(Generator.Case(name: "\"\(messageType)\"", value: "return \(messageType)()", separator: ":"))
                
                //break // Debug first message type
            }
            
            function.nodes.append(typeSwitch)
            
            implementation.nodes.append(function)
            
            for messageType in hl7.spec(ofVersion: version).messages.keys.sorted() {
                var typableStruct = Generator.Class(name: messageType, protocols: ["Typable"])
                let nameInstr = Generator.Instruction(name: "var name:String = \"\(messageType)\"")
                
                typableStruct.nodes.append(nameInstr)
                
                if let message = hl7.spec(ofVersion: version ).messages[messageType] {
                    var fieldTypeEnum = Generator.Enum(name: "FieldType", type: "String")
                    
                    for s in message.rootGroup.segments {
                        for f in s.fields {
                            let symbol = f.longName
                                .replacingOccurrences(of: " ", with: "_")
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
                            
                            let value = f.longName.replacingOccurrences(of: "\"", with: "")

                            // TODO: find a placeholder for « Type » field (reserved word in Swift)
                            if symbol != "Type" {
                                fieldTypeEnum.append(
                                    Generator.Case(name: symbol, value: "\"\(value)\"")
                                )
                            }

                        }
                    }
                    
                    // do not append empty enum!
                    if message.rootGroup.segments.count > 0 {
                        typableStruct.nodes.append(fieldTypeEnum)
                    }
                    
                }
                
                implementation.nodes.append(typableStruct)
                
                 //break // Debug first message type
            }
            
            namespaceExtension.nodes.append(implementation)
            
            let filePath = "\(forlderPath)/\(versionName).swift"
            
            try? namespaceExtension.generate().write(to: URL(fileURLWithPath: filePath), atomically: false, encoding: .utf8)
        }
    }
    
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
}

