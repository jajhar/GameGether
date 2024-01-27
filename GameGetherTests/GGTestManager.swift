//
//  GGTestManager.swift
//  GameGetherTests
//
//  Created by James Ajhar on 9/8/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import XCTest
@testable import GameGether

class GGBaseTestCase: XCTestCase {
    
    func login() {
        let exp = expectation(description: "Wait for login to finish")

        DataCoordinator.shared.loginUser(withEmail: "james.ajhar@gmail.com",
                                         andPassword: "password1!A")
        { (user, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(user)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
}
