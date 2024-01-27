//
//  FirebaseChat+Chatrooms.swift
//  GameGether
//
//  Created by James Ajhar on 8/9/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase
import FirebaseFirestore

extension FirebaseChat {
    
    /// Call to create a private chatroom between a group of users
    ///
    /// - Parameters:
    ///   - userIds: the array of user ids
    ///   - game: optional game if this chatroom was created from the party-up feature
    ///   - tags: optional tags associated if this chatroom was created from the party-up feature
    ///   - completion: Called when the chatroom was created
    public func createPrivateRoom(withUserIds userIds: [String],
                                  game: Game? = nil,
                                  tags: [Tag]? = nil,
                                  completion: ((FRChatroom?) -> Void)? = nil) {

        getChatroom(withUserIds: userIds, allowCache: false, completion: { [weak self] (existingChatroom) in
            guard let weakSelf = self else {
                completion?(nil)
                return
            }
            
            guard existingChatroom == nil else {
                // chatroom already exists. stop here...

                if let game = game,
                    let existingChatroom = existingChatroom,
                    existingChatroom.game?.identifier != game.identifier {
                    // update the associated game for this chatroom if necessary
                    weakSelf.updateGame(game, forChatroom: existingChatroom) { (_) in
                        // NOP - Fire and forget
                    }
                }
                
                completion?(existingChatroom)
                return
            }
            
            weakSelf.forceCreateChatroom(withUserIds: userIds, game: game, completion: completion)
        })
    }
    
    public func forceCreateChatroom(withUserIds userIds: [String],
                                    game: Game? = nil,
                                    completion: ((FRChatroom?) -> Void)? = nil) {
        
        guard DataCoordinator.shared.isUserSignedIn(), let signedInUser = DataCoordinator.shared.signedInUser else {
            GGLog.error("Failed to create private room: User is not signed in.")
            completion?(nil)
            return
        }
        
        let allUsers = userIds.contains(signedInUser.identifier) ? userIds : userIds + [signedInUser.identifier]
        
        var values: [String : Any] = [
            "createdBy": signedInUser.identifier,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
            "userIds": allUsers
        ]
        
        if let game = game {
            // Convert the game into a dictionary representation to be parsed later
            values["game"] = game.jsonValue
        }
        
        let chatroomRef = chatroomsDatabase.addDocument(data: values) { (error) in
            guard error == nil else {
                GGLog.error("Failed to create private room: \(error?.localizedDescription ?? "unknown error")")
                return
            }
        }
        
        values["id"] = chatroomRef.documentID
        
        let chatroom = FRChatroom(json: values)
        
        completion?(chatroom)

    }

    /// Call to fetch a particular chatroom containing an array of user ids
    ///
    /// - Parameters:
    ///   - userIds: The users that make up the chatroom
    ///   - completion: Returns the chatroom (if it exists)
    public func getChatroom(withUserIds userIds: [String], allowCache: Bool = true, completion: @escaping (FRChatroom?) -> Void) {
        
        guard DataCoordinator.shared.isUserSignedIn(), let signedInUser = DataCoordinator.shared.signedInUser else {
            GGLog.error("Failed to create private room: User is not signed in.")
            completion(nil)
            return
        }
        
        let allUsers = userIds.contains(signedInUser.identifier) ? userIds : userIds + [signedInUser.identifier]
        let userIdsToCompare = allUsers.sorted()
        
        fetchPrivateRooms(completion: { (existingChatrooms) in
            
            let existingChatroom = existingChatrooms.filter({ $0.userIds.sorted() == userIdsToCompare }).first
            
            completion(existingChatroom)
        })
    }
    
    /// Call to fetch a particular chatroom given a Game Session ID
    ///
    /// - Parameters:
    ///   - sessionId: The Game Session associated with this chatroom
    ///   - completion: Returns the chatroom (if it exists)
    public func getChatroom(forSessionId sessionId: String, completion: @escaping (FRChatroom?) -> Void) {
        
        guard DataCoordinator.shared.isUserSignedIn(), let _ = DataCoordinator.shared.signedInUser else {
            GGLog.error("Failed to create private room: User is not signed in.")
            completion(nil)
            return
        }
        
        chatroomsDatabase.whereField("sessionId", isEqualTo: sessionId)
            .getDocuments { (snapshot, error) in
                guard error == nil else {
                    GGLog.error(error?.localizedDescription ?? "unknown error")
                    completion(nil)
                    return
                }
                
                guard let json = snapshot?.documents.first?.data() else {
                    completion(nil)
                    return
                }
                
                let chatroom = FRChatroom(json: json)
                completion(chatroom)
        }
    }
    /// Call to observe changes that occur for a given chatroom (user added, user left, etc)
    ///
    /// - Parameters:
    ///   - chatroom: The chatroom to observe
    ///   - onDidChange: Called when the chatroom was updated in some way
    public func observeChatroom(_ chatroom: FRChatroom, onDidChange: @escaping (FRChatroom) -> Void) {
        
        let ref = chatroomsDatabase.document(chatroom.identifier)
        
        ref.addSnapshotListener { (snapshot, error) in
           
            guard let document = snapshot, var json = document.data() else {
                GGLog.error("Error fetching document: \(error?.localizedDescription ?? "unknown")")
                return
            }
            
            json["id"] = document.documentID
            let updatedChatroom = FRChatroom(json: json)
            chatroom.update(from: updatedChatroom)
            
            onDidChange(updatedChatroom)
        }
    }
    
    /// Call to one-time-fetch a given chatrom
    ///
    /// - Parameters:
    ///   - chatroomId: the identifier of the chatroom to fetch
    ///   - onFetch: Returns the chatroom if it exists
    public func fetchChatroom(_ chatroomId: String, onFetch: @escaping (FRChatroom?) -> Void) {
        
        let ref = chatroomsDatabase.document(chatroomId)
        
        ref.getDocument { (snapshot, error) in
            guard let document = snapshot, var json = document.data() else {
                GGLog.error("Error fetching document: \(error?.localizedDescription ?? "unknown")")
                onFetch(nil)
                return
            }
            
            json["id"] = document.documentID
            let chatroom = FRChatroom(json: json)
            onFetch(chatroom)
        }
    }
    
    /// Call to fetch all private chatrooms for the signed in user
    ///
    /// - Parameter completion: Returns an array of the user's private chatrooms
    public func fetchPrivateRooms(limit: UInt = 100, sessionsOnly: Bool = false, completion: @escaping ([FRChatroom]) -> Void) {
        
        guard DataCoordinator.shared.isUserSignedIn(), let signedInUser = DataCoordinator.shared.signedInUser else {
            GGLog.error("Failed to fetch private rooms: User is not signed in.")
            return
        }
        
        // Fetch all chatrooms that the signed in user belongs to.
        chatroomsDatabase
            .whereField("userIds", arrayContains: signedInUser.identifier)
            .whereField("updatedAt", isGreaterThan: Date.now.subtractDays(30) ?? Date.now)
            .order(by: "updatedAt", descending: true)
            .getDocuments { (snapshot, error) in
                guard error == nil else {
                    GGLog.error(error?.localizedDescription ?? "unknown error")
                    completion([])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                var chatrooms = [FRChatroom]()
                
                for document in documents {
                    var json = document.data()
                    json["id"] = document.documentID
                    
                    let chatroom = FRChatroom(json: json)
                    
                    if sessionsOnly {
                        guard chatroom.session != nil else { continue }
                    } else {
                        guard chatroom.session == nil else { continue }
                    }
                    
                    chatrooms.append(chatroom)
                }
                
                completion(chatrooms)
        }
    }
    
    /// Call to do a one-time fetch for the messages in a chatroom
    ///
    /// - Parameters:
    ///   - chatroomId: The identifier of the chatroom
    ///   - limit: The limit of messages to fetch
    ///   - completion: Returns an array of messages for the chatroom
    public func fetchMessages(forChatroom chatroomId: String, limit: UInt = 100, completion: @escaping ([FRMessage]) -> Void) {
        
        chatroomsDatabase.document(chatroomId)
            .collection("messages")
            .order(by: "createdAt", descending: true)
            .limit(to: Int(limit))
            .getDocuments { (snapshot, error) in
                
                guard let documents = snapshot?.documents else {
                    GGLog.error("Error fetching document: \(error?.localizedDescription ?? "unknown")")
                    completion([])
                    return
                }
                
                var messages = [FRMessage]()
                
                for document in documents {
                    var json = document.data()
                    json["id"] = document.documentID
                    
                    let message = FRMessage(json: json)
                    messages.append(message)
                }
                
                completion(messages)
        }
    }
    
    /// Call to observe messages for a given chatroom
    ///
    /// - Parameters:
    ///   - chatroomId: The identifier of the chatroom
    ///   - limit: The limit of messages to fetch (not sure if this is needed on .observe)
    ///   - onChildAdded: Called when a new message has been added to the chatroom
    public func observeMessages(forChatroom chatroomId: String, limit: UInt = 100, onUpdate: @escaping ([FRMessage]) -> Void) {
        
        messageChannelRef?.remove()
        
        messageChannelRef = chatroomsDatabase.document(chatroomId)
            .collection("messages")
            .order(by: "createdAt", descending: true)
            .limit(to: Int(limit))
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
    }
    
    /// Call to increment the unread messages count for all users in a given chtaroom
    ///
    /// - Parameter chatroom: The chatroom to update
    func incrementUnreadCount(forUsersInChatroom chatroom: FRChatroom) {
        
        guard DataCoordinator.shared.isUserSignedIn(), let signedInUser = DataCoordinator.shared.signedInUser else {
            GGLog.error("Failed to increment unread count")
            return
        }
        
        let usersToUpdate = chatroom.userIds.filter({ $0 != signedInUser.identifier})
        
        for userId in usersToUpdate {
            let ref = unreadMessagesDatabase.document(userId)
                .collection("chatrooms")
                .document(chatroom.identifier)
            
            ref.setData(["unreadCount": FieldValue.increment(Int64(1))], merge: true, completion: { (error) in
                if let error = error { GGLog.error("\(error.localizedDescription)") }
            })
        }
    }
    
    /// Call to reset the signed in user's unread message count for a single chatroom
    ///
    /// - Parameter chatroom: The chatroom to reset
    func resetMyUnreadCount(inChatroom chatroom: FRChatroom) {
        
        guard DataCoordinator.shared.isUserSignedIn(), let signedInUser = DataCoordinator.shared.signedInUser else {
            GGLog.error("Failed to create private room: User is not signed in.")
            return
        }
        
        let ref = unreadMessagesDatabase.document(signedInUser.identifier)
            .collection("chatrooms")
            .document(chatroom.identifier)
        
        ref.delete { (error) in
            if let error = error { GGLog.error(error.localizedDescription) }
        }
    }
    
    /// Call to update the last updated at timestamp on a given chatroom.
    /// This is typically called after sending a message so that we can sort when we fetch chatrooms
    ///
    /// - Parameter chatroom: The chatroom to update
    func updateTimestamp(forChatroom chatroom: FRChatroom) {
        let ref = chatroomsDatabase.document(chatroom.identifier)
        ref.updateData(["updatedAt": FieldValue.serverTimestamp()]) { (error) in
            if let error = error { GGLog.error(error.localizedDescription) }
        }
    }
    
    /// Call to observe the unread message counter for a given chatroom
    ///
    /// - Parameters:
    ///   - chatroom: The chatroom to observe
    ///   - onChange: Called when the unread count changes
    public func observeUnreadMessageCount(forChatroom chatroomId: String, onChange: @escaping (Int) -> Void) {
        
        guard DataCoordinator.shared.isUserSignedIn(), let signedInUser = DataCoordinator.shared.signedInUser else {
            GGLog.error("Failed to fetch unread count. User is not signed in.")
            return
        }
        
        let ref = unreadMessagesDatabase.document(signedInUser.identifier)
            .collection("chatrooms")
            .document(chatroomId)

        ref.addSnapshotListener { (snapshot, error) in
            
            guard let document = snapshot else {
                GGLog.error("Error fetching document: \(error?.localizedDescription ?? "unknown")")
                onChange(0)
                return
            }
            
            if let unreadCount = document.data()?["unreadCount"] as? Int {
                onChange(unreadCount)
            } else {
                onChange(0)
            }
        }
    }
    
    /// Call to observe the unread message counter for ALL chatrooms this user belongs to
    ///
    /// - Parameter completion: Returns a tuple of each chatrooms specific unread count AND the total unread count
    public func observeTotalChatroomUnreadMessageCount(sessionsOnly: Bool = false, completion: @escaping ([(FRChatroom, Int)], Int) -> Void) {
        
        guard DataCoordinator.shared.isUserSignedIn(), let signedInUser = DataCoordinator.shared.signedInUser else {
            GGLog.error("Failed to fetch unread count. User is not signed in.")
            return
        }
        
        let ref = unreadMessagesDatabase.document(signedInUser.identifier).collection("chatrooms")
        
        ref.addSnapshotListener { [weak self] (snapshot, error) in
            
            guard let weakSelf = self, let documents = snapshot?.documents else {
                GGLog.error("Error fetching document: \(error?.localizedDescription ?? "unknown")")
                completion([], 0)
                return
            }
            
            weakSelf.fetchPrivateRooms(sessionsOnly: sessionsOnly, completion: { (chatrooms) in
                var totalUnreadCount: Int = 0
                var chatroomsAndUnreadCount = [(FRChatroom, Int)]()
                
                for document in documents {

                    let unreadJSON = document.data()
                    let chatroomId = document.documentID
                    
                    for chatroom in chatrooms {
                        if chatroom.identifier == chatroomId {
                            totalUnreadCount += unreadJSON["unreadCount"] as? Int ?? 0
                            chatroomsAndUnreadCount.append((chatroom, unreadJSON["unreadCount"] as? Int ?? 0))
                            break
                        }
                    }
                }
                
                completion(chatroomsAndUnreadCount, totalUnreadCount)
            })
        }
    }
    
    /// Call to observe the total unread message count for ALL chatrooms this user belongs to
    ///
    /// - Parameter completion: Returns the total unread message count
    public func observeTotalUnreadMessageCount(completion: @escaping (Int) -> Void) {
        
        guard DataCoordinator.shared.isUserSignedIn(), let signedInUser = DataCoordinator.shared.signedInUser else {
            GGLog.error("Failed to fetch unread count. User is not signed in.")
            return
        }
        
        let ref = unreadMessagesDatabase.document(signedInUser.identifier).collection("chatrooms")
        
        ref.addSnapshotListener { (snapshot, error) in
            
            guard let documents = snapshot?.documents else {
                GGLog.error("Error fetching document: \(error?.localizedDescription ?? "unknown")")
                completion(0)
                return
            }
            
            var totalUnreadCount: Int = 0
            
            for document in documents {
                let unreadJSON = document.data()
                totalUnreadCount += unreadJSON["unreadCount"] as? Int ?? 0
            }
            
            completion(totalUnreadCount)
        }
    }
    
    /// Call to update a chatroom's image icon
    ///
    /// - Parameters:
    ///   - chatroom: The chatroom to update
    ///   - imageURL: The new image URL
    func updateChatroomImage(forChatroom chatroom: FRChatroom, imageURL: URL) {

        let documentRef = chatroomsDatabase.document(chatroom.identifier)
        
        Firestore.firestore().runTransaction({ (transaction, errorPointer) -> Any? in
            let document: DocumentSnapshot
            do {
                try document = transaction.getDocument(documentRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard document.data() != nil else {
                let error = NSError(
                    domain: "AppErrorDomain",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Failed to fetch chatroom JSON"
                    ]
                )
                errorPointer?.pointee = error
                return nil
            }
            
            transaction.updateData(["imageURL": imageURL.absoluteString], forDocument: documentRef)
            return nil
            
        }) { [weak self] (object, error) in
            if let error = error {
                GGLog.error("Transaction failed: \(error)")
                return
            }
            
            self?.sendMessage(ofType: .chatroomImageUpdated, toChatroom: chatroom)
        }
    }
    
    /// Call to update a chatroom's name
    ///
    /// - Parameters:
    ///   - chatroom: The chatroom to update
    ///   - newName: The new name of the chatroom
    func updateChatroomName(forChatroom chatroom: FRChatroom, newName: String) {
        
        let documentRef = chatroomsDatabase.document(chatroom.identifier)
        
        Firestore.firestore().runTransaction({ (transaction, errorPointer) -> Any? in
            let document: DocumentSnapshot
            do {
                try document = transaction.getDocument(documentRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard document.data() != nil else {
                let error = NSError(
                    domain: "AppErrorDomain",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Failed to fetch chatroom JSON"
                    ]
                )
                errorPointer?.pointee = error
                return nil
            }
            
            transaction.updateData(["name": newName], forDocument: documentRef)
            return nil
            
        }) { [weak self] (object, error) in
            if let error = error {
                GGLog.error("Transaction failed: \(error)")
                return
            }
            
            self?.sendMessage(ofType: .chatroomNameUpdated, toChatroom: chatroom)
        }
    }
    
    /// Call to update the associated game for a given chatroom
    ///
    /// - Parameters:
    ///   - game: The new game to associate to this chatroom
    ///   - chatroom: The chatroom to update
    ///   - completion: Returns an error if failed
    func updateGame(_ game: Game, forChatroom chatroom: FRChatroom, _ completion: @escaping (Error?) -> Void) {
        
        let documentRef = chatroomsDatabase.document(chatroom.identifier)
        
        Firestore.firestore().runTransaction({ (transaction, errorPointer) -> Any? in
            // Convert the game into a dictionary representation to be parsed later
            transaction.updateData(["game": game.jsonValue], forDocument: documentRef)
            return nil
            
        }) { (_, error) in
            if let error = error {
                GGLog.error("Transaction failed: \(error)")
                completion(error)
                return
            }
            
            completion(nil)
        }
    }
    
    /// Call to edit the list of users on a given chatroom
    /// - Parameter userIds: The users list that make up the chatroom
    /// - Parameter chatroom: The chatroom to update
    /// - Parameter completion: Returns an error if failed
    func setUsers(_ userIds: [String], forChatroom chatroom: FRChatroom, _ completion: @escaping (Error?) -> Void) {
        
        let documentRef = chatroomsDatabase.document(chatroom.identifier)
        
        Firestore.firestore().runTransaction({ (transaction, errorPointer) -> Any? in
            transaction.updateData(["userIds": userIds], forDocument: documentRef)
            return nil
            
        }) { (_, error) in
            if let error = error {
                GGLog.error("Transaction failed: \(error)")
                completion(error)
                return
            }
            
            completion(nil)
        }
    }
    
    /// Call to leave a chatroom permanently
    ///
    /// - Parameter chatroom: The chatroom to leave
    func leaveChatroom(_ chatroom: FRChatroom, completion: @escaping (Error?) -> Void) {
        
        guard DataCoordinator.shared.isUserSignedIn(), let signedInUser = DataCoordinator.shared.signedInUser else {
            GGLog.error("User is not signed in.")
            completion(nil)
            return
        }
        
        resetMyUnreadCount(inChatroom: chatroom)
        
        let documentRef = chatroomsDatabase.document(chatroom.identifier)
        
        if chatroom.session == nil {
            // Have to send message first or else permissions won't allow us to send this once the user has been removed
            sendMessage(ofType: FRMessageType.leftChatroom, text: "\(signedInUser.ign) left the group.", toChatroom: chatroom)
        }
        
        Firestore.firestore().runTransaction({ (transaction, errorPointer) -> Any? in
            let document: DocumentSnapshot
            do {
                try document = transaction.getDocument(documentRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let json = document.data() else {
                let error = NSError(
                    domain: "AppErrorDomain",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Failed to fetch chatroom JSON"
                    ]
                )
                errorPointer?.pointee = error
                return nil
            }
            
            let chatroom = FRChatroom(json: json)
            
            // Remove the signed in user
            let userIds = chatroom.userIds.filter({ $0 != signedInUser.identifier })
            
            transaction.updateData(["userIds": userIds], forDocument: documentRef)
            return nil
            
        }) { (object, error) in
            if let error = error {
                GGLog.error("Transaction failed: \(error)")
                completion(error)
                return
            }
            
            completion(nil)
        }
    }
    
    /// Call to notify the chatroom that the signed in user is actively typing
    ///
    /// - Parameters:
    ///   - isTyping: true if the signed in user is actively typing
    ///   - chatroom: The chatroom to update
    public func setTypingStatus(isTyping: Bool, inChatroom chatroom: FRChatroom) {
        
        guard DataCoordinator.shared.isUserSignedIn(), let signedInUser = DataCoordinator.shared.signedInUser else {
            GGLog.error("Failed to create private room: User is not signed in.")
            return
        }
        
        let documentRef = chatroomsDatabase.document(chatroom.identifier)
        
        Firestore.firestore().runTransaction({ (transaction, errorPointer) -> Any? in
            let document: DocumentSnapshot
            do {
                try document = transaction.getDocument(documentRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let documentJSON = document.data() else {
                let error = NSError(
                    domain: "AppErrorDomain",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Failed to fetch chatroom JSON"
                    ]
                )
                errorPointer?.pointee = error
                return nil
            }
            
            var users: [String] = documentJSON["typingUsers"] as? [String] ?? []
            
            if isTyping {
                users.append(signedInUser.identifier)
            } else {
                users.removeAll(where: { $0 == signedInUser.identifier })
            }
            
            // Remove any duplicates (just to be safe)
            users = Array(Set(users))
            
            transaction.updateData(["typingUsers": users], forDocument: documentRef)
            return nil
            
        }) { (_, error) in
            if let error = error {
                GGLog.error("Transaction failed: \(error)")
                return
            }
        }
    }
    
    /// Call to observe users that are actively typing in the chatroom
    ///
    /// - Parameters:
    ///   - chatroom: The chatroom to observe
    ///   - onUpdate: Called when the value changes
    public func observeTypingUsers(inChatroom chatroom: FRChatroom, onUpdate: @escaping ([String]) -> Void) {
    
        let ref = chatroomsDatabase.document(chatroom.identifier)
        
        ref.addSnapshotListener { (snapshot, error) in
            guard error == nil,
                let documentJSON = snapshot?.data(),
                let typingUsers = documentJSON["typingUsers"] as? [String] else {
                GGLog.error(error?.localizedDescription ?? "unknown error")
                return
            }
            
            // Ignore logged in user
            onUpdate(typingUsers.filter({ $0 != DataCoordinator.shared.signedInUser?.identifier }))
        }
    }
}
