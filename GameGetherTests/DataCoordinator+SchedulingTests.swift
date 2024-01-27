//
//  DataCoordinator+SchedulingTests.swift
//  GameGetherTests
//
//  Created by James Ajhar on 9/8/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import XCTest
@testable import GameGether

class DataCoordinator_SchedulingTests: GGBaseTestCase {

    struct Constants {
        static let fortniteGameId = "5b91f332fcc9b35219ffa2f8"
        static let gameTags = [TagObject(withIdentifier: "5b9b267c2810d0fbe6777c47", title: "PC", type: .device)]
    }
    
    let dataCoordinator = DataCoordinator.shared
    
    override func setUp() {
        super.setUp()
  
        dataCoordinator.clearCache()
        dataCoordinator.start()
        
        login()
    }
    
    override func tearDown() {
        dataCoordinator.clearCache()
        super.tearDown()
    }
  
    func testScheduleGameSession() {
        
//        let exp = expectation(description: "Wait for game session to be created")
//
//        guard let startTime = Date().addHours(1) else { return XCTFail("Invalid start time") }
//
//        dataCoordinator.scheduleGameSession(ofType: .gameMode,
//                                            forGame: Constants.fortniteGameId,
//                                            withTags: Constants.gameTags,
//                                            startTime: startTime,
//                                            maxSize: 0,
//                                            sessionDescription: "new game session")
//        { (newSession, _, error) in
//            XCTAssertNil(error)
//            XCTAssertNotNil(newSession)
//            XCTAssertFalse(newSession?.identifier.isEmpty ?? true)
//            exp.fulfill()
//        }
//        
//        waitForExpectations(timeout: 10.0, handler: nil)
    }
    
    func testFetchGameSessions() {
        let exp = expectation(description: "Wait for game sessions to be fetched")
        
        dataCoordinator.getGameSessions(forGame: Constants.fortniteGameId,
                                        withTags: Constants.gameTags,
                                        ofType: nil)
        { (sessions, error) in
            XCTAssertNil(error)
            XCTAssertFalse(sessions.isEmpty)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 10.0, handler: nil)
    }
    
    func testFetchGameSessionTypes() {
        let exp = expectation(description: "Wait for game sessions to be fetched")
        
        dataCoordinator.getGameSessionTypes(forGame: Constants.fortniteGameId)
        { (types, error) in
            XCTAssertNil(error)
            XCTAssertFalse(types.isEmpty)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 10.0, handler: nil)
    }
    
    func testFetchGameSession() {
        let exp = expectation(description: "Wait for game sessions to be fetched")
        
        dataCoordinator.getGameSession(withSessionId: "5dc8d0f2e577a6537ae733a6", completion: { (session, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(session)
            exp.fulfill()
        })
        
        waitForExpectations(timeout: 10.0, handler: nil)
    }
    
    func testJoinGameSession() {

    }
    
    func testLeaveGameSession() {
        
    }
}
