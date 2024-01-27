//
//  Datacoordinator+Scheduling.swift
//  GameGether
//
//  Created by James Ajhar on 9/8/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import Foundation

extension DataCoordinator {
    
    func scheduleGameSession(ofType type: GameSessionType,
                             forGame gameId: String,
                             withTags tags: [Tag],
                             startTime: Date,
                             maxSize: UInt?,
                             sessionDescription: String,
                             completion: @escaping ((GameSession?, String?, Error?) -> Void)) {

        remoteCoordinator.scheduleGameSession(ofType: type,
                                              forGame: gameId,
                                              withTags: tags,
                                              startTime: startTime,
                                              maxSize: maxSize,
                                              sessionDescription: sessionDescription,
                                              completion: completion)
    }
    
    func createGameSession(forGame gameId: String,
                             withTags tags: [Tag],
                             sessionDescription: String,
                             completion: @escaping ((GameSession?, String?, Error?) -> Void)) {

        remoteCoordinator.createGameSession(forGame: gameId,
                                            withTags: tags,
                                            sessionDescription: sessionDescription,
                                            completion: completion)
    }
    
    func getGameSessions(forGame gameId: String? = nil,
                         withTags tags: [Tag]? = nil,
                         ofType sessionType: GameSessionType?,
                         startTime: Date? = nil,
                         maxStartTime: Date? = nil,
                         completion: @escaping (([GameSession], Error?) -> Void)) {
        
        remoteCoordinator.getGameSessions(forGame: gameId,
                                          withTags: tags,
                                          ofType: sessionType,
                                          startTime: startTime,
                                          maxStartTime: maxStartTime,
                                          completion: completion)
    }
    
    func getGameSessionsAttending(forGame gameId: String? = nil,
                                  withTags tags: [Tag]? = nil,
                                  startTime: Date? = nil,
                                  maxStartTime: Date? = nil,
                                  completion: @escaping (([GameSession], Error?) -> Void)) {
        
        remoteCoordinator.getGameSessionsAttending(forGame: gameId, withTags: tags, startTime: startTime, maxStartTime: maxStartTime, completion: completion)
    }

    
    func joinGameSession(_ session: GameSession, completion: @escaping (String?, Error?) -> Void) {
        remoteCoordinator.joinGameSession(session, completion: completion)
    }
    
    func leaveGameSession(_ session: GameSession, completion: @escaping (Error?) -> Void) {
        remoteCoordinator.leaveGameSession(session, completion: completion)
    }
    
    func getGameSessionTypes(forGame gameId: String, _ completion: @escaping (([GameSessionType], Error?) -> Void)) {
        remoteCoordinator.getGameSessionTypes(forGame: gameId, completion)
    }
    
    func getGameSession(withSessionId sessionId: String, completion: @escaping ((GameSession?, Error?) -> Void)) {
        remoteCoordinator.getGameSession(withSessionId: sessionId, completion: completion)
    }
}
