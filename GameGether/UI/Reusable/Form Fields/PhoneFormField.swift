//
//  PhoneFormField.swift
//  GameGether
//
//  Created by James Ajhar on 6/21/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

class PhoneFormField: FormTextField {

    private var toolbar: UIToolbar!

    override func commonInit() {
        super.commonInit()

        keyboardType = .phonePad
        titleLabel.text = "Phone"

        // Default rule set
//        ruleSet.append(PhoneNumberRule(message: "Please enter a valid phone number"))

        // Setup keyboard toolbar
        toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: frame.width, height: 50))
        toolbar.barStyle = .default
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "done",
                            style: .done,
                            target: self,
                            action: #selector(doneButtonPressed(sender:)))
        ]
        toolbar.sizeToFit()
        inputAccessoryView = toolbar
    }

    @objc func doneButtonPressed(sender: UIBarButtonItem?) {
        _ = resignFirstResponder()
    }
}
