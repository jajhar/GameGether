//
//  RemoteCoordinator+User.swift
//  GameGether
//
//  Created by James Ajhar on 8/23/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation
import KeychainSwift

extension RemoteCoordinator {
    
    func loginUser(withEmail email: String, andPassword password: String, completion: @escaping ((User?, Error?) -> Void)) {
        
        guard var request = APIRequest.login.request() else {
            completion(nil, RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
        
        //setup request
        let requestBody: JSONDictionary = ["email": email,
                                           "password": password]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        send(request: request) { (data, response, error) in
            
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, RemoteError.apiError(message: "Response has no data", errorCode: 0))
                return
            }
            
            guard let json = self.jsonParse(data: data) as? JSONDictionary else {
                completion(nil, RemoteError.apiError(message: "Failed to parse JSON", errorCode: response?.statusCode))
                return
            }
            
            guard let userJSON = json["user"] as? JSONDictionary,
                let token = json["token"] as? String else
            {
                if let errorMessage = json["error"] as? String {
                    completion(nil, RemoteError.apiError(message: errorMessage, errorCode: response?.statusCode))
                } else {
                    completion(nil, RemoteError.apiError(message: "Failed to parse JSON", errorCode: response?.statusCode))
                }
                
                return
            }
            
            // Store the Auth token
            let keychain = KeychainSwift()
            keychain.set(token, forKey: AppConstants.Keychain.remoteTokenKey)
            
            let user = UserObject.parseJSON(json: userJSON)
            completion(user, nil)
        }
    }
    
    /// Call to fetch a new auth token from the firebase server
    ///
    /// - Parameter completion: returns the new token or an error
    func renewFirebaseToken(completion: @escaping ((String?, Error?) -> Void)) {
        
        guard let request = APIRequest.loginToFirebase.request() else {
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
            
            guard let json = self.jsonParse(data: data) as? JSONDictionary else {
                completion(nil, RemoteError.apiError(message: "Failed to parse JSON", errorCode: response?.statusCode))
                return
            }
            
            guard let token = json["token"] as? String else {
                if let errorMessage = json["error"] as? String {
                    completion(nil, RemoteError.apiError(message: errorMessage, errorCode: response?.statusCode))
                } else {
                    completion(nil, RemoteError.apiError(message: "Failed to parse JSON", errorCode: response?.statusCode))
                }
                
                return
            }
            
            // Store the auth token
            let keychain = KeychainSwift()
            keychain.set(token, forKey: AppConstants.Keychain.firebaseAuthTokenKey)
            
            completion(token, nil)
        }
    }
    
    func loginUser(withFacebookToken token: String, completion: @escaping ((User?, Error?) -> Void)) {
        
        guard var request = APIRequest.loginWithFacebook.request() else {
            completion(nil, RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
        
        //setup request
        let requestBody: JSONDictionary = ["token": token]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        send(request: request) { (data, response, error) in
            
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, RemoteError.apiError(message: "Response has no data", errorCode: 0))
                return
            }
            
            guard let json = self.jsonParse(data: data) as? JSONDictionary else {
                completion(nil, RemoteError.apiError(message: "Failed to parse JSON", errorCode: response?.statusCode))
                return
            }
            
            guard let userJSON = json["user"] as? JSONDictionary,
                let token = json["token"] as? String else
            {
                if let errorMessage = json["error"] as? String {
                    completion(nil, RemoteError.apiError(message: errorMessage, errorCode: response?.statusCode))
                } else {
                    completion(nil, RemoteError.apiError(message: "Failed to parse JSON", errorCode: response?.statusCode))
                }
                
                return
            }
            
            // Store the Auth token
            let keychain = KeychainSwift()
            keychain.set(token, forKey: AppConstants.Keychain.remoteTokenKey)
            
            let user = UserObject.parseJSON(json: userJSON)
            completion(user, nil)
        }
    }
    
    func loginUser(withGoogleToken token: String, completion: @escaping ((User?, Error?) -> Void)) {
        
        guard var request = APIRequest.loginWithGoogle.request() else {
            completion(nil, RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
        
        //setup request
        let requestBody: JSONDictionary = ["token": token]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        send(request: request) { (data, response, error) in
            
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, RemoteError.apiError(message: "Response has no data", errorCode: 0))
                return
            }
            
            guard let json = self.jsonParse(data: data) as? JSONDictionary else {
                completion(nil, RemoteError.apiError(message: "Failed to parse JSON", errorCode: response?.statusCode))
                return
            }
            
            guard let userJSON = json["user"] as? JSONDictionary,
                let token = json["token"] as? String else
            {
                if let errorMessage = json["error"] as? String {
                    completion(nil, RemoteError.apiError(message: errorMessage, errorCode: response?.statusCode))
                } else {
                    completion(nil, RemoteError.apiError(message: "Failed to parse JSON", errorCode: response?.statusCode))
                }
                
                return
            }
            
            // Store the Auth token
            let keychain = KeychainSwift()
            keychain.set(token, forKey: AppConstants.Keychain.remoteTokenKey)
            
            let user = UserObject.parseJSON(json: userJSON)
            completion(user, nil)
        }
    }
    
    func loginUser(withAppleUserId userId: String, completion: @escaping ((User?, Error?) -> Void)) {
        
        guard var request = APIRequest.loginWithApple.request() else {
            completion(nil, RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
        
        //setup request
        let requestBody: JSONDictionary = ["appleUserId": userId]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        send(request: request) { (data, response, error) in
            
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, RemoteError.apiError(message: "Response has no data", errorCode: 0))
                return
            }
            
            guard let json = self.jsonParse(data: data) as? JSONDictionary else {
                completion(nil, RemoteError.apiError(message: "Failed to parse JSON", errorCode: response?.statusCode))
                return
            }
            
            guard let userJSON = json["user"] as? JSONDictionary,
                let token = json["token"] as? String else
            {
                if let errorMessage = json["error"] as? String {
                    completion(nil, RemoteError.apiError(message: errorMessage, errorCode: response?.statusCode))
                } else {
                    completion(nil, RemoteError.apiError(message: "Failed to parse JSON", errorCode: response?.statusCode))
                }
                
                return
            }
            
            // Store the Auth token
            let keychain = KeychainSwift()
            keychain.set(token, forKey: AppConstants.Keychain.remoteTokenKey)
            
            let user = UserObject.parseJSON(json: userJSON)
            completion(user, nil)
        }
    }

    
    func register(user: User, andPassword password: String?, completion: @escaping ((User?, Error?) -> Void)) {
        
        guard var request = APIRequest.register.request() else {
            completion(nil, RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
        
        // setup request
        var requestBody: JSONDictionary = [
            "email": user.email,
            "ign": user.ign
        ]
        
        if let appleUserId = KeychainSwift().get(AppConstants.Keychain.appleUserIdentifier) {
            requestBody["appleUserId"] = appleUserId
        }
        
        if let url = user.profileImageURL {
            requestBody["profileImageURL"] = url.absoluteString
        }
        
        if let url = user.profileImageColoredBackgroundURL {
            requestBody["profileImageColoredBackgroundURL"] = url.absoluteString
        }
        
        if let password = password {
            // A password is not always necessary. For example: Social registrations through Facebook or Google
            requestBody["password"] = password
        }
        
        if let birthday = user.birthday?.iso8601Format() {
            requestBody["birthday"] = birthday
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        send(request: request) { (data, response, error) in
            
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, RemoteError.apiError(message: "Response has no data", errorCode: response?.statusCode))
                return
            }
            
            guard let json = self.jsonParse(data: data) as? JSONDictionary else {
                completion(nil, RemoteError.apiError(message: "Failed to parse JSON", errorCode: response?.statusCode))
                return
            }
            
            guard let userJSON = json["user"] as? JSONDictionary,
                let token = json["token"] as? String else
            {
                if let errorMessage = json["error"] as? String {
                    completion(nil, RemoteError.apiError(message: errorMessage, errorCode: response?.statusCode))
                } else {
                    completion(nil, RemoteError.apiError(message: "Failed to parse JSON", errorCode: response?.statusCode))
                }
                
                return
            }
            
            // Store the Auth token
            let keychain = KeychainSwift()
            keychain.set(token, forKey: AppConstants.Keychain.remoteTokenKey)
            
            let user = UserObject.parseJSON(json: userJSON)
            completion(user, nil)
        }
        
    }
    
    func checkEmailAvailability(email: String, completion: @escaping (Bool, Error?) -> Void) {
        
        guard let request = APIRequest.checkEmail(email).request() else {
            completion(false, RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
        
        send(request: request) { (data, response, error) in
            
            guard error == nil else {
                completion(false, error)
                return
            }
            
            guard let data = data else {
                completion(false, RemoteError.apiError(message: "Response has no data", errorCode: 0))
                return
            }
            
            guard let json = self.jsonParse(data: data) as? JSONDictionary,
                let isAvailable = json["available"] as? Bool else
            {
                completion(false, RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            completion(isAvailable, nil)
        }
    }

    func checkIGNAvailability(ign: String, completion: @escaping ((Int, Error?) -> Void)) {
        
        guard let request = APIRequest.checkIGN(ign).request() else {
            completion(-1, RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
        
        send(request: request) { (data, response, error) in
            
            guard error == nil else {
                completion(-1, error)
                return
            }
            
            guard let data = data else {
                completion(-1, RemoteError.apiError(message: "Response has no data", errorCode: 0))
                return
            }
            
            guard let json = self.jsonParse(data: data) as? JSONDictionary,
                let count = json["count"] as? Int else
            {
                completion(-1, RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            completion(count, nil)
        }
    }
    
    func sendForgotPasswordEmail(toEmail email: String, completion: @escaping ((Error?) -> Void)) {
        
        guard var request = APIRequest.forgotPassword.request() else {
            completion(RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["email": email], options: [])
        
        send(request: request) { (data, response, error) in
            
            guard error == nil else {
                completion(error)
                return
            }
            
            guard let data = data else {
                completion(RemoteError.apiError(message: "Response has no data", errorCode: 0))
                return
            }
            
            guard let json = self.jsonParse(data: data) as? JSONDictionary else {
                completion(RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            if let errorMessage = json["error"] as? String {
                completion(RemoteError.apiError(message: errorMessage, errorCode: response?.statusCode))
            } else {
                completion(nil)
            }
        }
    }
    
    func resetPassword(newPassword password: String, completion: @escaping ((Error?) -> Void)) {
        
        guard var request = APIRequest.resetPassword.request() else {
            completion(RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["password": password], options: [])
        
        send(request: request) { (data, response, error) in
            
            guard error == nil else {
                completion(error)
                return
            }
            
            guard let data = data else {
                completion(RemoteError.apiError(message: "Response has no data", errorCode: 0))
                return
            }
            
            guard let json = self.jsonParse(data: data) as? JSONDictionary else {
                completion(RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            if let errorMessage = json["error"] as? String {
                completion(RemoteError.apiError(message: errorMessage, errorCode: response?.statusCode))
            } else {
                completion(nil)
            }
        }
    }
    
    func updateProfileBackgroundImage(withImageURL imageURL: String, completion: @escaping ((Error?) -> Void)) {
        guard var request = APIRequest.updateProfile.request() else {
            completion(RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["profileBackgroundImageURL": imageURL], options: [])
        
        send(request: request) { (data, response, error) in
            
            guard error == nil else {
                completion(error)
                return
            }
            
            guard let data = data else {
                completion(RemoteError.apiError(message: "Response has no data", errorCode: 0))
                return
            }
            
            guard let json = self.jsonParse(data: data) as? JSONDictionary else {
                completion(RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            if let errorMessage = json["error"] as? String {
                completion(RemoteError.apiError(message: errorMessage, errorCode: response?.statusCode))
            } else {
                completion(nil)
            }
        }
    }
    
    func updateProfileImage(withImageURL imageURL: String, completion: @escaping ((Error?) -> Void)) {
        guard var request = APIRequest.updateProfile.request() else {
            completion(RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["profileImageURL": imageURL], options: [])
        
        send(request: request) { (data, response, error) in
            
            guard error == nil else {
                completion(error)
                return
            }
            
            guard let data = data else {
                completion(RemoteError.apiError(message: "Response has no data", errorCode: 0))
                return
            }
            
            guard let json = self.jsonParse(data: data) as? JSONDictionary else {
                completion(RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            if let errorMessage = json["error"] as? String {
                completion(RemoteError.apiError(message: errorMessage, errorCode: response?.statusCode))
            } else {
                completion(nil)
            }
        }
    }
    
    func addFriend(withUserId userId: String, completion: @escaping ((Error?) -> Void)) {
        guard var request = APIRequest.addFriend(userId).request() else {
            completion(RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
             
        let requestBody = [
            "type": 1 // 1 = Friend Request
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])

        send(request: request) { (data, response, error) in
            
            guard error == nil else {
                completion(error)
                return
            }
            
            guard let data = data else {
                completion(RemoteError.apiError(message: "Response has no data", errorCode: 0))
                return
            }
            
            guard let json = self.jsonParse(data: data) as? JSONDictionary else {
                completion(RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            if let errorMessage = json["error"] as? String {
                completion(RemoteError.apiError(message: errorMessage, errorCode: response?.statusCode))
            } else {
                completion(nil)
            }
        }
    }
    
    func acceptFriendRequest(fromUser userId: String, completion: @escaping ((Error?) -> Void)) {
        guard var request = APIRequest.acceptFriendRequest(userId).request() else {
            completion(RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
                
        let requestBody = [
            "status": "ACCEPTED"
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])

        send(request: request) { (data, response, error) in
            
            guard error == nil else {
                completion(error)
                return
            }
            
            guard let data = data else {
                completion(RemoteError.apiError(message: "Response has no data", errorCode: 0))
                return
            }
            
            guard let json = self.jsonParse(data: data) as? JSONDictionary else {
                completion(RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            if let errors = json["errors"] as? [JSONDictionary], let error = errors.first, let errorMessage = error["msg"] as? String {
                completion(RemoteError.apiError(message: errorMessage, errorCode: response?.statusCode))
            } else {
                completion(nil)
            }
        }
    }
    
    func cancelFriendRequest(toUser userId: String, completion: @escaping ((Error?) -> Void)) {
        guard let request = APIRequest.cancelFriendRequest(userId).request() else {
            completion(RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
                
        send(request: request) { (data, response, error) in
            
            guard error == nil else {
                completion(error)
                return
            }
            
            guard let data = data else {
                completion(RemoteError.apiError(message: "Response has no data", errorCode: 0))
                return
            }
            
            if response?.statusCode == 204 {
                // Successful delete
                completion(nil)
                return
            }
            
            guard let json = self.jsonParse(data: data) as? JSONDictionary else {
                completion(RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            if let errorMessage = json["error"] as? String {
                completion(RemoteError.apiError(message: errorMessage, errorCode: response?.statusCode))
            } else {
                completion(nil)
            }
        }
    }
    
    func getFriendStatus(forUser userId: String, completion: @escaping ((UserRelationship?, Error?) -> Void)) {
        guard let request = APIRequest.getFriendStatus(userId).request() else {
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
                let relationshipsJSON = json["relationships"] as? [JSONDictionary] else {
                completion(nil, RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
                       
            guard let relationshipJSON = relationshipsJSON.first else {
                // No relationship between these two users
                let relationship = UserRelationship()
                completion(relationship, nil)
                return
            }
            
            let relationship = UserRelationship.parseJSON(relationshipJSON)
            completion(relationship, nil)
        }
    }
    
    func getFriends(completion: @escaping (([User]?, Error?) -> Void)) {
        
        guard let request = APIRequest.getFriends.request() else {
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
            
            guard let json = self.jsonParse(data: data) as? JSONDictionary else {
                completion(nil, RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            guard let relationships = json["relationships"] as? [JSONDictionary] else {
                completion(nil, RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            var friends = [User]()
            for relationshipJSON in relationships {
                
                var friendObj: UserObject?
                
                if let userJSON = relationshipJSON["friend"] as? JSONDictionary {
                    friendObj = UserObject.parseJSON(json: userJSON)
                }
                
                guard let friend = friendObj else { continue }
                                
                friends.append(friend)
            }
            
            completion(friends, nil)
        }
    }
    
    func blockUser(_ userId: String, _ completion: @escaping ((Error?) -> Void)) {
        guard var request = APIRequest.blockUser(userId).request() else {
            completion(RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
             
        let requestBody = [
            "type": 2 // 2 = Block
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])

        send(request: request) { (data, response, error) in
            
            guard error == nil else {
                completion(error)
                return
            }
            
            guard let data = data else {
                completion(RemoteError.apiError(message: "Response has no data", errorCode: 0))
                return
            }
            
            guard let json = self.jsonParse(data: data) as? JSONDictionary else {
                completion(RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            if let errorMessage = json["error"] as? String {
                completion(RemoteError.apiError(message: errorMessage, errorCode: response?.statusCode))
            } else {
                completion(nil)
            }
        }
    }
    
    func unblockUser(_ userId: String, _ completion: @escaping ((Error?) -> Void)) {
        guard let request = APIRequest.unblockUser(userId).request() else {
            completion(RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
    
        send(request: request) { (data, response, error) in
          
            guard error == nil else {
              completion(error)
              return
            }

            guard let data = data else {
              completion(RemoteError.apiError(message: "Response has no data", errorCode: 0))
              return
            }

            if response?.statusCode == 204 {
              // Successful delete
              completion(nil)
              return
            }

            guard let json = self.jsonParse(data: data) as? JSONDictionary else {
              completion(RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
              return
            }

            if let errorMessage = json["error"] as? String {
              completion(RemoteError.apiError(message: errorMessage, errorCode: response?.statusCode))
            } else {
              completion(nil)
            }
        }
    }
    
    func getBlockedUsers(_ completion: @escaping (([User], Error?) -> Void)) {
        
        guard let request = APIRequest.getBlockedUsers.request() else {
            completion([], RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
        
        send(request: request) { (data, response, error) in
            
            guard error == nil else {
                completion([], error)
                return
            }
            
            guard let data = data else {
                completion([], RemoteError.apiError(message: "Response has no data", errorCode: 0))
                return
            }
            
            guard let json = self.jsonParse(data: data) as? JSONDictionary else {
                completion([], RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            guard let relationships = json["relationships"] as? [JSONDictionary] else {
                completion([], RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            var friends = [User]()
            for relationshipJSON in relationships {
                
                var friendObj: UserObject?
                
                if let userJSON = relationshipJSON["friend"] as? JSONDictionary {
                    friendObj = UserObject.parseJSON(json: userJSON)
                }
                
                guard let friend = friendObj else { continue }
                                
                friends.append(friend)
            }
            
            completion(friends, nil)
        }
    }

    
    func getProfiles(forUsersWithIds userIds: [String], completion: @escaping (([User]?, Error?) -> Void)) {
        
        guard !userIds.isEmpty else {
            completion([], nil)
            return
        }
        
        let idString = userIds.joined(separator: "&userIds[]=")
        guard let request = APIRequest.getProfiles(idString).request() else {
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
            
            guard let json = self.jsonParse(data: data) as? JSONDictionary else {
                completion(nil, RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            guard let profilesJSON = json["users"] as? [JSONDictionary] else {
                completion(nil, RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            var profiles = [User]()
            for profileJSON in profilesJSON {
                guard let user = UserObject.parseJSON(json: profileJSON) else { continue }
                profiles.append(user)
            }
            completion(profiles, nil)
        }
    }
    
    func updateUserStatus(completion: @escaping (Error?) -> Void) {
        guard var request = APIRequest.updateStatus.request() else {
            completion(RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
        
        let requestBody = [
            "status": [
                "platform": "IOS",
                "micOn": AgoraManager.shared.isInVoiceChannel
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])

        send(request: request) { (data, response, error) in
            
            guard error == nil else {
                completion(error)
                return
            }
            
            guard let data = data else {
                completion(RemoteError.apiError(message: "Response has no data", errorCode: 0))
                return
            }
            
            guard let json = self.jsonParse(data: data) as? JSONDictionary else {
                completion(RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            if let errorMessage = json["error"] as? String {
                completion(RemoteError.apiError(message: errorMessage, errorCode: response?.statusCode))
            } else {
                completion(nil)
            }
        }
    }
    
    func updateHighlights(tagline: String, about: String, completion: @escaping (Error?) -> Void) {
        guard var request = APIRequest.updateProfile.request() else {
            completion(RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
        
        //setup request
        let requestBody: JSONDictionary = ["tagline": tagline,
                                           "about": about]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        send(request: request) { (data, response, error) in
            
            guard error == nil else {
                completion(error)
                return
            }
            
            guard let data = data else {
                completion(RemoteError.apiError(message: "Response has no data", errorCode: 0))
                return
            }
            
            guard let json = self.jsonParse(data: data) as? JSONDictionary else {
                completion(RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            if let errorMessage = json["error"] as? String {
                completion(RemoteError.apiError(message: errorMessage, errorCode: response?.statusCode))
            } else {
                completion(nil)
            }
        }
    }
    
    func updateProfileMedia(media: [ProfileMedia], completion: @escaping (Error?) -> Void) {
        guard var request = APIRequest.updateProfile.request() else {
            completion(RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
        
        var mediaJSON = [JSONDictionary]()
        
        for media in media {
            let jsonObject: JSONDictionary = [
                "mediaType": media.type.rawValue,
                "url": media.url.absoluteString,
                "index": media.index
            ]
            mediaJSON.append(jsonObject)
        }
        
        //setup request
        let requestBody: JSONDictionary = ["profileMedia": mediaJSON]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        send(request: request) { (data, response, error) in
            
            guard error == nil else {
                completion(error)
                return
            }
            
            guard let data = data else {
                completion(RemoteError.apiError(message: "Response has no data", errorCode: 0))
                return
            }
            
            guard let json = self.jsonParse(data: data) as? JSONDictionary else {
                completion(RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            if let errorMessage = json["error"] as? String {
                completion(RemoteError.apiError(message: errorMessage, errorCode: response?.statusCode))
            } else {
                completion(nil)
            }
        }
    }
    
    func updateSocialLinks(socialLinks: [SocialLink], completion: @escaping (Error?) -> Void) {
        guard var request = APIRequest.updateProfile.request() else {
            completion(RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
        
        var socialLinksJSON = JSONDictionary()
        
        for link in socialLinks {
            socialLinksJSON[link.type.rawValue] = link.username
        }
        
        //setup request
        let requestBody: JSONDictionary = ["socialLinks": socialLinksJSON]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        send(request: request) { (data, response, error) in
            
            guard error == nil else {
                completion(error)
                return
            }
            
            guard let data = data else {
                completion(RemoteError.apiError(message: "Response has no data", errorCode: 0))
                return
            }
            
            guard let json = self.jsonParse(data: data) as? JSONDictionary else {
                completion(RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            if let errorMessage = json["error"] as? String {
                completion(RemoteError.apiError(message: errorMessage, errorCode: response?.statusCode))
            } else {
                completion(nil)
            }
        }
    }

}

extension RemoteCoordinator {
    
    //    func parseErrors(inJSON json: [String: Any]) {
    
    //        {
    //            "errors": [{
    //            "location": "body",
    //            "param": "ign",
    //            "msg": "Missing ign field"
    //            }]
    //        }
    //
    //        if let errors = json["errors"] as? [[String: Any]] {
    //
    //        }
    //    }
}
