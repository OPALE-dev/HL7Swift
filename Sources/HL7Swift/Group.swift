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
        if name == underGroupName {
            items.append(Item.segment(segment))
            
            return true
        } else {
            for item in items {
                switch item {
                case .group(var itemGroup):
                    return itemGroup.appendSegment(segment: segment, underGroupName: underGroupName)
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
            for item in items {
                switch item {
                case .group(var itemGroup):
                    return itemGroup.appendGroup(group: group, underGroupName: underGroupName)
                default:
                    continue
                }
            }
        }
        
        return false
    }
}

public indirect enum Item {
    case group(Group)
    case segment(Segment)
}
