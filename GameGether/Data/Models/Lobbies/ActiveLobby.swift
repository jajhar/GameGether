//
//  ActiveLobby.swift
//  GameGether
//
//  Created by James Ajhar on 11/7/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import Foundation

protocol ActiveLobby {
    var game: Game? { get }
    var tags: [Tag] { get }
    var users: [User] { get }
    var isFavorited: Bool { get }
    var lastMessageUser: User? { get }
    var lastMessage: String? { get }
    var messageMediaURL: URL? { get }
}

struct ActiveLobbyObject: ActiveLobby {
    
    private(set) var game: Game?
    private(set) var tags = [Tag]()
    private(set) var users = [User]()
    private(set) var isFavorited: Bool = false
    private(set) var lastMessage: String?
    private(set) var messageMediaURL: URL?
    private(set) var lastMessageUser: User?
    
    var isGeneralLobby: Bool {
        return tags.isEmpty
    }
    
    static func parseJSON(_ json: JSONDictionary) -> ActiveLobby {
        
        var lobby = ActiveLobbyObject()
        
        lobby.isFavorited = json["favorited"] as? Bool ?? false
        
        if let gameJSON = json["game"] as? JSONDictionary {
            lobby.game = GameObject.parseJSON(gameJSON)
        }
        
        if let messageJSON = json["lastMessage"] as? JSONDictionary {
            lobby.lastMessage = messageJSON["text"] as? String
            
            if let userJSON = messageJSON["user"] as? JSONDictionary,
                let user = UserObject.parseJSON(json: userJSON) {
                lobby.lastMessageUser = user
            }
            
            if let media = messageJSON["media"] as? JSONDictionary, let urlString = media["mediaUrl"] as? String {
                lobby.messageMediaURL = URL(string: urlString)
            }
        }
        
        if let usersJSON = json["users"] as? [JSONDictionary] {
            lobby.users = usersJSON.compactMap({
                let user = UserObject.parseJSON(json: $0)
                guard lobby.lastMessageUser?.identifier != user?.identifier else {
                    // Don't show the last message user here.
                    return nil
                }
                return user
            })
        }
        
        if let tagsJSON = json["tags"] as? [JSONDictionary] {
            lobby.tags = tagsJSON.compactMap({ TagObject.parseJSON($0) })
        }
        
        return lobby
    }
}
