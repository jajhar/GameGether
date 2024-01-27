//
//  FirebaseParty.swift
//  GameGether
//
//  Created by James Ajhar on 10/25/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseDatabase
import FirebaseFirestore

enum FirebasePartyError: Error, Equatable, LocalizedError {
    
    case error(message: String?)
    
    var description: String {
        switch self {
        case .error(let message):
            if let message = message {
                return message
            } else {
                return "An unknown error occurred"
            }
        }
    }
    
    var errorDescription: String? {
        get {
            return self.description
        }
    }
}

class FirebaseParty: FirebaseManager {
        
    private var partyChannelRef: DatabaseQuery?
    private var partyChannelRefHandle: DatabaseHandle?
    
    deinit {
        if let handle = partyChannelRefHandle {
            partyChannelRef?.removeObserver(withHandle: handle)
        }
    }
    
    internal func tagsChatFirestorePartiesCollection(forGame gameId: String) -> CollectionReference {
        return Firestore.firestore().collection("lobbies/\(gameId)/parties")
    }

    
    func createParty(forGame game: Game, withSize partySize: PartySize, withTags tags: [Tag], completion: @escaping (FRParty?) -> Void) {
        guard let signedInUser = DataCoordinator.shared.signedInUser else {
            GGLog.error("Failed to create party: User is not signed in.")
            completion(nil)
            return
        }
        
        getParty(forGame: game, withTags: tags) { [weak self] (existingParty) in
            guard let weakSelf = self, existingParty == nil else {
                completion(existingParty)
                return
            }
            
            let ref = weakSelf.tagsChatFirestorePartiesCollection(forGame: game.identifier)
            
            let values: JSONDictionary = [
                "maxSize": partySize.size,
                "game": game.jsonValue,
                "createdBy": signedInUser.identifier,
                "createdAt": FieldValue.serverTimestamp(),
                "tags": tags.compactMap({ $0.jsonValue }),
                "tagIds": tags.compactMap({ $0.identifier }),
                "users": [signedInUser.identifier]
            ]
            
            ref.addDocument(data: values, completion: { (error) in
                guard error == nil else {
                    GGLog.error(error?.localizedDescription ?? "unknown error")
                    completion(nil)
                    return
                }
                
                // Fetch the newly created party
                weakSelf.getParty(forGame: game, withTags: tags, completion: { (createdParty) in
                    guard let createdParty = createdParty else {
                        GGLog.error("Failed to create party")
                        completion(nil)
                        return
                    }
                    
                    completion(createdParty)
                })
            })
        }
    }
    
    func getParty(forGame game: Game, withTags tags: [Tag], completion: @escaping (FRParty?) -> Void) {
        
        let ref = tagsChatFirestorePartiesCollection(forGame: game.identifier)
        
        var tagsQuery: [String] = tags.compactMap({ $0.identifier })
        if tagsQuery.isEmpty { tagsQuery = [game.identifier] }

        let cutoffDate = FRParty.Constants.cutoffDate

        ref.whereField("tagIds", isEqualTo: tagsQuery)
            .whereField("createdAt", isGreaterThan: cutoffDate)
            .getDocuments(completion: { (snapshot, error) in
                
                guard error == nil else {
                    GGLog.error(error?.localizedDescription ?? "unknown error")
                    return
                }
                
                guard let documents = snapshot?.documents, let existingParty = documents.first else {
                    completion(nil)
                    return
                }
                
                var json = existingParty.data()
                json["id"] = existingParty.documentID
                
                let party = FRParty(json: json)
                completion(party)
            })
    }
    
    func joinParty(_ party: FRParty, completion: @escaping (FRParty?, Error?) -> Void) {
        guard let identifier = party.identifier, let game = party.game else {
            completion(nil, FirebasePartyError.error(message: "No identifier found for party."))
            return
        }

        guard let signedInUser = DataCoordinator.shared.signedInUser else {
            GGLog.error("Failed to fetch unread count. User is not signed in.")
            completion(nil, FirebasePartyError.error(message: "User is not signed in"))
            return
        }
        
        let ref = tagsChatFirestorePartiesCollection(forGame: game.identifier)
        
        let documentRef = ref.document(identifier)
        
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
                        NSLocalizedDescriptionKey: "Failed to fetch party JSON"
                    ]
                )
                errorPointer?.pointee = error
                return nil
            }
            
            let currentParty = FRParty(json: json)
            var users: [String] = currentParty.userIds
            
            guard !users.contains(signedInUser.identifier) else {
                // User is already in this party
                let error = NSError(
                    domain: "AppErrorDomain",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "User is already in this party"
                    ]
                )
                errorPointer?.pointee = error
                return nil
            }
            
            guard users.count < party.maxSize else {
                // party is already full. Stop here.
                let error = NSError(
                    domain: "AppErrorDomain",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Party is full"
                    ]
                )
                errorPointer?.pointee = error
                return nil
            }
            
            // Add the user to this party
            users.append(signedInUser.identifier)
            
            transaction.updateData(["users": users], forDocument: documentRef)
            return nil
            
        }) { [weak self] (object, error) in
            if let error = error {
                GGLog.error("Transaction failed: \(error)")
                return
            }
            
            self?.getParty(forGame: game, withTags: party.tags) { (party) in
                completion(party, nil)
            }
        }
    }

    func leaveParty(_ party: FRParty, completion: @escaping (Error?) -> Void) {
        guard let identifier = party.identifier, let game = party.game else {
            completion(FirebasePartyError.error(message: "No identifier found for party."))
            return
        }
        
        guard let signedInUser = DataCoordinator.shared.signedInUser else {
            completion(FirebasePartyError.error(message: "User is not signed in"))
            return
        }
        
        let ref = tagsChatFirestorePartiesCollection(forGame: game.identifier)
        
        let documentRef = ref.document(identifier)
        
        var markForDeletion = false
        
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
                        NSLocalizedDescriptionKey: "Failed to fetch party JSON"
                    ]
                )
                errorPointer?.pointee = error
                return nil
            }
            
            let currentParty = FRParty(json: json)
            
            // Remove the signed in user
            let users = currentParty.userIds.filter({ $0 != signedInUser.identifier })
            
            guard users.count > 0 else {
                // If no users left in this party, delete it
                markForDeletion = true
                // Every document read in a transaction must also be written in that transaction.
                transaction.updateData([:], forDocument: documentRef)
                return nil
            }
            
            transaction.updateData(["users": users], forDocument: documentRef)
            return nil
            
        }) { (object, error) in
            if let error = error {
                GGLog.error("Transaction failed: \(error)")
                completion(error)
                return
            }
            
            if markForDeletion {
                documentRef.delete(completion: { (error) in
                    if let error = error { GGLog.error(error.localizedDescription) }
                })
            }
            
            completion(nil)
        }
    }
    
    func markPartyAsCreated(_ party: FRParty, completion: @escaping (Error?) -> Void) {
        guard let identifier = party.identifier, let game = party.game else {
            GGLog.error("No identifier found for party.")
            return
        }
        
        let ref = tagsChatFirestorePartiesCollection(forGame: game.identifier)
        ref.document(identifier).updateData((["chatroomCreated": true])) { (error) in
            completion(error)
        }
    }

    func deleteParty(_ party: FRParty) {
        guard let identifier = party.identifier, let game = party.game else {
            return
        }

        let ref = tagsChatFirestorePartiesCollection(forGame: game.identifier)
        ref.document(identifier).delete()
    }
    
    func observeParties(forGame gameId: String,
                        onUpdate: @escaping ([FRParty]?) -> Void) {
        
        GGLog.debug("Observing parties for game: \(gameId)")
       
        let ref = tagsChatFirestorePartiesCollection(forGame: gameId)

        let cutoffDate = FRParty.Constants.cutoffDate
        
        ref.whereField("createdAt", isGreaterThan: cutoffDate)
            .order(by: "createdAt", descending: false)
            .limit(to: 100)
            .addSnapshotListener { (snapshot, error) in
                
                guard let documents = snapshot?.documents else {
                    GGLog.error("\(#function) Error fetching document: \(error?.localizedDescription ?? "unknown")")
                    onUpdate([])
                    return
                }
                
                var parties = [FRParty]()
                for document in documents {

                    var json = document.data()
                    json["id"] = document.documentID
                    
                    let party = FRParty(json: json)
                    if !party.isStale {
                        parties.append(party)
                    }
                }
                
                onUpdate(parties)
        }
    }
}
