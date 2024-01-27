//
//  GameGetherTests.swift
//  GameGetherTests
//
//  Created by James Ajhar on 6/16/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import XCTest
@testable import GameGether

class DataCoordinatorTests: XCTestCase {
    
    struct Constants {
        static let fortniteGameId = "5b91f332fcc9b35219ffa2f8"
    }
    
    let dataCoordinator = DataCoordinator()
    let localCoordinator = LocalCoordinator()
    
    override func setUp() {
        super.setUp()
        
        dataCoordinator.clearCache()
    }
    
    override func tearDown() {
        dataCoordinator.clearCache()

        super.tearDown()
    }
    
//    func testRegistration() {
//
//        let exp = expectation(description: "Wait for login success")
//
//        dataCoordinator.loginUser(withEmail: "j9cartoon@aol.com", andPassword: "password") { (user, error) in
//            XCTAssertNil(error)
//            XCTAssertNotNil(user)
//            exp.fulfill()
//        }
//
//        waitForExpectations(timeout: 10.0, handler: nil)
//    }
    
    func testLogin() {
        
        let exp = expectation(description: "Wait for login success")

        dataCoordinator.loginUser(withEmail: "j9cartoon@aol.com", andPassword: "password1!A") { (user, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(user)
            XCTAssertNotNil(self.localCoordinator.currentUser())
            XCTAssertNotNil(self.dataCoordinator.signedInUser)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 10.0, handler: nil)
    }
    
    func testCheckIGN() {
        
        let exp = expectation(description: "Wait for check IGN success")
        
        dataCoordinator.checkIGNAvailability(ign: "jajhar") { (count, error) in
            XCTAssertNil(error)
            XCTAssertEqual(count, 3)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 10.0, handler: nil)
    }
    
    func testGetFriends() {
        
        let exp = expectation(description: "Wait for get friends success")
        
        dataCoordinator.loginUser(withEmail: "james.ajhar@gmail.com", andPassword: "password1!A") { (user, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(user)
        
            self.dataCoordinator.getFriends { (friends, error) in
                XCTAssertNil(error)
                XCTAssertNotNil(friends)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }
    
    func testGetTags() {
        
        let exp = expectation(description: "Wait for get tags success")
        
        dataCoordinator.loginUser(withEmail: "james.ajhar@gmail.com", andPassword: "password1!A") { (user, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(user)
            
            self.dataCoordinator.getTags(forGame: Constants.fortniteGameId) { (tags, error) in
                XCTAssertNil(error)
                XCTAssertNotNil(tags)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }
    
    func testGetFollowedTags() {
        
        let exp = expectation(description: "Wait for get tags success")
        
        dataCoordinator.loginUser(withEmail: "james.ajhar@gmail.com", andPassword: "password1!A") { (user, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(user)
            
            self.dataCoordinator.getFollowedTags { (followedTags, error) in
                XCTAssertNil(error)
                XCTAssertNotNil(followedTags)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }
}
