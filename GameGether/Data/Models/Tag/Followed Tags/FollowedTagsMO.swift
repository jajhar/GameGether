//
//  FollowedTagsMO.swift
//  GameGether
//
//  Created by James Ajhar on 9/17/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation
import CoreData

class FollowedTagsMO: NSManagedObject, TagsGroup {
    
    @NSManaged var identifier: String
    @NSManaged var gameId: String
    @NSManaged var updatedAt: Date?

    // MARK: Relationships
    @NSManaged public var tagsRelationship: Set<TagMO>?

    var tags: [Tag] {
        get {
            guard let relationships = tagsRelationship else { return [] }
            
            var threadSafeObjects = [TagObject]()
            for object in relationships {
                threadSafeObjects.append(TagObject(fromTagMO: object))
            }
            return threadSafeObjects
        }
        set {
            GGLog.warning("This object does not support setting of tags variable")
        }
    }
    
    // Not saved in cache
    private(set) var users: [User] = []
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    func update(fromModel model: TagsGroup) {
        identifier = model.identifier
        gameId = model.gameId
        users = model.users
        updatedAt = Date()
    }
}
