//
//  File.swift
//  
//
//  Created by Rafael Warnault on 12/01/2022.
//

import Foundation

/**
 Abstract datatype type
 */
protocol DataTypable {
    var name:String { get set }
    var base:String { get set }
}

/**
 Base class implementing DataTypable
 */
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

/**
 Simple HL7 datatype
 */
public class SimpleType: DataType {

}

/**
 Component HL7 datatype (they compose composite types, embedded in `ComposedType` as proxy)
 */
public class ComponentType: DataType {
    var type:String = ""
    var longName:String = ""
    var index:Int = -1
    
    override public init(name: String) {
        super.init(name: name)
        
        let comps = name.split(separator: ".")
        self.name = String(comps[0] + "." + comps[1])
        self.index = Int(comps[1])!
    }
    
    public override var description: String {
        "\(Swift.type(of: self)) \(name).\(index) (\(longName))"
    }
}

/**
 A proxy type to encapsulate `ComponentType` alongside with `minOccurs` and `maxOccurs` attributes
 */
public class ComposedType: DataType {
    // -1 means unbounded
    public var minOccurs:Int!
    public var maxOccurs:Int!
    var type:DataType!

    public init(type: DataType, minOccurs: String = "0", maxOccurs: String = "0") {
        super.init(name: type.name)
        self.type = type
        self.maxOccurs = Int(maxOccurs)
        self.minOccurs = Int(minOccurs)
    }
}

/**
 Component HL7 datatype (composed of `ComponentType` through `ComposedType` proxy)
 */
public class CompositeType: DataType {
    var types:[ComposedType] = []
    
    public override var description: String {
        "\(Swift.type(of: self)) \(name) [\(types.map { t in t.name }.joined(separator: ", "))]"
    }
}
