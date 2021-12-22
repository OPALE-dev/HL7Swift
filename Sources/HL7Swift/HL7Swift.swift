import Foundation


// Not used that much
struct Group {
    var name: String
    var item: Item
}
// Not used that much
indirect enum Item {
    case group(Group)
    case segments([Segment])
}





public struct Segment {
    var code: String = ""
    var fields: [Field] = []
    
    init(_ str: String) {
        
        var strCloneSplit = str.split(separator: "|", maxSplits: 50, omittingEmptySubsequences: false)
        
        code = String(strCloneSplit.remove(at: 0))
                    
        if strCloneSplit[0].contains("^") && strCloneSplit[0].contains("~") {
            fields.append(Field([Cell(String(strCloneSplit.remove(at: 0)), isEncoding: true)]))
        }
        
        
        for field in strCloneSplit {
            fields.append(Field(String(field)))
        }
        
    }
}

extension Segment: CustomStringConvertible {
    public var description: String {
        var str = code + "|"

        for field in fields {
            str += field.description + "|"
        }
        
        // remove last |
        str.removeLast()

        return str
    }
}

public struct Field {
    var cells: [Cell] = []
    
    init(_ str: String) {
        if str.contains("~") {
            for cell in str.split(separator: "~", maxSplits: 20, omittingEmptySubsequences: false) {
                cells.append(Cell(String(cell)))
            }
        } else {
            cells.append(Cell(str))
        }
    }
    
    init(_ cellsToCopy: [Cell]) {
        cells = cellsToCopy
    }
}

extension Field: CustomStringConvertible {
    public var description: String {
        var str = ""
        
        for cell in cells {
            str += cell.description + "~"
        }
        
        // remove last ~
        str.removeLast()
        
        return str
    }
}

public struct Cell {
    var text: String = ""
    var components: [Cell] = []
    
    init(_ str: String, isEncoding: Bool = false) {
        if isEncoding {
            text = str
        } else {
            if str.contains("^") {
                for component in str.split(separator: "^", maxSplits: 20, omittingEmptySubsequences: false) {
                    components.append(Cell(String(component)))
                }
            } else if str.contains("&") {
                for component in str.split(separator: "&", maxSplits: 20, omittingEmptySubsequences: false) {
                    components.append(Cell(String(component)))
                }
            } else {
                text = str
            }
        }
    }
}

extension Cell: CustomStringConvertible {
    public var description: String {
        
        if components.isEmpty {
            return text
        }
        
        var str = ""
        
        for component in components {
            str += component.text
            for subcomponent in component.components {
                str += subcomponent.text

                str += "&"
            }
            if str.last == "&" {
                str.removeLast()
            }
            
            str += "^"
        }
        if str.last == "^" {
            str.removeLast()
        }
        
        return str
    }
}
