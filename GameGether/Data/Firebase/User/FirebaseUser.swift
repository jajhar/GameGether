//
//  FirebaseUser.swift
//  GameGether
//
//  Created by James Ajhar on 8/5/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase
import FirebaseFirestore

class FirebaseUser: FirebaseManager {
    
    internal let userStatusDatabase: DatabaseReference = Database.database(url: "https://gamegether-user-status.firebaseio.com/").reference()
    private let firestoreStatusRef: CollectionReference = Firestore.firestore().collection("status")
    
    private var persistentStatusRef: DatabaseReference?
    private var userStatusRef: ListenerRegistration?

    deinit {
        userStatusRef?.remove()
        persistentStatusRef?.removeAllObservers()
    }
    
    /// Call to observe the online status of a given set of users
    ///
    /// - Parameters:
    ///   - userId: The identifier of the user to observe
    ///   - onChange: Called when a given user's status has changed (isOnline)
    func observeUserStatus(forUser userId: String, onChange: @escaping (Bool, Date?) -> Void) {
        
        let ref = firestoreStatusRef.document(userId)
        
        userStatusRef = ref.addSnapshotListener { [weak self] (snapshot, error) in
          
            guard self != nil else {
                self?.userStatusRef?.remove()
                return
            }
            
            guard let userData = snapshot?.data() else {
                GGLog.error("Error fetching document: \(error?.localizedDescription ?? "unknown")")
                onChange(false, nil)
                return
            }
            
            var updatedAt: Date?
            if let timestamp = userData["lastChanged"] as? Timestamp {
                updatedAt = timestamp.dateValue()
            }
            
            onChange(userData["isOnline"] as? Bool ?? false, updatedAt)
        }
    }
    
    func updateOnlineStatus(forUser userId: String) {
        
        persistentStatusRef?.removeAllObservers()
        
        userStatusDatabase.child(userId).onDisconnectUpdateChildValues([
            "isOnline": false,
            "lastChanged": [".sv": "timestamp"]
            ], withCompletionBlock: { [weak self] (error, ref) in
                guard error == nil else {
                    GGLog.error(error?.localizedDescription ?? "unknown error")
                    return
                }
                
                self?.persistentStatusRef = ref
                ref.updateChildValues([
                    "isOnline": true,
                    "lastDevice": "iOS",
                    "lastChanged": [".sv": "timestamp"]
                ])
        })
    }
}
