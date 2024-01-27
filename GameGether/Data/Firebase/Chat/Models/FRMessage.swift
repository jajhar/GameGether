//
//  FRMessage.swift
//  GameGether
//
//  Created by James Ajhar on 8/4/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation
import UIKit
import DeepDiff
import FirebaseFirestore

enum FRMessageType: String {
    case message
    case chatroomImageUpdated
    case chatroomNameUpdated
    case sentFriendRequest
    case cancelledFriendRequest
    case friendRequestAccepted
    case leftChatroom
    case addedToChatroom
    case micTurnedOn
    case micTurnedOff
    case createdParty
    case createdPartyNotification
    case sessionCreated
    case media
}

class FRMessage: DiffAware {
    
    // MARK: - Deep Diff
    typealias DiffId = String
    
    var diffId: String {
        return identifier
    }
    
    static func compareContent(_ a: FRMessage, _ b: FRMessage) -> Bool {
        return a.identifier == b.identifier
    }
    
    private(set) var identifier: String = ""
    private(set) var createdBy: String = ""
    private(set) var text: String = ""
    private(set) var gif: Gif?
    private(set) var createdAt: Date = Date()
    private(set) var fromUserName: String = ""
    private(set) var userImageURL: URL?
    private(set) var type: FRMessageType = .message
    private(set) var tags = [Tag]()
    private(set) var game: Game?
    private(set) var userIds = [String]()
    
    convenience init(json: JSONDictionary) {
        self.init()
        
        identifier = json["id"] as? String ?? ""
        createdBy = json["fromUserId"] as? String ?? json["createdBy"] as? String ?? ""
        text = json["text"] as? String ?? ""
        fromUserName = json["fromUserName"] as? String ?? ""

        if let urlString = json["userImageURL"] as? String {
            userImageURL = URL(string: urlString)
        }
        
        if let mediaJSON = json["media"] as? [String: Any] {
            gif = Gif(json: mediaJSON)
        }
        
        if let gameJSON = json["game"] as? JSONDictionary {
            game = GameObject.parseJSON(gameJSON)
        }
        
        if let tagsJSON = json["tags"] as? [JSONDictionary] {
            tags = tagsJSON.compactMap({ TagObject.parseJSON($0) })
        }
        
        if let users = json["users"] as? [String] {
            userIds = users
        }

        if let rawType = json["type"] as? String {
            type = FRMessageType(rawValue: rawType) ?? .message
        }
        
        if let timestamp = json["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        }
    }
}
