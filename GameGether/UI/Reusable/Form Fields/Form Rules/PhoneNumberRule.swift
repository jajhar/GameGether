//
//  PhoneNumberRule.swift
//  GameGether
//
//  Created by James Ajhar on 6/21/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation

public class PhoneNumberRule: FormRule {

    fileprivate var message: String

    public var isRequired: Bool = true
    
    required public init(message: String = "Please enter a valid phone number") {
        self.message = message
    }

    public func validate(_ value: String) -> Bool {
        let test = NSPredicate(format: "SELF MATCHES %@", "^\\d{10}$")
        return test.evaluate(with: value)
    }

    public func errorMessage() -> String {
        return message
    }
}
