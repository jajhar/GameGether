//
//  MinLengthRule.swift
//  GameGether
//
//  Created by James Ajhar on 6/21/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation

public class MinLengthRule: FormRule {

    /// Default minimum character length.
    fileprivate var length: Int = 3

    public var isRequired: Bool = true

    /// Default error message to be displayed if validation fails.
    fileprivate var message: String

    required public init(message: String) {
        self.message = message
    }

    /**
     Initializes a `MaxLengthRule` object that is to validate the length of the text of a field.

     - parameter length: Minimum character length.
     - parameter message: String of error message.
     - returns: An initialized `MinLengthRule` object, or nil if an object could not be created for some reason that would not result in an exception.
     */
    public init(length: Int, message: String = "Must be at least %ld characters long", isRequired: Bool = true) {
        self.length = length
        self.message = String(format: message, length)
        self.isRequired = isRequired
    }

    public func validate(_ value: String) -> Bool {
        return value.count >= length
    }

    public func errorMessage() -> String {
        return message
    }
}
