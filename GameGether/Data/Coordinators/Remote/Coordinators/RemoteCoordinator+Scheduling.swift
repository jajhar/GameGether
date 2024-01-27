//
//  RemoteCoordinator+Scheduling.swift
//  GameGether
//
//  Created by James Ajhar on 9/8/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import Foundation

extension RemoteCoordinator {
    
    func scheduleGameSession(ofType type: GameSessionType,
                             forGame gameId: String,
                             withTags tags: [Tag],
                             startTime: Date,
                             maxSize: UInt?,
                             sessionDescription: String,
                             completion: @escaping ((GameSession?, String?, Error?) -> Void)) {
        
        guard var request = APIRequest.scheduleGameSession.request() else {
            completion(nil, nil, RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
        
        let tagIds = tags.compactMap({ $0.identifier })

        //setup request
        var requestBody: JSONDictionary = [
            "gameId": gameId,
            "tags": tagIds,
            "sessionType": type.identifier,
            "begins": startTime.iso8601Format(),
            "description": sessionDescription
        ]
        
        if let maxSize = maxSize {
            requestBody["maxSize"] = maxSize
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        send(request: request) { (data, response, error) in
            
            guard error == nil else {
                completion(nil, nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, nil, RemoteError.apiError(message: "Response has no data", errorCode: 0))
                return
            }
            
            guard let json = self.jsonParse(data: data) as? JSONDictionary, let sessionJSON = json["session"] as? JSONDictionary else {
                completion(nil, nil, RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }

            guard response?.statusCode == 200 else {
                completion(nil, nil, RemoteError.apiError(message: "Failed to create session", errorCode: 0))
                return
            }
            
            let session = GameSessionObject(json: sessionJSON)
            
            completion(session, json["chatroom"] as? String, nil)
        }
    }
    
    func createGameSession(forGame gameId: String,
                             withTags tags: [Tag],
                             sessionDescription: String,
                             completion: @escaping ((GameSession?, String?, Error?) -> Void)) {
        
        guard var request = APIRequest.scheduleGameSession.request() else {
            completion(nil, nil, RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
        
        let tagIds = tags.compactMap({ $0.identifier })

        //setup request
        let requestBody: JSONDictionary = [
            "gameId": gameId,
            "tags": tagIds,
            "sessionType": "5d929b42f6cd5547de36423b",  // REQUEST type
            "description": sessionDescription
        ]
                
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        send(request: request) { (data, response, error) in
            
            guard error == nil else {
                completion(nil, nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, nil, RemoteError.apiError(message: "Response has no data", errorCode: 0))
                return
            }
            
            guard let json = self.jsonParse(data: data) as? JSONDictionary, let sessionJSON = json["session"] as? JSONDictionary else {
                completion(nil, nil, RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }

            guard response?.statusCode == 200 else {
                completion(nil, nil, RemoteError.apiError(message: "Failed to create session", errorCode: 0))
                return
            }
            
            let session = GameSessionObject(json: sessionJSON)
            
            completion(session, json["chatroom"] as? String, nil)
        }
    }
    
    func getGameSessions(forGame gameId: String? = nil,
                         withTags tags: [Tag]? = nil,
                         ofType sessionType: GameSessionType?,
                         startTime: Date? = nil,
                         maxStartTime: Date? = nil,
                         completion: @escaping (([GameSession], Error?) -> Void)) {
       
        let tagIds = tags?.compactMap({ $0.identifier })
        let tagsIdString = tagIds?.joined(separator: "&tags[]=")

        guard let request = APIRequest.getGameSessions(gameId,
                                                       tagsIdString,
                                                       sessionType?.identifier,
                                                       startTime?.iso8601Format(),
                                                       maxStartTime?.iso8601Format()).request() else {
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
            
            guard let json = self.jsonParse(data: data) as? JSONDictionary,
                let sessionsJSON = json["sessions"] as? [JSONDictionary] else {
                completion([], RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            var sessions = [GameSession]()
            for json in sessionsJSON {
                sessions.append(GameSessionObject(json: json))
            }
            
            completion(sessions, nil)
        }
    }
    
    func getGameSession(withSessionId sessionId: String,
                        completion: @escaping ((GameSession?, Error?) -> Void)) {
       
        guard let request = APIRequest.getGameSession(sessionId).request() else {
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
                let sessionJSON = json["session"] as? JSONDictionary else {
                completion(nil, RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            completion(GameSessionObject(json: sessionJSON), nil)
        }
    }
    
    func getGameSessionsAttending(forGame gameId: String? = nil,
                         withTags tags: [Tag]? = nil,
                         startTime: Date? = nil,
                         maxStartTime: Date? = nil,
                         completion: @escaping (([GameSession], Error?) -> Void)) {
        
        let tagIds = tags?.compactMap({ $0.identifier })
        let tagsIdString = tagIds?.joined(separator: "&tags[]=")
        
        guard let request = APIRequest.getGameSessionsAttending(gameId,
                                                       tagsIdString,
                                                       startTime?.iso8601Format(),
                                                       maxStartTime?.iso8601Format()).request() else {
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
            
            guard let json = self.jsonParse(data: data) as? JSONDictionary,
                let sessionsJSON = json["sessions"] as? [JSONDictionary] else {
                completion([], RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            var sessions = [GameSession]()
            for json in sessionsJSON {
                sessions.append(GameSessionObject(json: json))
            }
            
            completion(sessions, nil)
        }
    }
    
    func joinGameSession(_ session: GameSession, completion: @escaping (String?, Error?) -> Void) {
        
        guard let request = APIRequest.joinGameSession(session.identifier).request() else {
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
            
            guard response?.statusCode == 200 || response?.statusCode == 409 else {
                
                if response?.statusCode == 400,
                    let error = json["error"] as? JSONDictionary,
                    let message = error["message"] as? String {
                    // Parse error if possible
                    completion(nil, RemoteError.apiError(message: message, errorCode: 0))
                    return
                }
                
                completion(nil, RemoteError.apiError(message: "Invalid response code from API", errorCode: 0))
                return
            }
            
            completion(json["chatroom"] as? String, nil)
        }
    }

    func leaveGameSession(_ session: GameSession, completion: @escaping (Error?) -> Void) {
        
        guard let request = APIRequest.leaveGameSession(session.identifier).request() else {
            completion(RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
        
        send(request: request) { (data, response, error) in
            
            guard error == nil else {
                completion(error)
                return
            }
            
            guard response?.statusCode == 200 else {
                completion(RemoteError.apiError(message: "Invalid response code from API", errorCode: 0))
                return
            }
            
            completion(nil)
        }
    }
    
    func getGameSessionTypes(forGame gameId: String, _ completion: @escaping (([GameSessionType], Error?) -> Void)) {
                
        guard let request = APIRequest.getGameSessionTypes(gameId).request() else {
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
            
            guard let typesJSON = self.jsonParse(data: data) as? [JSONDictionary] else {
                completion([], RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            let types: [GameSessionType] = typesJSON.compactMap({ GameSessionTypeObject.parse(json: $0) })
            completion(types, nil)
        }
    }
}
