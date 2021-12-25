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
public struct Group {
    public var name: String = ""
    public var items: [Item] = []
    
    
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
    public mutating func appendSegment(segment: Segment, underGroupName: String) -> Bool {
        var isAppended = false
        
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
    public mutating func appendGroup(group: Group, underGroupName: String) -> Bool {
        var appended = false
        
        if group.name == self.name {
            print("TODO error : can't append a group already appended")

        } else if group.name == underGroupName {
            print("TODO error : can't append a group under the same group")

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
            }
            
            str += "\n"
        }
        
        return str
    }
}

public indirect enum Item {
    case group(Group)
    case segment(Segment)
}
