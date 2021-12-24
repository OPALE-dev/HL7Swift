//
//  Group.swift
//  
//
//  Created by Paul on 23/12/2021.
//

import Foundation

public struct Group {
    public var name: String = ""
    public var items: [Item] = []
    
    /// Appends a segment to the group, under a certain group, eg. ORU_RO1.CONTENT
    /// Returns `true` is the segment was appended
    public mutating func appendSegment(segment: Segment, underGroupName: String) -> Bool {
        print("trying to add segment \(segment.code) to group \(underGroupName) [current \(name)]")
        
        if name == underGroupName {
            items.append(Item.segment(segment))
            
            return true
        } else {
            for index in items.indices {
                switch items[index] {
                case .group(var itemGroup):
                    let rst = itemGroup.appendSegment(segment: segment, underGroupName: underGroupName)
                    items[index] = Item.group(itemGroup)
                    if rst {
                        return rst
                    }

                default:
                    continue
                }
            }
        }
        
        return false
    }
    
    public mutating func appendGroup(group: Group, underGroupName: String) -> Bool {
        if group.name == self.name {
            print("TODO error : can't append a group already appended")
            return false
        } else if group.name == underGroupName {
            print("TODO error : can't append a group under the same group")
            return false
        } else if name == underGroupName {
            items.append(Item.group(group))
            
            return true
        } else {
            for index in items.indices {
                switch items[index] {
                case .group(var itemGroup):
                    let rst = itemGroup.appendGroup(group: group, underGroupName: underGroupName)
                    items[index] = Item.group(itemGroup)
                    if rst {
                        return rst
                    }
                default:
                    continue
                }
            }
        }
        
        return false
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
