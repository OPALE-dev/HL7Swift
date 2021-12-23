//
//  Group.swift
//  
//
//  Created by Paul on 23/12/2021.
//

import Foundation

public struct Group {
    public var name: String = ""
    public var item: Item
}

public indirect enum Item {
    case group(Group)
    case segments([Segment])
}
