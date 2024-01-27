//
//  FriendRequest.swift
//  GameGether
//
//  Created by James Ajhar on 8/31/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation

class UserRelationship {
    
    private(set) var creator: String?
    private(set) var receiver: String?
    private(set) var status: FriendStatus = .none
    
    var wasSentToMe: Bool {
        guard let signedInUser = DataCoordinator.shared.signedInUser else { return false }
        return creator != signedInUser.identifier
    }

    static func parseJSON(_ json: JSONDictionary) -> UserRelationship {
        let relationship = UserRelationship()
        relationship.creator = json["created_by_user_id"] as? String
        
        if let userIds = json["user_ids"] as? [String] {
            relationship.receiver = userIds.filter({ $0 != relationship.creator }).first
        }
        
        relationship.status = FriendStatus(rawValue: json["status"] as? String ?? "") ?? .none
        return relationship
    }
    
    convenience init(status: FriendStatus) {
        self.init()
        self.status = status
    }
    
    convenience init(fromRelationship relationship: UserRelationshipStatus) {
        self.init()
        self.creator = relationship.creator
        self.receiver = relationship.receiver
        self.status = relationship.status
    }
}
