//
//  File.swift
//  
//
//  Created by Rafael Warnault on 13/01/2022.
//

import Foundation

//MARK: XMLParserDelegate methods
extension Versioned:XMLParserDelegate {
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        if loadMessagesFlag {
            if elementName == "xsd:element" {
                if let ref = attributeDict["ref"] {
                    if HL7.generator {
                        messages[ref] = SpecMessage(type: HL7.MessageType(name: ref), version: version)
                    } else {
                        if let type = type(forName: ref) {
                            messages[ref] = SpecMessage(type: type, version: version)
                        }
                    }
                }
            }
        }
        else if loadSegmentsFlag {
            if elementName == "xsd:complexType" {
                currentSequence = (attributeDict["name"])!
                
                currentSequence = shortname(currentSequence!)
                
            } else if elementName == "xsd:element" {
                if let ref = attributeDict["ref"] {
                    if let currentSequence = currentSequence {
                        // is it a segment ?
                        if ref.count == 3 {
                            let segment = Segment(ref, specMessage: currentMessage)
                            
                            if let fields = fields[ref] {
                                segment.fields.append(contentsOf: fields)
                            }
                            
                            _ = currentMessage?.rootGroup?.appendSegment(segment: segment, underGroupName: currentSequence)
                        // it is a group
                        } else {
                            let groupName = shortname(ref)
                            
                            _ = currentMessage?.rootGroup?.appendGroup(group: Group(name: groupName, items: []), underGroupName: currentSequence)
                        }
                    }
                }
            }
        }
        else if loadFieldsFlag {
            if elementName == "xsd:attributeGroup" {
                if let attributeGroup = attributeDict["name"] {
                    let split = attributeGroup.split(separator: ".")
                    
                    if let first = split.first {
                        let segmentCode = String(first)
                        
                        currentField = Field(name: "\(split[0]).\(split[1])")
                        currentField?.segmentCode = segmentCode
                        
                        if let index = Int(split[1]) {
                            currentField?.index = index
                        }
                    }
                }
            } else if elementName == "xsd:attribute" {
                if let name = attributeDict["name"] {
                    if name == "Item" {
                        currentField?.item = attributeDict["fixed"]!
                    }
                    else if name == "Type" {
                        if let type = dataTypes[attributeDict["fixed"]!] {
                            currentField?.type = type
                        }
                    }
                    else if name == "LongName" {
                        currentField?.longName = attributeDict["fixed"]!
                    }
                    else if name == "maxLength" {
                        currentField?.maxLength = Int(attributeDict["fixed"]!)!
                    }
                }
            }
        }
        else if loadDataTypesFlag {
            if elementName == "xsd:simpleType" {
                currentDataType = SimpleType(name: attributeDict["name"]!)
            }
            else if elementName == "xsd:restriction" {
                if currentDataType != nil {
                    currentDataType!.base = attributeDict["base"]!
                }
            }
            else if elementName == "xsd:complexType" {
                if attributeDict["name"]! != "escapeType" && attributeDict["name"]!.contains(".") {
                    currentDataType = ComponentType(name: attributeDict["name"]!)
                }
            }
            else if elementName == "hl7:type" {
                if currentDataType is ComponentType {
                    currentElement = elementName
                }
            }
            else if elementName == "hl7:LongName" {
                if currentDataType != nil {
                    currentElement = elementName
                }
            }
        }
        else if loadCompositeTypesFlag {
            if elementName == "xsd:complexType" {
                if attributeDict["name"]! != "escapeType" && !attributeDict["name"]!.contains(".") {
                    currentDataType = CompositeType(name: attributeDict["name"]!)
                }
            }
            else if elementName == "xsd:element" {
                if currentDataType != nil {
                    if let currentDataType = currentDataType as? CompositeType {
                        if let ref = attributeDict["ref"], let type = dataTypes[ref] {
                            currentDataType.types.append(ComposedType(type: type, minOccurs: attributeDict["minOccurs"]!, maxOccurs: attributeDict["maxOccurs"]!))
                        }
                    }
                }
            }
        }
    }

    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if loadSegmentsFlag {
            if elementName == "xsd:complexType" {
                currentSequence = nil
            }
        }
        else if loadFieldsFlag {
            if elementName == "xsd:attributeGroup" {
                if let currentField = currentField {
                    if fields[currentField.segmentCode] == nil {
                        fields[currentField.segmentCode] = []
                    }
                
                    fields[currentField.segmentCode]?.append(currentField)
                }
                
                currentField = nil
            }
        }
        else if loadDataTypesFlag {
            if elementName == "xsd:simpleType" {
                if currentDataType != nil {
                    dataTypes[currentDataType!.name] = currentDataType!

                    currentDataType = nil
                    currentElement = nil
                    }
            }
            else if elementName == "xsd:complexType" {
                if currentDataType != nil {
                    dataTypes[currentDataType!.name] = currentDataType!

                    currentDataType = nil
                    currentElement = nil
                }
            }
        }
        else if loadCompositeTypesFlag {
            if elementName == "xsd:complexType" {
                if currentDataType != nil {
                    dataTypes[currentDataType!.name] = currentDataType!
                    
                    currentDataType = nil
                }
            }
        }
    }

    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        if let currentDataType = currentDataType as? ComponentType {
            if currentElement == "hl7:type" {
                currentDataType.type = string
                
            } else if currentElement == "hl7:LongName" {
                currentDataType.longName = string
            }
        }
    }

    public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("failure error: ", parseError)
    }
    
    public func parserDidEndDocument(_ parser: XMLParser) {
        // clean the lmess to avoid when parser delegate is reused
        if loadMessagesFlag == true {
            loadMessagesFlag = false
        }
        
        if loadSegmentsFlag == true {
            loadSegmentsFlag = false
        }
        
        if loadDataTypesFlag == true {
            loadDataTypesFlag = false
        }
        
        if loadCompositeTypesFlag == true {
            loadCompositeTypesFlag = false
        }
     
        currentElement = nil
        currentMessage = nil
    }
}
