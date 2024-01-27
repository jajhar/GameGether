//
//  RemoteCoordinator+Games.swift
//  GameGether
//
//  Created by James Ajhar on 9/6/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation

extension RemoteCoordinator {
    
    func getGames(completion: @escaping (([Game]?, Error?) -> Void)) {
        
        guard let request = APIRequest.getGames.request() else {
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
                let gamesJSON = json["data"] as? [JSONDictionary] else {
                completion(nil, RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            var games = [Game]()
            for gameJSON in gamesJSON {
                let game = GameObject.parseJSON(gameJSON)
                games.append(game)
            }
            
            completion(games, nil)
        }
    }
    
    func setFavoriteGames(games: [Game], completion: @escaping (Error?) -> Void) {

        guard var request = APIRequest.addFavoriteGame.request() else {
            completion(RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
        
        let body: [String: Any] = [
            "games": games.compactMap({ return ["gameId": $0.identifier, "gamerTag": $0.gamerTag] }),
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
                
        send(request: request) { (data, response, error) in
            
            guard error == nil else {
                completion(error)
                return
            }
            
            guard response?.statusCode == 200 else {
                completion(RemoteError.apiError(message: "Invalid response code", errorCode: 0))
                return
            }
            
            completion(nil)
        }
    }
    
    func getActiveLobbies(completion: @escaping (([ActiveLobby], Error?) -> Void)) {
        
        guard let request = APIRequest.getActiveLobbies.request() else {
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
                let lobbiesJSON = json["lobbies"] as? [JSONDictionary] else {
                completion([], RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            var lobbies = [ActiveLobby]()
            for lobbyJSON in lobbiesJSON {
                let lobby = ActiveLobbyObject.parseJSON(lobbyJSON)
                lobbies.append(lobby)
            }
            
            completion(lobbies, nil)
        }
    }

}
