//
//  TagMO.swift
//  GameGether
//
//  Created by James Ajhar on 9/13/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation
import CoreData

class TagMO: NSManagedObject, Tag {
    
    @NSManaged var identifier: String
    @NSManaged var title: String
    @NSManaged var rawType: Int16
    @NSManaged var priority: Int16
    @NSManaged var size: Int16
    @NSManaged var gameId: String?
    @NSManaged var updatedAt: Date?
    @NSManaged var isFollowed: Bool

    // MARK: Relationships
    @NSManaged public var nestedTagsRelationship: Set<TagMO>?

    var nestedTags: [Tag]? {
        get {
            guard let relationships = nestedTagsRelationship else { return nil }
            
            var threadSafeObjects = [Tag]()
            for tagMO in relationships {
                threadSafeObjects.append(TagObject(fromTagMO: tagMO))
            }
            return threadSafeObjects
        }
        set {
            GGLog.warning("This object does not support setting of nestedTags variable")
        }
    }

    var type: TagType {
        return TagType(rawValue: Int(rawType)) ?? .custom
    }
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    /// Update Entity Properties from Tag protocol
    ///
    /// - Parameter model: The Tag model to update from
    func update(fromModel model: Tag) {
        identifier = model.identifier
        title = model.title
        rawType = Int16(model.type.rawValue)
        priority = model.priority
        size = model.size
        updatedAt = Date()
    }
}
