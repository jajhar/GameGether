//
//  FirebaseChat+Voice.swift
//  GameGether
//
//  Created by James Ajhar on 8/7/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase

extension FirebaseChat {

    /// Call to set the microphone status of a particular user in a given chatroom
    ///
    /// - Parameters:
    ///   - isEnabled: true if the microphone for this user is currently enabled
    ///   - chatroom: The chatroom to set the microphone status on.
    public func setMicEnabledStatus(isEnabled: Bool, inChatroom chatroomId: String) {
        
        guard let signedInUser = DataCoordinator.shared.signedInUser else {
            GGLog.error("Failed to set mic status: User is not signed in.")
            return
        }
        
        let documentRef = chatroomsDatabase.document(chatroomId)
        
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
            
            var users: [String] = documentJSON["onVoiceUsers"] as? [String] ?? []
            
            if isEnabled {
                users.append(signedInUser.identifier)
            } else {
                users.removeAll(where: { $0 == signedInUser.identifier })
            }
            
            // Remove any duplicates (just to be safe)
            users = Array(Set(users))
            
            transaction.updateData(["onVoiceUsers": users], forDocument: documentRef)
            return nil
            
        }) { (object, error) in
            if let error = error {
                GGLog.error("Transaction failed: \(error)")
                return
            }
        }
    }
    
    /// Call to observe the mic status for all users in a given chatroom
    public func observeMicEnabledStatus(forChatroom chatroomId: String, onStatusChanged: @escaping ([String]) -> Void) {
        
        let ref = chatroomsDatabase.document(chatroomId)
        
        ref.addSnapshotListener { (snapshot, error) in
            guard error == nil,
                let documentJSON = snapshot?.data(),
                let onVoiceUsers = documentJSON["onVoiceUsers"] as? [String] else {
                GGLog.error(error?.localizedDescription ?? "unknown error")
                return
            }
            
            // Ignore the signed in user
            let filteredUsers = onVoiceUsers.filter({ $0 != DataCoordinator.shared.signedInUser?.identifier })
            onStatusChanged(filteredUsers)
        }
    }
    
    /// Call to set the microphone muted status of a particular user in a given chatroom
    ///
    /// - Parameters:
    ///   - isMuted: true if the microphone for this user is currently muted
    ///   - chatroom: The chatroom to set the microphone status on.
    public func setMicMutedStatus(isMuted: Bool, inChatroom chatroomId: String) {
        
        guard let signedInUser = DataCoordinator.shared.signedInUser else {
            GGLog.error("Failed to set mic status: User is not signed in.")
            return
        }
        
        let documentRef = chatroomsDatabase.document(chatroomId)
        
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
            
            var users: [String] = documentJSON["micMutedUsers"] as? [String] ?? []
            
            if isMuted {
                users.append(signedInUser.identifier)
            } else {
                users.removeAll(where: { $0 == signedInUser.identifier })
            }
            
            // Remove any duplicates (just to be safe)
            users = Array(Set(users))
            
            transaction.updateData(["micMutedUsers": users], forDocument: documentRef)
            return nil
            
        }) { (object, error) in
            if let error = error {
                GGLog.error("Transaction failed: \(error)")
                return
            }
        }
    }
    
    /// Call to observe the mic muted status for a given user
    ///
    /// - Parameters:
    ///   - userId: The identifier of the user to observe
    ///   - onStatusChanged: returns the muted status for this user
    public func observeMicMutedStatus(inChatroom chatroomId: String, onStatusChanged: @escaping ([String]) -> Void) {
        
       let ref = chatroomsDatabase.document(chatroomId)
        
        ref.addSnapshotListener { (snapshot, error) in
            guard error == nil else {
                GGLog.error(error?.localizedDescription ?? "unknown error")
                return
            }
            
            guard let documentJSON = snapshot?.data(),
                let mutedUsers = documentJSON["micMutedUsers"] as? [String] else {
                return
            }
            
            onStatusChanged(mutedUsers)
        }
    }
}
