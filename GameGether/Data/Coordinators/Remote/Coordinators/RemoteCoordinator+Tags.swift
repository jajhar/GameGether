//
//  RemoteCoordinator+Tags.swift
//  GameGether
//
//  Created by James Ajhar on 9/13/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation

extension RemoteCoordinator {
    
    func getTags(forGame gameId: String, completion: @escaping (([Tag]?, Error?) -> Void)) {
        
        guard let request = APIRequest.getTags(gameId).request() else {
            completion(nil, RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
        
        send(request: request) { (data, response, error) in
            
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, RemoteError.apiError(message: "Response has no data", errorCode: 0))
                return
            }
            
            guard let json = self.jsonParse(data: data) as? JSONDictionary,
                let tagsJSON = json["tags"] as? [JSONDictionary] else {
                    completion(nil, RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                    return
            }
            
            var tags = [Tag]()
            for tagJSON in tagsJSON {
                let tag = TagObject.parseJSON(tagJSON)
                tags.append(tag)
            }
            
            completion(tags, nil)
        }
    }
    
    func followTags(tags: [Tag], forGame gameId: String, completion: @escaping (([TagsGroup]?, Error?) -> Void)) {
        
        guard var request = APIRequest.followTags.request() else {
            completion(nil, RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
        
        let tagIds = tags.compactMap({ $0.identifier })
        
        let body: JSONDictionary = [
            "tags": [
                "tags": tagIds,
                "gameId": gameId
            ]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        send(request: request) { (data, response, error) in
            
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, RemoteError.apiError(message: "Response has no data", errorCode: 0))
                return
            }
            
            guard let tagsJSON = self.jsonParse(data: data) as? [JSONDictionary] else {
                completion(nil, RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            var tags = [TagsGroup]()
            for tagJSON in tagsJSON {
                let tag = TagsGroupObject.parseJSON(tagJSON)
                tags.append(tag)
            }
            
            completion(tags, nil)
        }
    }
    
    func unfollowTags(withIdentifier identifier: String, completion: @escaping (([TagsGroup]?, Error?) -> Void)) {
        
        guard var request = APIRequest.unfollowTags.request() else {
            completion(nil, RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
        
        let body: JSONDictionary = [
            "followId": identifier
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        send(request: request) { (data, response, error) in
            
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, RemoteError.apiError(message: "Response has no data", errorCode: 0))
                return
            }
            
            guard let tagsJSON = self.jsonParse(data: data) as? [JSONDictionary] else {
                completion(nil, RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            var tags = [TagsGroup]()
            for tagJSON in tagsJSON {
                let tag = TagsGroupObject.parseJSON(tagJSON)
                tags.append(tag)
            }
            
            completion(tags, nil)
        }
    }
    
    func getFollowedTags(completion: @escaping (([TagsGroup]?, Error?) -> Void)) {
        
        guard let request = APIRequest.getFollowedTags.request() else {
            completion(nil, RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
                
        send(request: request) { (data, response, error) in
            
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, RemoteError.apiError(message: "Response has no data", errorCode: 0))
                return
            }
            
            guard let json = self.jsonParse(data: data) as? JSONDictionary,
                let tagsJSON = json["tags"] as? [JSONDictionary] else {
                completion(nil, RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            var tags = [TagsGroup]()
            for tagJSON in tagsJSON {
                let tag = TagsGroupObject.parseJSON(tagJSON)
                tags.append(tag)
            }
            
            completion(tags, nil)
        }
    }
        
    func getActiveTags(forGame gameId: String, completion: @escaping (([TagsGroup]?, Error?) -> Void)) {
        
        guard var request = APIRequest.activeTags(gameId).request() else {
            completion(nil, RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
        
        request.cachePolicy = .reloadRevalidatingCacheData
        
        send(request: request) { (data, response, error) in
            
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, RemoteError.apiError(message: "Response has no data", errorCode: 0))
                return
            }
            
            guard let tagsJSON = self.jsonParse(data: data) as? [JSONDictionary] else {
                completion(nil, RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            var tags = [TagsGroup]()
            for tagJSON in tagsJSON {
                let tag = TagsGroupObject.parseJSON(tagJSON)
                tags.append(tag)
            }
            
            completion(tags, nil)
        }
    }
    
    func getUsersFollowingTags(forGame gameId: String, withTags tags: [String], offset: String?, completion: @escaping (([User]?, String?, Error?) -> Void)) {
        
        let idString = tags.count > 0 ? tags.joined(separator: "&tags[]=") : ""
        guard let request = APIRequest.getUsersFollowingTags(gameId, idString, offset).request() else {
            completion(nil, nil, RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
        
        send(request: request) { (data, response, error) in
            
            guard error == nil else {
                completion(nil, nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, nil, RemoteError.apiError(message: "Response has no data", errorCode: 0))
                return
            }
            
            guard let json = self.jsonParse(data: data) as? JSONDictionary else {
                completion(nil, nil, RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            guard let profilesJSON = json["users"] as? [JSONDictionary] else {
                completion(nil, nil, RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            var profiles = [User]()
            for profileJSON in profilesJSON {
                guard let user = UserObject.parseJSON(json: profileJSON) else { continue }
                profiles.append(user)
            }
            completion(profiles, json["offset"] as? String, nil)
        }
    }
}
