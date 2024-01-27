//
//  TagObject.swift
//  GameGether
//
//  Created by James Ajhar on 9/13/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation

class TagObject: Tag {
    
    private(set) var identifier: String = ""
    private(set) var title: String = ""
    private(set) var type: TagType = .custom
    private(set) var priority: Int16 = 0
    private(set) var size: Int16 = 0
    private(set) var nestedTags: [Tag]?

    static func parseJSON(_ json: [String: Any]) -> TagObject {
        let object = TagObject()
        object.identifier = json["_id"] as? String ?? ""
        object.title = json["title"] as? String ?? ""
        object.priority = json["priority"] as? Int16 ?? 0
        
        if let metadata = json["metadata"] as? JSONDictionary {
            object.size = metadata["size"] as? Int16 ?? 0
        }
        
        if let tagsJSON = json["nestedTags"] as? [JSONDictionary], !tagsJSON.isEmpty {
            object.nestedTags = tagsJSON.compactMap({ TagObject.parseJSON($0) })
        }
        
        if let rawType = json["type"] as? String {
            
            switch rawType {
            case "TEAM_SIZE":
                object.type = .teamSize
            case "DEVICE":
                object.type = .device
            case "GAME_MODE":
                object.type = .gameMode
            case "LOCATION":
                object.type = .location
            case "COMMUNICATION":
                object.type = .communication
            case "PERSONALITY":
                object.type = .personality
            case "SPECTRUM":
                object.type = .spectrum
            case "CUSTOM":
                object.type = .custom
            default:
                break
            }
        }
        
        return object
    }
    
    convenience init(withIdentifier identifier: String, title: String, type: TagType, size: Int16 = 0) {
        self.init()
        self.identifier = identifier
        self.title = title
        self.type = type
        self.size = size
    }
    
    convenience init(fromTagMO tagMO: TagMO) {
        self.init()
        self.identifier = tagMO.identifier
        self.title = tagMO.title
        self.type = tagMO.type
        self.size = tagMO.size
        self.priority = tagMO.priority
        self.nestedTags = tagMO.nestedTags
    }
}

extension Tag {
    
    var jsonValue: JSONDictionary {
        var tagsDictionary = JSONDictionary()
        tagsDictionary["_id"] = identifier
        tagsDictionary["title"] = title
        tagsDictionary["priority"] = priority
        tagsDictionary["type"] = type.stringValue
        tagsDictionary["metadata"] = ["size": size]
        return tagsDictionary
    }
}
