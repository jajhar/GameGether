//
//  EmailFormField.swift
//  GameGether
//
//  Created by James Ajhar on 6/21/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

open class EmailFormField: FormTextField {

    override func commonInit() {
        super.commonInit()

        keyboardType = .emailAddress
        addClearTextButton()
        
        // Default rule set
        ruleSet.append(EmailRule(message: "invalid_email_address"))
        
        showsErrorBorder = true
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
