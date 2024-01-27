//
//  FRChatroom.swift
//  GameGether
//
//  Created by James Ajhar on 8/4/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation
import DeepDiff
import FirebaseFirestore

class FRChatroom: DiffAware {

    // MARK: - Deep Diff
    typealias DiffId = String

    var diffId: String {
        return identifier
    }
    
    static func compareContent(_ a: FRChatroom, _ b: FRChatroom) -> Bool {
        return a.updatedAt == b.updatedAt
    }
    
    struct Constants {
        static let staleMicUsersCacheInterval: Int = 300 // 5 minutes
    }
    
    private(set) var identifier: String = ""
    private(set) var createdBy: String = ""
    private(set) var createdAt: Date = Date()
    private(set) var updatedAt: Date = Date()
    private(set) var userIds: [String] = [String]()
    private(set) var game: Game?
    private(set) var session: GameSession?

    var name: String?
    var imageURL: URL?
    private var users: [User]?

    var isGroupChat: Bool {
        return userIds.count > 2
    }
    
    convenience init(identifier: String) {
        self.init()
        self.identifier = identifier
    }
    
    convenience init(json: JSONDictionary) {
        self.init()
        
        identifier = json["id"] as? String ?? ""
        createdBy = json["createdBy"] as? String ?? ""
        userIds = json["userIds"] as? [String] ?? [String]()
        
        if let timestamp = json["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        }
        
        if let sessionJSON = json["session"] as? JSONDictionary {
            session = GameSessionObject(json: sessionJSON)
        } else if let sessionId = json["sessionId"] as? String {
            session = GameSessionObject(identifier: sessionId)
        }
        
        if let timestamp = json["updatedAt"] as? Timestamp {
            updatedAt = timestamp.dateValue()
        }
        
        if let urlString = json["imageURL"] as? String {
            imageURL = URL(string: urlString)
        }
        
        if let gameJSON = json["game"] as? JSONDictionary {
            game = GameObject.parseJSON(gameJSON)
        }
        
        if let chatroomName = json["name"] as? String {
            name = chatroomName
        }
    }
    
    func update(from chatroom: FRChatroom) {
        self.name = chatroom.name
        self.createdAt = chatroom.createdAt
        self.game = chatroom.game
        self.userIds = chatroom.userIds
        self.users = chatroom.users
        self.imageURL = chatroom.imageURL
    }
    
    func fetchUsers(breakCache: Bool = false, completion: (([User]?) -> Void)? = nil) {
        guard breakCache || users == nil || userIds.count != users?.count else {
            completion?(users)
            return
        }
        
        guard let signedInUser = DataCoordinator.shared.signedInUser else {
            completion?(nil)
            return
        }
        
        let usersToFetch = self.userIds.filter({ $0 != signedInUser.identifier })
        
        DataCoordinator.shared.getProfiles(forUsersWithIds: usersToFetch, allowCache: !breakCache) { [weak self] (users, error) in
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
