//
//  FirebaseChat+Lobbies.swift
//  GameGether
//
//  Created by James Ajhar on 8/20/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase
import FirebaseFirestore

extension FirebaseChat {
    
    internal func tagsChatFirestoreMessagesCollection(forGame gameId: String,
                                                      withTags tags: [Tag]? = nil,
                                                      _ completion: @escaping (CollectionReference?) -> Void) {
        
        var tagsQuery: [String] = tags?.compactMap({ $0.identifier }) ?? [gameId]
        if tagsQuery.isEmpty { tagsQuery = [gameId] }
        
        let lobbyRef = Firestore.firestore().collection("lobbies/\(gameId)/tags")
        
        lobbyRef.whereField("tags", isEqualTo: tagsQuery)
            .getDocuments(completion: { (snapshot, error) in
                
                guard let documents = snapshot?.documents, let tagLobby = documents.first else {
                    let ref = lobbyRef.addDocument(data: ["tags": tagsQuery]).collection("messages")
                    completion(ref)
                    return
                }
                
                let ref = Firestore.firestore().collection("lobbies/\(gameId)/tags").document(tagLobby.documentID).collection("messages")
                completion(ref)
            })
    }
    
    internal func tagsChatFirestoreUsersCollection(forGame gameId: String,
                                                      withTags tags: [Tag]? = nil,
                                                      _ completion: @escaping (CollectionReference?) -> Void) {
        
        var tagsQuery: [String] = tags?.compactMap({ $0.identifier }) ?? [gameId]
        if tagsQuery.isEmpty { tagsQuery = [gameId] }
        
        let lobbyRef = Firestore.firestore().collection("lobbies/\(gameId)/tags")
        
        lobbyRef.whereField("tags", isEqualTo: tagsQuery)
            .getDocuments(completion: { (snapshot, error) in
                
                guard let documents = snapshot?.documents, let tagLobby = documents.first else {
                    let ref = lobbyRef.addDocument(data: ["tags": tagsQuery]).collection("users")
                    completion(ref)
                    return
                }
                
                let ref = Firestore.firestore().collection("lobbies/\(gameId)/tags").document(tagLobby.documentID).collection("users")
                completion(ref)
            })
    }


    /// Call to observe messages for a given game's chat channel
    ///
    /// - Parameters:
    ///   - game: The game to observe
    ///   - tags: Optional tags to observe (tag filtering). If none provided, will default to top level of game's chat channel.
    ///   - onChildAdded: Called when a new message is added.
    public func observeMessages(forGame game: Game, withTags tags: [Tag]? = nil, onUpdate: @escaping ([FRMessage]) -> Void) {
        
        trackedGame = game
        trackedTags = tags
        
        tagsChatFirestoreMessagesCollection(forGame: game.identifier, withTags: tags, { [weak self] (ref) in
            guard let weakSelf = self,
                let ref = ref, weakSelf.trackedGame?.identifier == game.identifier,
                weakSelf.trackedTags?.hashedValue == tags?.hashedValue else {
                    return
            }
            
            // Remove any pre-existing listeners
            weakSelf.tagChannelRef?.remove()
            
            weakSelf.tagChannelRef = ref
                .order(by: "createdAt", descending: true)
                .limit(to: 100)
                .addSnapshotListener { (snapshot, error) in
                    
                    guard let documents = snapshot?.documents else {
                        GGLog.error("Error fetching document: \(error?.localizedDescription ?? "unknown")")
                        onUpdate([])
                        return
                    }
                    
                    var messages = [FRMessage]()
                    
                    for document in documents {
                        var json = document.data()
                        json["id"] = document.documentID
                        
                        let message = FRMessage(json: json)
                        messages.append(message)
                    }
                    
                    onUpdate(messages.reversed())
            }
        })
    }
    
    /// Call to send a message or piece of media to a given game's chat channel
    ///
    /// - Parameters:
    ///   - messageType: The type of message being sent (text, media, actions, etc...)
    ///   - text: Optional text to send
    ///   - gif: Optional gif to send
    ///   - game: The game to send it to
    ///   - tags: Optional tags to send the message to. If none provided, will default to top level of game's chat channel.
    public func sendMessage(ofType messageType: FRMessageType = .message,
                            text: String? = nil,
                            gif: Gif? = nil,
                            toGame game: Game,
                            withTags tags: [Tag]? = nil,
                            metadata: JSONDictionary? = nil) {
        
        guard let signedInUser = DataCoordinator.shared.signedInUser else {
            GGLog.error("Failed to send message: User is not signed in.")
            return
        }
        
        var identifier = tags?.hashedValue ?? game.identifier
        identifier = identifier.isEmpty ? game.identifier : identifier
        
        var values: [String : Any] = [
            "fromUserId": signedInUser.identifier,
            "fromUserName": signedInUser.ign,
            "createdAt": FieldValue.serverTimestamp(),
            "type": messageType.rawValue,
            "userImageURL": signedInUser.profileImageURL?.absoluteString ?? "",
            "text": text ?? "",
        ]
        
        switch messageType {
        case .message:
            // Do nothing
            break
        case .media:
            if let gif = gif {
                values["media"] = gif.jsonValue
            }
        case .createdPartyNotification:
            values["users"] = metadata?["users"] ?? []
            
        case .chatroomImageUpdated,
             .chatroomNameUpdated,
             .sentFriendRequest,
             .cancelledFriendRequest,
             .friendRequestAccepted,
             .leftChatroom,
             .addedToChatroom,
             .micTurnedOn, .micTurnedOff,
             .sessionCreated,
             .createdParty:
            // Unsupported types for game chat. Stop here and don't create message
            GGLog.error("Failed to send message. Unsupported message type: \(messageType.rawValue)")
            return
        }
        
        tagsChatFirestoreMessagesCollection(forGame: game.identifier, withTags: tags, { (ref) in
            guard let ref = ref else { return }
            
            ref.addDocument(data: values) { (error) in
                if let error = error { GGLog.error(error.localizedDescription) }
            }
        })
    }

    /// Call to observe users that join/leave a lobby
    ///
    /// - Parameters:
    ///   - gameId: The game ID associated with the lobby
    ///   - tags: The tags that make up the lobby
    ///   - limit: The max number of users to fetch
    ///   - onUpdate: Returns active users and users that are inactive
    public func observeUsers(forGame gameId: String, withTags tags: [Tag]? = nil, limit: Int = 100, onUpdate: @escaping ([User], [User]) -> Void) {
        
        observeLobbyUsersRef?.remove()
        
        var identifier = tags?.hashedValue ?? gameId
        identifier = identifier.isEmpty ? gameId : identifier
        
        tagsChatFirestoreUsersCollection(forGame: gameId, withTags: tags) { [weak self] (ref) in
            guard let weakSelf = self else { return }
            
            weakSelf.observeLobbyUsersRef = ref?
                .order(by: "lastChanged")
                .limit(to: limit)
                .addSnapshotListener({ (snapshot, error) in

                guard let documents = snapshot?.documents else {
                    GGLog.error("Error fetching document: \(error?.localizedDescription ?? "unknown")")
                    onUpdate([], [])
                    return
                }
                
                var activeUsers = [User]()
                var inactiveUsers = [User]()
                
                for document in documents {
                    var userJSON = document.data()
                    userJSON["id"] = document.documentID
                    
                    guard let user = UserObject.parseJSON(json: userJSON) else { continue }
                                       
                    // Ignore the signed in user
                    guard !user.isSignedInUser, let isActive = userJSON["isActive"] as? Bool else { continue }

                    if !isActive {
                       
                       if let timestamp = userJSON["lastChanged"] as? Double {
                           let joinedAt = Date(timeIntervalSince1970: timestamp / 1000)
                           // 3 day stale cutoff for inactive users
                           guard let cutoffDate = Date().subtractDays(3), cutoffDate <= joinedAt else { continue }
                       }
                       
                       inactiveUsers.append(user)
                       
                    } else {
                       activeUsers.append(user)
                    }
                }
                    
                onUpdate(activeUsers, inactiveUsers)
            })
        }
    }
    
    public func joinLobby(forGame game: Game, withTags tags: [Tag]? = nil) {
        
        guard DataCoordinator.shared.isUserSignedIn(), let signedInUser = DataCoordinator.shared.signedInUser else {
            GGLog.error("Failed to join lobby: User is not signed in.")
            return
        }
        
        tagsChatFirestoreUsersCollection(forGame: game.identifier, withTags: tags) { (ref) in
            
            let values: JSONDictionary = [
                "lastChanged": FieldValue.serverTimestamp(),
                "isActive": true,
                "userId": signedInUser.identifier
            ]

            ref?.document(signedInUser.identifier).setData(values)
        }
    }
    
    public func leaveLobby(forGame game: Game, withTags tags: [Tag]? = nil) {
        
        guard DataCoordinator.shared.isUserSignedIn(), let signedInUser = DataCoordinator.shared.signedInUser else {
            GGLog.error("Failed to join lobby: User is not signed in.")
            return
        }
        
        tagsChatFirestoreUsersCollection(forGame: game.identifier, withTags: tags) { (ref) in
            
            let values: JSONDictionary = [
                "lastChanged": FieldValue.serverTimestamp(),
                "isActive": false,
                "userId": signedInUser.identifier
            ]

            ref?.document(signedInUser.identifier).setData(values)
        }
    }
}
