//
//  FRParty.swift
//  GameGether
//
//  Created by James Ajhar on 10/25/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation
import FirebaseFirestore

struct PartySize {
    var size: UInt
    var title: String
}

class FRParty {
    
    struct Constants {
        static let stalePartiesDateInterval: Int = 3600
        static let cutoffDate: Date = Date().subtractSeconds(Constants.stalePartiesDateInterval) ?? Date()
    }
    
    private(set) var game: Game?
    private(set) var maxSize: Int = 0
    private(set) var createdBy: String?
    private(set) var createdAt: Date = Date()
    private(set) var tags = [Tag]()
    private(set) var userIds = [String]()
    private(set) var users: [User]?
    private(set) var identifier: String?
    private(set) var chatroomCreated: Bool = false

    var containsLoggedInUser: Bool {
        guard let signedInUser = DataCoordinator.shared.signedInUser else { return false }
        return userIds.contains(signedInUser.identifier)
    }
    
    var isCreatedByLoggedInUser: Bool {
        guard let signedInUser = DataCoordinator.shared.signedInUser, let createdBy = createdBy else { return false }
        return createdBy == signedInUser.identifier
    }
    
    var isFull: Bool {
        return userIds.count >= maxSize
    }
    
    var isStale: Bool {
        return Constants.cutoffDate > createdAt
    }
    
    convenience init(json: JSONDictionary) {
        self.init()
        
        maxSize = json["maxSize"] as? Int ?? 0
        createdBy = json["createdBy"] as? String
        identifier = json["id"] as? String
        userIds = json["users"] as? [String] ?? []
        chatroomCreated = json["chatroomCreated"] as? Bool ?? false
        
        if let timestamp = json["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        }
        
        if let gameJSON = json["game"] as? JSONDictionary {
            game = GameObject.parseJSON(gameJSON)
        }
        
        if let tagsJSON = json["tags"] as? [JSONDictionary] {
            tags = tagsJSON.compactMap({ TagObject.parseJSON($0) })
        }
    }
    
    func setUsers(userIds: [String]) {
        self.userIds = userIds
    }
    
    func fetchUsers(breakCache: Bool = false, completion: (([User]?) -> Void)? = nil) {
        guard breakCache || users == nil, userIds.count > 0, userIds.count != users?.count else {
            completion?(users)
            return
        }
        
        DataCoordinator.shared.getProfiles(forUsersWithIds: userIds, allowCache: breakCache) { [weak self] (users, error) in
            guard error == nil else {
                GGLog.error("\(String(describing: error))")
                completion?(self?.users)
                return
            }
            self?.users = users
            completion?(users)
        }
    }
}

extension Array where Iterator.Element == FRParty {
    
    func containsTags(_ tags: [Tag]) -> Bool {
        return filter({ tags.isEqual(to: $0.tags )}).first != nil
    }
}
