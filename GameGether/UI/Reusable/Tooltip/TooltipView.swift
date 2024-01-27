//
//  GGTooltipView.swift
//  GameGether
//
//  Created by James Ajhar on 8/16/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit
import EasyTipView

extension EasyTipView {

    static let gamegetherPreferences: EasyTipView.Preferences = {
        var preferences = EasyTipView.Preferences()
        preferences.drawing.font = AppConstants.Fonts.robotoRegular(18).font
        preferences.drawing.foregroundColor = .white
        preferences.drawing.backgroundColor = UIColor(hexString: "366CB3")
        preferences.drawing.borderColor = .white
        preferences.drawing.borderWidth = 3
        preferences.drawing.shadowColor = .black
        preferences.drawing.shadowOpacity = 0.3
        preferences.drawing.shadowRadius = 2
        preferences.drawing.shadowOffset = CGSize(width: 1, height: 2)
        preferences.drawing.cornerRadius = 8
        preferences.drawing.arrowPosition = .bottom
        preferences.drawing.arrowWidth = 15
        preferences.drawing.arrowHeight = 7
        preferences.positioning.contentVInset = 5
        preferences.positioning.contentHInset = 8
        preferences.positioning.bubbleVInset = 5
        preferences.positioning.maxWidth = UIScreen.main.bounds.width - 10 // inset of five(ish)
        return preferences
    }()
    
    static func tooltip(withText text: String, preferences: EasyTipView.Preferences = EasyTipView.gamegetherPreferences, delegate: EasyTipViewDelegate? = nil) -> EasyTipView {
        return EasyTipView(text: text, preferences: preferences, delegate: delegate)
    }
    
    public func animate(distance: CGFloat = -7) {
        addHoverAnimation(duration: 1, distance: distance)
    }
    
    public func dismissOnTap() {
        let dismissTap = UITapGestureRecognizer(target: self,
                                                action: #selector(dismissSelf))
        dismissTap.cancelsTouchesInView = false
        NavigationManager.topMostViewController()?.view.addGestureRecognizer(dismissTap)
    }
    
    @objc func dismissSelf() {
        dismiss()
    }

}
