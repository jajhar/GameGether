//
//  PasswordFormField.swift
//  GameGether
//
//  Created by James Ajhar on 6/21/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

public class PasswordFormField: FormTextField {

    override func commonInit() {
        super.commonInit()
        
//        rightButtonText = "hide"
//        rightButtonTextToggled = "show"
//        showsRightButton = true
//        rightButton.isHidden = true
        isSecureTextEntry = true
        addClearTextButton()
        showsErrorBorder = true

        // Default rule set
        let minLengthRule = MinLengthRule(length: 6, message: "Password must be at least 6 characters long")
        ruleSet.append(minLengthRule)
    }
    
    override func updateRightButton() {
        super.updateRightButton()
        
        if text?.isEmpty == false {
            addRightButton()
        } else {
            rightView = nil
        }
    }
    
    override func updateUI() {
        if text?.isEmpty == false {
            addRightButton()
        } else {
            rightView = nil
        }
    }
}
