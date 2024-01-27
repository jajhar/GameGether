//
//  RequiredRule.swift
//  GameGether
//
//  Created by James Ajhar on 6/21/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation

public class RequiredRule: FormRule {

    fileprivate var message: String

    public var isRequired: Bool = true

    required public init(message: String = "This field is required") {
        self.message = message
    }

    public func validate(_ value: String) -> Bool {
        return !value.isEmpty
    }

    public func errorMessage() -> String {
        return message
    }
}
