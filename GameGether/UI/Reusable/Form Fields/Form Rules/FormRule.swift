//
//  FormRule.swift
//  GameGether
//
//  Created by James Ajhar on 6/21/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation

public protocol FormRule {
    /**
     Validates text of a field.

     - parameter value: String of text to be validated.
     - returns: Boolean value. True if validation is successful; False if validation fails.
     */
    func validate(_ value: String) -> Bool

    var isRequired: Bool { get set }
    
    /**
     Used to display error message when validation fails.
     - returns: String of error message.
     */
    func errorMessage() -> String

    /**
     Initializes `FormRule` object with error message.

     - parameter message: String of error message.
     - returns: An initialized `FormRule` object, or nil if an object could not be created for some reason that would not result in an exception.
     */
    init(message: String)
}
