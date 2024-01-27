//
//  DataCoordinator+Tags.swift
//  GameGether
//
//  Created by James Ajhar on 9/13/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation

extension DataCoordinator {
    
    func getTags(forGame gameId: String, completion: @escaping ([Tag]?, Error?) -> Void) {
        
        localCoordinator.getTags(forGame: gameId) { [unowned self] (cachedTags, error) in
            
            if error == nil, let tags = cachedTags, !tags.isEmpty {
                completion(tags, nil)
                return
            }
            
            // Nothing cached, fetch from remote
            self.remoteCoordinator.getTags(forGame: gameId) { (tags, error) in
                
                performOnMainThread {
                    guard error == nil, let tags = tags else {
                        completion(nil, error)
                        return
                    }
                    
                    completion(tags, error)
                    
                    self.localCoordinator.saveTags(tags: tags, completion: nil)
                }
            }
        }
    }
    
    func bookmarkTags(tags: [Tag], forGame gameId: String, completion: ((Error?) -> Void)? = nil) {
        localCoordinator.bookmarkTags(tags: tags, forGame: gameId) { (error) in
            guard error == nil else {
                completion?(error)
                return
            }
           
            completion?(nil)
        }
    }

    func getBookmarkedTags(forGame gameId: String, completion: @escaping (([Tag]?, Error?) -> Void)) {
        localCoordinator.getBookmarkedTags(forGame: gameId) { (tags, error) in
            completion(tags, error)
        }
    }
    
    func deleteBookmarkedTags(forGame gameId: String, completion: ((Error?) -> Void)? = nil) {
        localCoordinator.deleteAllBookmarks(forGameId: gameId, completion: completion)
    }
    
    func getFollowedTags(completion: @escaping (([TagsGroup]?, Error?) -> Void)) {
        
        // NOTE: DISABLING CACHED DATA FOR NOW. MAY RE-ENABLE LATER.
//        localCoordinator.getFollowedTags { [unowned self] (cachedObjects, error) in
//
//            if let objects = cachedObjects, objects.count > 0 {
//                completion(cachedObjects, nil)
//                return
//            }
        
            self.remoteCoordinator.getFollowedTags { (followedTags, error) in
                guard error == nil, let followedTags = followedTags else {
                    completion(nil, error)
                    return
                }
                
                completion(followedTags, error)

//                self.localCoordinator.saveFollowedTags(followedTags: followedTags, completion: { (savedObjects, error) in
//                    completion(savedObjects, error)
//                })
            }
//        }
    }
    
    func followTags(tags: [Tag], forGame gameId: String, completion: @escaping (([TagsGroup]?, Error?) -> Void)) {
        
        remoteCoordinator.followTags(tags: tags, forGame: gameId) { [unowned self] (followedTags, error) in
            guard error == nil, let followedTags = followedTags else {
                completion(nil, error)
                return
            }
            
            self.localCoordinator.saveFollowedTags(followedTags: followedTags, completion: { (savedObjects, error) in
                completion(savedObjects, error)
            })
        }
    }
    
    func unfollowTags(withIdentifier identifier: String, completion: @escaping (([TagsGroup]?, Error?) -> Void)) {

        remoteCoordinator.unfollowTags(withIdentifier: identifier) { [unowned self] (followedTags, error) in
            guard error == nil, let followedTags = followedTags else {
                completion(nil, error)
                return
            }
            
            self.localCoordinator.saveFollowedTags(followedTags: followedTags, completion: { (savedObjects, error) in
                completion(savedObjects, error)
            })
        }
    }
    
    func getActiveTags(forGame gameId: String, completion: @escaping (([TagsGroup]?, Error?) -> Void)) {
        remoteCoordinator.getActiveTags(forGame: gameId, completion: completion)
    }
}
