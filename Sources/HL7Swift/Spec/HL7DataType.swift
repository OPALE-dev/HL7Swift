//
//  File.swift
//  
//
//  Created by Rafael Warnault on 12/01/2022.
//

import Foundation

//enum BaseType:String {
//    case DT
//    case DTM
//    case GTS
//    case ID
//    case IS
//    case NM
//    case SI
//    case SNM
//    case ST
//    case TM
//    case TN // deprecated ?
//    case None
//}


protocol DataTypable {
    var name:String { get set }
    var base:String { get set }
}

public class DataType: DataTypable, CustomStringConvertible {
    var name: String
    var base: String = ""
    
    public init(name: String) {
        self.name = name
    }
    
    public var description: String {
        "\(type(of: self)) \(name)"
    }
}

class SimpleType: DataType {

}

class ComponentType: DataType {
    var type:String = ""
    var longName:String = ""
    var index:Int = -1
    
    override public init(name: String) {
        super.init(name: name)
        
        let comps = name.split(separator: ".")
        self.name = String(comps[0] + "." + comps[1])
        self.index = Int(comps[1])!
    }
    
    override var description: String {
        "\(Swift.type(of: self)) \(name).\(index) (\(longName))"
    }
}

class ComposedType: DataType {
    var minOccurs:Int!
    var maxOccurs:Int!
    var type:DataType!

    public init(type: DataType, minOccurs: String = "0", maxOccurs: String = "0") {
        super.init(name: type.name)
        self.type = type
        self.maxOccurs = Int(maxOccurs)
        self.minOccurs = Int(minOccurs)
    }
}

class CompositeType: DataType {
    var types:[ComposedType] = []
    
    override var description: String {
        "\(Swift.type(of: self)) \(name) [\(types.map { t in t.name }.joined(separator: ", "))]"
    }
}
