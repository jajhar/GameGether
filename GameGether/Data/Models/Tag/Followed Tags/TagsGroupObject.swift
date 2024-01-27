//
//  TagsGroupObject.swift
//  GameGether
//
//  Created by James Ajhar on 9/17/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation

class TagsGroupObject: TagsGroup {
    
    private(set) var identifier: String = ""
    private(set) var gameId: String = ""
    private(set) var tags: [Tag] = []
    private(set) var users: [User] = []

    static func parseJSON(_ json: [String: Any]) -> TagsGroupObject {
        let object = TagsGroupObject()
        object.identifier = json["_id"] as? String ?? ""
        object.gameId = json["gameId"] as? String ?? ""

        if let tagsJSON = json["tags"] as? [JSONDictionary] {
            for tagJSON in tagsJSON {
                let tag = TagObject.parseJSON(tagJSON)
                object.tags.append(tag)
            }
            object.tags.sortByType()
        }
        
        if let usersJson = json["users"] as? [JSONDictionary] {
            for userJSON in usersJson {
                guard let user = UserObject.parseJSON(json: userJSON) else { continue }
                object.users.append(user)
            }
        }
        
        return object
    }
    
    convenience init(identifier: String, gameId: String) {
        self.init()
        self.identifier = identifier
        self.gameId = gameId
    }

    convenience init(fromFollowedTagsMO tagMO: FollowedTagsMO) {
        self.init()
        identifier = tagMO.identifier
        gameId = tagMO.gameId
        tags = tagMO.tags
        users = tagMO.users
        tags.sortByType()
    }
}
