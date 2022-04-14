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
                } else {
                    if let foundGroup = itemGroup[name] {
                        return foundGroup
                    }
                }
            default:
                continue
            }
        }
        return nil
    }
    
    
    
    public var description: String {
        return name
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
                case .group(let itemGroup):
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
                case .group(let itemGroup):
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
                for f in segment.sortedFields {
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
                str += segment.name
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
                    for f in segment.sortedFields {
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
    internal func populate(group:Group? = nil, from message:Message, index: Int = 0) {
        var ding = false
        var superIndex = index
        
        for item in items {
            switch item {
            case .segment(let segment):
                
                // append messages segments (and repetitions)
                for (sIndex, messageSegment) in message.segments[superIndex...].enumerated() {
                    
                    if messageSegment.code == segment.code {
                        ding = true
                        var i = 1
                        
                        // populate segments attributes (longName, index, etc.), we already have the value
                        
                        for f1 in segment.sortedFields {
                            if  i < messageSegment.fields.count + 1 {

                                // messageSegment.parent       = group // segment.parent
                                messageSegment.minOccurs    = segment.minOccurs
                                messageSegment.maxOccurs    = segment.maxOccurs
                                // copy everything from the field except cells
                                messageSegment.fields[i]?.parent     = messageSegment
                                messageSegment.fields[i]?.longName   = f1.longName
                                messageSegment.fields[i]?.name       = f1.name
                                messageSegment.fields[i]?.type       = f1.type
                                messageSegment.fields[i]?.index      = f1.index
                                messageSegment.fields[i]?.maxLength  = f1.maxLength
                                messageSegment.fields[i]?.minLength  = f1.minLength
                                messageSegment.fields[i]?.item       = f1.item
                                messageSegment.fields[i]?.minOccurs  = f1.minOccurs
                                messageSegment.fields[i]?.maxOccurs  = f1.maxOccurs
                                messageSegment.fields[i]?.segmentCode  = f1.segmentCode
                            }

                            i += 1
                        }
                        
                        // populate min/maxOccurs by datatypes
                        for f in messageSegment.sortedFields {
                            f.parent = messageSegment
                            for cell in f.cells {
                                cell.type = f.type
                                var j = 0
                                for comp in cell.components {
                                    if let compositeType = f.type as? CompositeType {
                                        if j < compositeType.types.count {
                                            let composedType = compositeType.types[j]
                                            comp.type = composedType
                                            comp.minOccurs = composedType.minOccurs
                                            comp.maxOccurs = composedType.maxOccurs
                                        }
                                    }
                                    j += 1
                                }
                            }
                        }
                        
                        // append populated segment to the current group
                        group?.items.append(Item.segment(messageSegment))
                        
                        // also append segment to root group segment array for efficiency
                        if let root = message.rootGroup {
                            if !root.segments.map({ $0.code }).contains(messageSegment.code) {
                                root.segments.append(messageSegment)
                            }
                        }
                        
                    } else {
                        if ding {
                            superIndex = sIndex + superIndex
                            break
                        }
                    }
                }
            case .group(let itemGroup):
                let newGroup = Group(name: itemGroup.name)
                
                newGroup.parent = group // self
                itemGroup.populate(group: newGroup, from: message, index: superIndex)
                
                // append clone group to current group
                group?.items.append(Item.group(newGroup))
            }
        }
        
        group?.items.forEach() { $0.setParent(group) }
    }
    
    
    /**
     Gets a segment under the group tree; it's recursive
     
     - TODO: handle repetition
     */
    public func getSegment(_ code: String) -> Segment? {
        for item in items {
            switch item {
            case .segment(let s):
                if s.code == code {
                    return s
                }
            case .group(let g):
                if let s = g.getSegment(code) {
                    return s
                }
            }
        }
        
        return nil
    }

    public func tersePath(_ segment: Segment?) -> String {
        if let p = parent as? Group {
            if let s = segment {
                                
                var sameSegmentsCount = 0
                for i in items {
                    switch i {
                    case .segment(let s2):
                        if s2.code == s.code {
                            sameSegmentsCount += 1
                        }
                    case .group(_):
                        let _ = 1
                    }
                }
                
                if sameSegmentsCount == 1 {
                    return "\(p.tersePath(nil))/\(name)"
                } else {
                    var rep = 0
                    for (ind, i) in items.enumerated() {
                        switch i {
                        case .segment(let s2):
                            if s2.description == s.description {
                                rep = ind
                            }
                        case .group(_):
                            let _ = 1
                        }
                    
                    }

                    if rep == 0 {
                        return "\(p.tersePath(nil))/\(name)"
                    } else {
                        return "\(p.tersePath(nil))/\(name)(\(rep + 1))"
                    }
                }
            } else {
                return "\(p.tersePath(nil))/\(name)"
            }
        } else {
            return ""
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
    
    public func tersePath() -> String {
        switch self {
        case .group(let group):
            return group.tersePath(nil)
        case .segment(let segment):
            return segment.tersePath()
        }
    }
    
    public func setParent(_ n: Node?) {
        switch self {
        case .group(let group):
            group.parent = n
        case .segment(let segment):
            segment.parent = n
        }
    }
}
