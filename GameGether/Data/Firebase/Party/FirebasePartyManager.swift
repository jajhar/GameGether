//
//  FirebasePartyManager.swift
//  GameGether
//
//  Created by James Ajhar on 7/7/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class FirebasePartyManager {
    
    static let shared: FirebasePartyManager = {
        let manager = FirebasePartyManager()
        manager.firebaseChat.signIn()
        manager.firebaseParty.signIn()
        return manager
    }()
    
    private let firebaseParty = FirebaseParty()
    private let firebaseChat = FirebaseChat()
    
    private lazy var partyObservationTableView: PartyTableView = {
        let view = PartyTableView(frame: .zero)
        view.partyTableViewDelegate = self
        return view
    }()

    private(set) var isMovingToParty: Bool = false

    var activeParty: FRParty?
    
    func createParty(forGame game: Game, withSize size: PartySize, andTags tags: [Tag], completion: ((FRParty?) -> Void)? = nil) {
        
        firebaseParty.getParty(forGame: game, withTags: tags, completion: { [weak self] (existingParty) in
            
            guard let weakSelf = self else { return }
            
            if let existingParty = existingParty {
                // Join the existing party
                weakSelf.firebaseParty.joinParty(existingParty, completion: { (joinedParty, error) in
                    
                    guard let joinedParty = joinedParty else { return }
                    
                    performOnMainThread {
                        if let error = error {
                            GGLog.error("\(error)")
                            return
                        }
                        
                        if joinedParty.isFull {
                            // Party is full. Create a chat with these users.
                            // We need to make this request synchronous to block other users from creating the same chatroom after
                            //  the party is updated and marked as full. AKA the chatroom NEEDS to exist before party is updated so users don't
                            //  get thrown into nothingness.
                            weakSelf.createChatroom(forParty: joinedParty)
                           
                            // send a notification to the game lobby
                            let partySize = joinedParty.tags.sizeTags().first
                            weakSelf.firebaseChat.sendMessage(ofType: .createdPartyNotification,
                                                              text: "\(partySize?.title ?? "") party filled",
                                toGame: game,
                                withTags: tags,
                                metadata: ["users": joinedParty.userIds])
                            
                            completion?(joinedParty)
                            
                        } else {
                            // Party is not full. Show the party as it is now.
                            completion?(joinedParty)
                        }
                    }
                })
                
            } else {
                // Create the party
                weakSelf.firebaseParty.createParty(forGame: game, withSize: size, withTags: tags) { (party) in
                    performOnMainThread {
                        FirebasePartyManager.shared.activeParty = party
                        completion?(party)
                        AnalyticsManager.track(event: .createdParty,
                                               withParameters: ["size": party?.maxSize ?? 0, "game": party?.game?.identifier ?? ""])
                    }
                }
            }
        })
    }
    
    func createChatroom(forParty party: FRParty) {
        firebaseChat.createPrivateRoom(withUserIds: party.userIds, game: party.game, tags: party.tags, completion: { [weak self] (chatroom) in
            guard let weakSelf = self, let chatroom = chatroom else { return }
            
            weakSelf.firebaseChat.sendMessage(ofType: .createdParty, toChatroom: chatroom, withGame: party.game, withTags: party.tags)
            
            weakSelf.isMovingToParty = true
            
            // Mark it as created (finished state) so other users know they can join the created chatroom now.
            weakSelf.firebaseParty.markPartyAsCreated(party, completion: { (error) in
                if let error = error {
                    GGLog.error("Failed to mark party as created: \(error)")
                }
                
//                weakSelf.firebaseChat.sendNotifications(toChatroom: chatroom,
//                                                        ofType: .partyCreated,
//                                                        withTitle: "📣 \(party.game?.title ?? "") party filled!",
//                                                        withMessage: "tap here to join your party now")
                
                // Delete the party to cleanup
                weakSelf.firebaseParty.deleteParty(party)
                
                AnalyticsManager.track(event: .partyFilled, withParameters: ["size": party.maxSize, "game": party.game?.identifier ?? ""])
                
                performOnMainThread {
                    
                    // Automatically start voice chatting
                    AgoraManager.shared.joinChannel(withId: chatroom.identifier)
                    NavigationManager.shared.toggleActiveCallView(visible: true, forChatroom: chatroom)

                    let viewController = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: ChatViewController.storyboardIdentifier) as! ChatViewController
                    viewController.chatroom = chatroom
                    NavigationManager.shared.push(viewController)
                    
                    weakSelf.isMovingToParty = false
                }
            })
        })
    }
    
    public func observeParties(forGame game: Game, withTags tags: [Tag]) {
        partyObservationTableView.observeGame(game, withTags: tags)
    }
    
    public func joinParty(_ party: FRParty, completion: @escaping (FRParty?, Error?) -> Void) {
        
        AnalyticsManager.track(event: .joinedParty, withParameters: ["size": party.maxSize, "game": party.game?.identifier ?? ""])
        
        firebaseParty.joinParty(party) { [weak self] (updatedParty, error) in
            
            guard let weakSelf = self, let updatedParty = updatedParty else { return }
            
            performOnMainThread {
                if let error = error {
                    GGLog.error("\(error)")
                    completion(nil, error)
                    return
                }
                
                if updatedParty.isFull {
                    // Party is full. Create a chat with these users.
                    // We need to make this request synchronous to block other users from creating the same chatroom after
                    //  the party is updated and marked as full. AKA the chatroom NEEDS to exist before party is updated so users don't
                    //  get thrown into nothingness.
                    weakSelf.createChatroom(forParty: updatedParty)
                    
                    if let game = updatedParty.game {
                        // send a notification to the game lobby
                        let partySize = updatedParty.tags.sizeTags().first
                        weakSelf.firebaseChat.sendMessage(ofType: .createdPartyNotification,
                                                          text: "\(partySize?.title ?? "") party filled",
                            toGame: game,
                            withTags: updatedParty.tags.filter({ $0.size == 0 }), // ignore size tags
                            metadata: ["users": updatedParty.userIds])
                    }
                }
                
                completion(updatedParty, nil)
            }
        }
    }
}

extension FirebasePartyManager: PartyTableViewDelegate {
    
    func partyTableView(tableView: PartyTableView, canJoinParty party: FRParty) -> Bool {
        return activeParty == nil
    }
    
    func partyTableView(tableView: PartyTableView, didJoinParty party: FRParty) {
        activeParty = party
    }
    
    func partyTableView(tableView: PartyTableView, didLeaveParty party: FRParty) {
        activeParty = nil
    }
    
    func partyTableView(tableView: PartyTableView, partiesDidUpdate parties: [FRParty]) {
        
        for party in parties {
            
            if party.containsLoggedInUser, !isMovingToParty {
                // Redundancy is fun!
                activeParty = party
            }
            
            // Check to see if any of these parties contains the logged in user and has a chatroom associated with it.
            guard party.containsLoggedInUser,
                party.chatroomCreated,
                activeParty != nil,
                !isMovingToParty else {
                    continue
            }
            
            // A chatroom has been created from this party. Join it
            activeParty = nil
            isMovingToParty = true  // so we don't spam push view controllers
            
            // Go to the new chatroom created from this party
            firebaseChat.getChatroom(withUserIds: party.userIds, allowCache: false, completion: { [weak self] (chatroom) in
                self?.isMovingToParty = false
                
                performOnMainThread {
                    if let chatroom = chatroom {
                        self?.showPartyCreatedAlert(forChatroom: chatroom)
                    } else {
                        NavigationManager.topMostViewController()?.presentGenericErrorAlert()
                    }
                }
            })
        }
    }
    
    private func showPartyCreatedAlert(forChatroom chatroom: FRChatroom) {
        
        let alert = UIAlertController(title: "📣 \(chatroom.game?.title ?? "") party filled!",
                                    message: "A room has been created for your party. click below to join now!",
                                    preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Join now", style: .default, handler: { (_) in
            
            // Automatically start voice chatting
            AgoraManager.shared.joinChannel(withId: chatroom.identifier)
            NavigationManager.shared.toggleActiveCallView(visible: true, forChatroom: chatroom)

            let viewController = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: ChatViewController.storyboardIdentifier) as! ChatViewController
            viewController.chatroom = chatroom
            NavigationManager.shared.push(viewController)
        }))
        
        NavigationManager.shared.present(alert)
    }
}
