//
//  TerserPath.swift
//  
//
//  Created by Paul on 21/04/2022.
//

import Foundation

public class TerserPath {
    public var nodes: [Node] = []
    public let message: Message
    
    public init(_ message: Message) {
        self.message = message
    }
    
    public func indices() -> [Int] {
        guard let root = message.rootGroup else { return [] }
        
        return _indices(root, currentNodes: nodes)
    }
    
    public func _indices(_ currentGroup: Group, currentNodes: [Node]) -> [Int] {
        if currentNodes.isEmpty { return [] }
        
        var nodesIndices: [Int] = []
        var indice = 0
        
        for item in currentGroup.items {
            switch item {
            case .group(let g):
                if let firstNode = currentNodes.first as? Group {
                    if firstNode.description == g.description {
                        nodesIndices.append(indice)
                        nodesIndices.append(contentsOf: _indices(firstNode, currentNodes: Array(nodes.dropFirst())))
                    }
                } else {
                    indice += 1
                }
            case .segment(let s):
                if let firstNode = currentNodes.first as? Segment {
                    if firstNode.description == s.description {
                        nodesIndices.append(indice)
                    }
                }
            }
        }
        
        return []
    }
}

extension Group {
    public func toTerserPath(_ message: Message) -> TerserPath {
        var nodes: [Node] = []
        
        if let parentNode = parent {
            if let grandparentNode = parentNode.parent {
                if let grandgrandparentNode = grandparentNode.parent {
                    nodes.append(grandgrandparentNode)
                }
                nodes.append(grandparentNode)
            }
            nodes.append(parentNode)
        }
        nodes.append(self)
        
        let tp = TerserPath(message)
        tp.nodes = nodes
        return tp
    }
}

extension Segment {
    public func toTerserPath(_ message: Message) -> TerserPath {
        var nodes: [Node] = []
        
        if let parentNode = parent as? Group {
            let tp = parentNode.toTerserPath(message)
            nodes = tp.nodes
        }
        
        nodes.append(self)
        
        let tp = TerserPath(message)
        tp.nodes = nodes
        return tp
    }
}

extension Field {
    public func toTerserPath(_ message: Message) -> TerserPath {
        var nodes: [Node] = []
        
        if let parentNode = parent as? Segment {
            let tp = parentNode.toTerserPath(message)
            nodes = tp.nodes
        }
        
        nodes.append(self)
        
        let tp = TerserPath(message)
        tp.nodes = nodes
        return tp
    }
}
