//
//  UserRelationshipStatus.swift
//  GameGether
//
//  Created by James Ajhar on 9/4/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation
import CoreData

class UserRelationshipStatus: NSManagedObject {

    @NSManaged var creator: String
    @NSManaged var receiver: String
    @NSManaged var rawStatus: String
    
    // Inverse Relationship
    @NSManaged var user: UserMO?
    
    var status: FriendStatus {
        return FriendStatus(rawValue: rawStatus) ?? .none
    }

    func update(fromRelationship model: UserRelationship) {
        creator = model.creator ?? ""
        receiver = model.receiver ?? ""
        rawStatus = model.status.rawValue
    }
    
    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

}
