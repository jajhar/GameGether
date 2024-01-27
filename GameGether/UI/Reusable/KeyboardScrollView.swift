//
//  KeyboardScrollView.swift
//  GameGether
//
//  Created by James Ajhar on 6/24/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation
import UIKit

public protocol KeyboardScrollViewDelegate: class {
    func keyboardScrollViewDidAdjustInsets(scrollView: UIScrollView)
}

open class KeyboardScrollView: UIScrollView {
    
    public weak var keyboardDelegate: KeyboardScrollViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func commonInit() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    // MARK: Keyboard Notifications
    
    @objc func keyboardWillChangeFrame(_ notification: Notification) {
        performOnMainThread {
            guard let info = notification.userInfo, let kbValue = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
            let keyboardSize = kbValue.cgRectValue
            
            self.contentInset = UIEdgeInsets(top: 0.0,
                                             left: 0.0,
                                             bottom: abs(keyboardSize.minY - UIScreen.main.bounds.height) + 20, // +20 for some extra padding
                right: 0.0)
            self.layoutIfNeeded()
            
            self.keyboardDelegate?.keyboardScrollViewDidAdjustInsets(scrollView: self)
        }
    }
}

open class KeyboardCollectionView: UICollectionView {
    
    public weak var keyboardDelegate: KeyboardScrollViewDelegate?
    
    public override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func commonInit() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    // MARK: Keyboard Notifications
    
    @objc func keyboardWillChangeFrame(_ notification: Notification) {
        performOnMainThread {
            guard let info = notification.userInfo, let kbValue = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
            let keyboardSize = kbValue.cgRectValue
            
            self.contentInset = UIEdgeInsets(top: self.contentInset.top,
                                             left: self.contentInset.left,
                                             bottom: abs(keyboardSize.minY - UIScreen.main.bounds.height) + 100,
                                             right: self.contentInset.right)
            self.layoutIfNeeded()
            
            self.keyboardDelegate?.keyboardScrollViewDidAdjustInsets(scrollView: self)
        }
    }
}
