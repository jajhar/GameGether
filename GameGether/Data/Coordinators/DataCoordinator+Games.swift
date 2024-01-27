//
//  DataCoordinator+Games.swift
//  GameGether
//
//  Created by James Ajhar on 8/27/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import Foundation

extension DataCoordinator {
    
    func getGames(ignoreCache: Bool = false, completion: @escaping (([Game], Error?) -> Void)) {
        
        localCoordinator.getGames { [unowned self] (cachedGames, error) in
            
            if !ignoreCache, let games = cachedGames, games.count > 0 {
                completion(games, error)
                return
            }
            
            self.remoteCoordinator.getGames { (games, error) in
                
                guard error == nil else {
                    performOnMainThread {
                        completion([], error ?? DataCoordinatorError.unknown)
                    }
                    return
                }
                
                guard let games = games else {
                    completion([], nil)
                    return
                }
                
                self.localCoordinator.saveGames(games: games, completion: { (savedGames, error) in
                    completion(savedGames ?? [], error)
                })
            }
        }
    }
    
    func updateGamerTag(gamerTag: String, forGame game: Game, completion: @escaping (Game?, Error?) -> Void) {
        getFavoriteGames { [weak self] (remoteGames, error) in
            guard error == nil else {
                performOnMainThread {
                    completion(nil, error ?? DataCoordinatorError.unknown)
                }
                return
            }
            
            guard let game = remoteGames.filter({ $0.identifier == game.identifier }).first else {
                completion(nil, nil)
                return
            }
            
            game.gamerTag = gamerTag
            
            self?.setFavoriteGames(games: remoteGames, completion: { (error) in
                if let error = error {
                    completion(nil, error)
                    return
                }
                completion(game, nil)
            })
        }
    }
    
    func getFavoriteGames(_ completion: @escaping ([Game], Error?) -> Void) {
        
        getGames { (remoteGames, error) in
            guard error == nil else {
                performOnMainThread {
                    completion([], error ?? DataCoordinatorError.unknown)
                }
                return
            }
            
            completion(remoteGames.filter({ $0.isFavorite }), nil)
        }
    }
    
    func setFavoriteGames(games: [Game], completion: @escaping (Error?) -> Void) {
        
        remoteCoordinator.setFavoriteGames(games: games) { [unowned self] (error) in
            guard error == nil else {
                performOnMainThread {
                    completion(error ?? DataCoordinatorError.unknown)
                }
                return
            }
            
            self.localCoordinator.setFavoriteGames(games: games, completion: { (error) in
                completion(error)
            })
        }
    }
    
    func getActiveLobbies(completion: @escaping (([ActiveLobby], Error?) -> Void)) {
        remoteCoordinator.getActiveLobbies(completion: completion)
    }
}
