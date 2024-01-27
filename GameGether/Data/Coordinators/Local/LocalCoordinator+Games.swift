//
//  LocalCoordinator+Games.swift
//  GameGether
//
//  Created by James Ajhar on 8/27/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import Foundation
import CoreData

extension LocalCoordinator {
    
    // MARK: Games
    
    func getGames(completion: @escaping (([Game]?, Error?) -> Void)) {
        
        let context = persistentContainer.viewContext
        
        context.perform {
            
            do {
                let request: NSFetchRequest<GameMO> = NSFetchRequest(entityName: "GameMO")
                
                let games = try context.fetch(request)
                
                if let game = games.first,
                    let date = Date().subtractSeconds(Constants.staleGamesCacheInterval),
                    date > game.updatedAt
                {
                    // cache is stale
                    completion(nil, nil)
                    return
                }
                
                var threadSafeGames = [Game]()
                
                for game in games {
                    threadSafeGames.append(GameObject(fromGameMO: game))
                }
                
                completion(threadSafeGames, nil)
                
            } catch {
                GGLog.error("Error: \(error)")
                completion(nil, error)
            }
        }
    }
    
    func saveGames(games: [Game], completion: (([Game]?, Error?) -> Void)?) {
        
        let context = persistentContainer.viewContext
        
        deleteAllGames { (error) in
            
            context.perform {
                
                do {
                    guard let description = NSEntityDescription.entity(forEntityName: "\(GameMO.self)", in: context) else {
                        completion?(nil, LocalCoordinatorError.gameSaveFailed)
                        return
                    }
                    
                    var threadSafeGames = [Game]()
                    
                    for game in games {
                        let gameMO = GameMO(entity: description, insertInto: context)
                        gameMO.update(fromGameModel: game)
                        
                        // Save each game's genres
                        for genre in game.genres {
                            guard let genreMODescription = NSEntityDescription.entity(forEntityName: "\(GenreMO.self)", in: context) else { continue }
                            let genreMO = GenreMO(entity: genreMODescription, insertInto: context)
                            genreMO.update(fromGenre: genre)
                            gameMO.genresRelationship?.insert(genreMO)
                        }
                        
                        threadSafeGames.append(GameObject(fromGameMO: gameMO))
                    }
                    
                    try context.save()
                    
                    completion?(threadSafeGames, nil)
                    
                } catch {
                    GGLog.error("Error: \(error)")
                    completion?(nil, error)
                }
            }
        }
    }
    
    func setFavoriteGames(games: [Game], completion: @escaping (Error?) -> Void) {
        
        let context = persistentContainer.viewContext
        
        context.perform {
            
            do {
                let request: NSFetchRequest<GameMO> = NSFetchRequest(entityName: "\(GameMO.self)")
                
                let savedGames = try context.fetch(request)
                
                guard games.count > 0 else {
                    completion(nil)
                    return
                }
                
                for game in savedGames {
                    if let favoriteGame = games.filter({ $0.identifier == game.identifier }).first {
                        game.isFavorite = true
                        game.gamerTag = favoriteGame.gamerTag
                    } else {
                        game.isFavorite = false
                    }
                }
                
                try context.save()
                
                completion(nil)
                
            } catch {
                GGLog.error("Error: \(error)")
                completion(error)
            }
        }
    }
    
    func deleteAllGames(_ completion: ((Error?) -> Void)? = nil) {
        let fetchRequest = NSFetchRequest<GameMO>(entityName: "\(GameMO.self)")
        
        let context = persistentContainer.viewContext
        context.performAndWait { [weak self] in
            do {
                guard let strongSelf = self else {
                    completion?(LocalCoordinatorError.deallocated)
                    return
                }
                
                let results = try context.fetch(fetchRequest)
                results.forEach({ context.delete($0) })
                
                strongSelf.saveContext()
                completion?(nil)
                
            } catch let error as NSError {
                GGLog.error("Error: \(error)")
                completion?(error)
            }
        }
    }    
}
