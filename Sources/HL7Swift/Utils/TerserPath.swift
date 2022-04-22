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
        if let nf = nodes.first as? Group {
            if nf.name == root.name {
                return _indices(root, currentNodes: Array(nodes.dropFirst()))
            }
        }
        return _indices(root, currentNodes: nodes)
    }
    
    func _indices(_ currentNode: Node, currentNodes: [Node]) -> [Int] {
        if currentNodes.isEmpty { return [] }
        
        var nodesIndices: [Int] = []
        var indice = 0
        
        if let currentGroup = currentNode as? Group {
            
            for item in currentGroup.items {
                switch item {
                case .group(let g):
                    if let firstNode = currentNodes.first as? Group {
                        if firstNode.name == g.name {
                            
                            nodesIndices.append(indice)
                            
                            var nextIndices = _indices(firstNode, currentNodes: Array(currentNodes.dropFirst()))
                            nextIndices = nextIndices.map { $0 + (nodesIndices.last ?? 0) + 1 }
                            nodesIndices.append(contentsOf: nextIndices)
                        } else {
                            indice += 1
                        }
                    } else {
                        indice += 1
                    }
                case .segment(let s):
                    if let firstNode = currentNodes.first as? Segment {
                        if firstNode.description == s.description {
                            
                            nodesIndices.append(indice)
                            
                            var nextIndices = _indices(firstNode, currentNodes: Array(currentNodes.dropFirst()))
                            nextIndices = nextIndices.map { $0 + (nodesIndices.last ?? 0) + 1 }
                            nodesIndices.append(contentsOf: nextIndices)
                        } else {
                            indice += 1
                        }
                    } else {
                        indice += 1
                    }
                }
            }
        } else if let currentSegment = currentNode as? Segment {
                        
            for field in currentSegment.sortedFields {
                if let firstNode = currentNodes.first as? Field {
                    if firstNode.description == field.description {
                        
                        nodesIndices.append(indice)
                    } else {
                        indice += 1
                    }
                } else {
                    indice += 1
                }
            }
        }
        
        return nodesIndices
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
