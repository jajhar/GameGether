//
//  RemoteCoordinator+Search.swift
//  GameGether
//
//  Created by James Ajhar on 8/23/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation

extension RemoteCoordinator {
    
    func search(forUsersWithIGN ign: String, andIGNCount count: Int?, completion: @escaping (([User]?, Error?) -> Void)) {
    
        guard var request = APIRequest.searchUsers.request() else {
            completion(nil, RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
        
        var body: [String: Any] = ["ign": ign]
        if let count = count {
            body["ignCount"] = count
        }
        
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
            
            guard let json = self.jsonParse(data: data) as? JSONDictionary,
                let usersJSON = json["users"] as? [JSONDictionary] else {
                completion(nil, RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            var users = [User]()
            for userJSON in usersJSON {
                guard let user = UserObject.parseJSON(json: userJSON) else { continue }
                users.append(user)
            }
            
            completion(users, nil)
        }
    }
}
