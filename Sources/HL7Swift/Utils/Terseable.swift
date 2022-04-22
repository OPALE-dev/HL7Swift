//
//  TerserPath.swift
//  
//
//  Created by Paul on 21/04/2022.
//

import Foundation

public extension Node {
    
    /**
     
     */
    public func dices() -> [Int] {
        guard let root = self.root() else { return [] }
        let nodes = self.nodePath()
        
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
                            print("g.name", g.name)
                            nodesIndices.append(indice)
                            
                            var nextIndices = _indices(firstNode, currentNodes: Array(currentNodes.dropFirst()))
                            nextIndices = nextIndices.map { $0 + (nodesIndices.last ?? 0) + 1 }
                            nodesIndices.append(contentsOf: nextIndices)
                            print("nodesIndices", nodesIndices)
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
                            print("nodesIndices", nodesIndices)
                        } else {
                            indice += 1
                        }
                    } else {
                        indice += 1
                    }
                }
            }
        } else if let currentSegment = currentNode as? Segment {
            
            print("currentSegment", currentSegment.code)
            for field in currentSegment.sortedFields {
                if let firstNode = currentNodes.first as? Field {
                    if firstNode.description == field.description {
                        
                        nodesIndices.append(indice)
                        print("nodesIndices", nodesIndices)
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
    
    
    /**
     
     */
    func nodePath() -> [Node] {
        print("nodePath")
        var nodes: [Node] = []

        if self is Group {
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
        } else if self is Segment {
            if let parentNode = parent as? Group {
                nodes = parentNode.nodePath()
            }
            
            nodes.append(self)
        } else if self is Field {
            if let parentNode = parent as? Segment {
                nodes = parentNode.nodePath()
            }
            
            nodes.append(self)
        }
        // TODO: handle Cell case ?
        
        return nodes
    }
}
