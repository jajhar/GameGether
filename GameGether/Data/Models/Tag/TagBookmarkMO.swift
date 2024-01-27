//
//  TagBookmarkMO.swift
//  GameGether
//
//  Created by James Ajhar on 9/16/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation
import CoreData

class TagBookmarkMO: NSManagedObject {
    
    @NSManaged var gameId: String
    @NSManaged var tagId: String
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
}
