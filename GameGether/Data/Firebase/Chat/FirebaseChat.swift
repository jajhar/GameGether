//
//  FirebaseChat.swift
//  GameGether
//
//  Created by James Ajhar on 7/24/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase
import FirebaseFirestore

class FirebaseChat: FirebaseManager {
    
    let unreadMessagesDatabase = Firestore.firestore().collection("unreadMessages")
    let chatroomsDatabase = Firestore.firestore().collection("chatrooms")

    var tagChannelRef: ListenerRegistration?
    var privateRoomChannelRef: ListenerRegistration?
    var messageChannelRef: ListenerRegistration?
    var observeLobbyUsersRef: ListenerRegistration?

    struct Constants {
        static let ggGlobalChatIdentifier = "GG Global Chat"
    }

    internal var trackedGame: Game?
    internal var trackedTags: [Tag]?

    deinit {
        tagChannelRef?.remove()
        privateRoomChannelRef?.remove()
        messageChannelRef?.remove()
        observeLobbyUsersRef?.remove()
    }
    
    /// Call to send a message or piece of media to a given chatroom
    ///
    /// - Parameters:
    ///   - messageType: The type of message being sent (text, media, actions, etc...)
    ///   - text: Optional text to send
    ///   - gif: Optional gif to send
    ///   - chatroom: The chatroom to send it to
    ///   - tags: Optional tags to link to (used to travel to particular tags when tapped)
    public func sendMessage(ofType messageType: FRMessageType = .message,
                            text: String? = nil,
                            gif: Gif? = nil,
                            toChatroom chatroom: FRChatroom,
                            withGame game: Game? = nil,
                            withTags tags: [Tag]? = nil,
                            metadata: JSONDictionary? = nil) {
        
        guard let signedInUser = DataCoordinator.shared.signedInUser else {
            GGLog.error("Failed to send message: User is not signed in.")
            return
        }
        
        var values: [String : Any] = [
            "fromUserId": signedInUser.identifier,
            "fromUserName": signedInUser.ign,
            "createdAt": FieldValue.serverTimestamp(),
            "type": messageType.rawValue,
            "userImageURL": signedInUser.profileImageURL?.absoluteString ?? "",
            "text": text ?? "",
            "game": game?.jsonValue ?? ""
        ]
        
        switch messageType {
        case .message:
            AnalyticsManager.track(event: .messageSent, withParameters: ["chatroom": chatroom.identifier, "type": "text"])
            break
        case .media:
            if let gif = gif {
                values["media"] = gif.jsonValue
            }
            AnalyticsManager.track(event: .messageSent, withParameters: ["chatroom": chatroom.identifier, "type": "gif"])

        case .createdPartyNotification:
            values["users"] = metadata?["users"] ?? []
        default:
            break
        }
        
        if let tags = tags {
            // Convert the tags into a dictionary representation to be parsed later
            values["tags"] = tags.compactMap({ $0.jsonValue })
        }
        
        chatroomsDatabase.document(chatroom.identifier).collection("messages").addDocument(data: values)

        // Increment the unread count for this message for all users within the chatroom.
        incrementUnreadCount(forUsersInChatroom: chatroom)
                
        // Update the chatroom's timestamp
        updateTimestamp(forChatroom: chatroom)
    }
}
