//
//  UITextViewNoPadding.swift
//  GameGether
//
//  Created by James Ajhar on 8/30/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

@IBDesignable class UITextViewNoPadding: UITextView {
    
    private(set) var originalTextContainerInset: UIEdgeInsets = .zero
    private(set) var originalLineFragmentPadding: CGFloat = 0
    private(set) var originalContentInset: UIEdgeInsets = .zero

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        commonInit()
        removePadding()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
        removePadding()
    }
    
    private func commonInit() {
        originalTextContainerInset = textContainerInset
        originalLineFragmentPadding = textContainer.lineFragmentPadding
        originalContentInset = contentInset
    }
    
    func removePadding() {
        textContainerInset = .zero
        textContainer.lineFragmentPadding = 0
        contentInset = .zero
    }
    
    func addPadding() {
        textContainerInset = originalTextContainerInset
        textContainer.lineFragmentPadding = originalLineFragmentPadding
        contentInset = originalContentInset
    }
}
