//
//  UITextField+Extensions.swift
//  GameGether
//
//  Created by James Ajhar on 8/14/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

extension UITextField {
    
    private func moveCursorToEnd() {
        if let newPosition = position(from: self.endOfDocument, offset: 0) {
            self.selectedTextRange = self.textRange(from: newPosition, to: newPosition)
        }
        let selectedRange: UITextRange? = self.selectedTextRange
        self.offset(from: self.endOfDocument, to: (selectedRange?.start)!)
    }

    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }

    func setRightPaddingPoints(_ amount:CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.rightView = paddingView
        self.rightViewMode = .always
    }
}
