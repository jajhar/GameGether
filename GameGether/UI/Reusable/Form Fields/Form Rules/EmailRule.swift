//
//  EmailRule.swift
//  GameGether
//
//  Created by James Ajhar on 6/21/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation

public class EmailRule: FormRule {

    fileprivate var message: String

    public var isRequired: Bool = true

    required public init(message: String = "Please enter a valid email address") {
        self.message = message
    }

    public func validate(_ value: String) -> Bool {
        let test = NSPredicate(format: "SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}[ ]*")
        return test.evaluate(with: value)
    }

    public func errorMessage() -> String {
        return message
    }
}
