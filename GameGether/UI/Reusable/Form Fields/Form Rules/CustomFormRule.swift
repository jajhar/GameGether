//
//  CustomFormRule.swift
//  GameGether
//
//  Created by James Ajhar on 6/21/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation

/**
 `CustomFormRule` is a subclass of RegexRule that defines how a field is validated.
 */
public class CustomFormRule: FormRule {
    
    var regex = ""
    
    var message: String
    
    public var isRequired: Bool = true

    /**
     Initializes a `CustomFormRule` object that will validate a field
     
     - parameter message: String of error message.
     - returns: An initialized `CustomFormRule` object, or nil if an object could not be created for some reason that would not result in an exception.
     */
    required public init(message: String = "Field is not valid", regex: String, isRequired: Bool = true) {
        self.regex = regex
        self.message = message
        self.isRequired = isRequired
    }
    
    required public init(message: String = "Field is not valid") {
        self.message = message
    }
    
    public func validate(_ value: String) -> Bool {
        return value.range(of: regex, options: .regularExpression) != nil
    }
    
    public func errorMessage() -> String {
        return message
    }
    
}
