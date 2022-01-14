//
//  Group.swift
//  
//
//  Created by Paul on 23/12/2021.
//

import Foundation

/**
 A group is a set of segments and/or groups, with a name. It's like a tree
 
 Usage :
 ```
 var rootGroup = Group(name: "R1", items: [])
 
 rootGroup.appendGroup(group: Group(name: "R2", items: []), underGroupName: "R1")
 
 rootGroup.appendSegment(segment: Segment("FSH||||whatever|||"), underGroupName: "R2")
 ```
 */

public protocol Node {
    var name:String { get set }
    var parent:Node? { get set }
}

public class Group:Node {
    public var parent: Node?
    
    public var name: String = ""
    public var items: [Item] = []
    public var segments: [Segment] = []
    
    
    init(parent:Node? = nil, name:String, items: [Item] = []) {
        self.parent = parent
        self.name = name
        self.items = items
    }
    
    /// subscript that return a group item based on its name
    /// Returns `Group` is matching group item found
    subscript(name: String) -> Group? {
        for index in items.indices {
            switch items[index] {
            case .group(let itemGroup):
                if itemGroup.name == name {
                    return itemGroup
                }
            default:
                continue
            }
        }
        return nil
    }
    
    
    /// Appends a segment to the group, under a certain group, eg. ORU_RO1.CONTENT
    /// Returns `true` is the segment was appended
    public func appendSegment(segment: Segment, underGroupName: String) -> Bool {
        var isAppended = false
        
        segments.append(segment)
        
        if name == underGroupName {
            items.append(Item.segment(segment))
            
            isAppended = true
        } else {
            for index in items.indices where isAppended != true {
                switch items[index] {
                case .group(var itemGroup):
                    isAppended = itemGroup.appendSegment(segment: segment, underGroupName: underGroupName)
                    items[index] = Item.group(itemGroup)

                default:
                    continue
                }
            }
        }
        
        return isAppended
    }
    
    /// Appends a group under a given group
    /// Returns `true` if the group is added
    public func appendGroup(group: Group, underGroupName: String) -> Bool {
        var appended = false
        
        if group.name == self.name {
            //print("TODO error : can't append a group already appended")

        } else if group.name == underGroupName {
            //print("TODO error : can't append a group under the same group")

        } else if name == underGroupName {
            items.append(Item.group(group))
            
            appended = true
        } else {
            for index in items.indices where appended != true {
                switch items[index] {
                case .group(var itemGroup):
                    appended = itemGroup.appendGroup(group: group, underGroupName: underGroupName)
                    items[index] = Item.group(itemGroup)
    
                default:
                    continue
                }
            }
        }
        
        return appended
    }
    
    /// Returns a pretty string
    public func pretty(depth: Int = 1) -> String {
        var str = name + ":\n"
        
        for item in items {
            str += String(repeating: "\t", count: depth)
            
            switch item {
            case .group(let group):
                str += group.pretty(depth: depth + 1)
            case .segment(let segment):
                str += segment.code
                for f in segment.fields {
                    str += "|\(f.longName)"
                }
            }
            
            str += "\n"
        }
        
        return str
    }
    
    /// Returns a pretty string
    public func prettyTree(depth: Int = 1) -> String {
        var str = name + ":\n"
        
        for item in items {
            str += String(repeating: "\t", count: depth)
            
            switch item {
            case .group(let group):
                str += group.prettyTree(depth: depth + 1)
            case .segment(let segment):
                str += segment.description
                
            }
            
            str += "\n"
        }
        
        return str
    }
    
    /// Returns a pretty string
    public func prettyTree(printFields: Bool = false, depth: Int = 1) -> String {
        var str = name + ":\n"
        
        for item in items {
            str += String(repeating: "\t", count: depth)
            
            switch item {
            case .group(let group):
                str += group.prettyTree(printFields: printFields, depth: depth + 1)
            case .segment(let segment):
                if printFields {
                    for f in segment.fields {
                        str += String(repeating: "\t", count: depth)
                        str += "\t\(f.longName): \(f.description)\n"
                    }
                } else {
                    str += segment.code
                }
            }
            
            str += "\n"
        }
        
        return str
    }
    
    /**
     Clone self into `group` and populate values from `message` segments.
     Also takes care to append segments with repetitions if needed.
     */
    internal func populate(group:Group? = nil, from message:Message) {
        for item in items {
            switch item {
            case .segment(let segment):
                // append repeated segments
                for messageSegment in message.segments {
                    if messageSegment.code == segment.code {
                        var i = 0
                        
                        for f1 in segment.fields {
                            if  i < messageSegment.fields.count - 1 {
                                messageSegment.minOccurs = segment.minOccurs
                                messageSegment.maxOccurs = segment.maxOccurs
                                // copy everything from the field except cells (we keep message values)
                                messageSegment.fields[i].longName   = f1.longName
                                messageSegment.fields[i].name       = f1.name
                                messageSegment.fields[i].index      = f1.index
                                messageSegment.fields[i].maxLength  = f1.maxLength
                                messageSegment.fields[i].type       = f1.type
                                messageSegment.fields[i].item       = f1.item
                                messageSegment.fields[i].maxLength  = f1.maxLength
                            }
                            i += 1
                        }
                        // append populated segment
                        group?.items.append(Item.segment(messageSegment))
                    }
                }
            case .group(let itemGroup):
                let newGroup = Group(name: itemGroup.name)
                
                itemGroup.populate(group: newGroup, from: message)
                
                group?.items.append(Item.group(newGroup))
            }
        }
    }
}

/// Shortens `"ORU_RO1.PATIENT_RESULT.CONTENT"` to `"PATIENT_RESULT"`
public func shortname(_ longName: String) -> String {
    let a = longName.split(separator: ".")
    //print("a \(a)")
    if a.count == 2 {
        if a[1] == "CONTENT" {
            return String(a[0])
        } else {
            return String(a[1])
        }
    } else if a.count == 3 {
        return String(a[1])
    } else {
        return String(a[0])
    }
}

public indirect enum Item {
    case group(Group)
    case segment(Segment)
}
