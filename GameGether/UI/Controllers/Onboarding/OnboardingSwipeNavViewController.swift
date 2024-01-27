//
//  OnboardingSwipeNavViewController.swift
//  GameGether
//
//  Created by James Ajhar on 8/7/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit
import EasyTipView

class OnboardingSwipeNavViewController: UIViewController {
    
    // MARK: - Properties
    private var tooltip: EasyTipView = {
        var prefs = EasyTipView.gamegetherPreferences
        prefs.drawing.arrowPosition = .bottom
        prefs.positioning.contentVInset = 10
        prefs.drawing.arrowWidth = 30
        prefs.drawing.arrowHeight = 16
        prefs.positioning.bubbleVInset = 20
        prefs.animating.dismissOnTap = false
        let tipView = EasyTipView.tooltip(withText: "swipe me up to navigate!", preferences: prefs)
        return tipView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let joystick = NavigationManager.shared.navigationOverlay?.joyStickView.handleImageView {
            tooltip.show(forView: joystick, withinSuperview: NavigationManager.shared.navigationOverlay)
        }
        
        tooltip.animate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NavigationManager.shared.navigationOverlay?.onGameNavigationDidShow = { [weak self] in
            self?.tooltip.isHidden = true
        }
        
        NavigationManager.shared.navigationOverlay?.onGameNavigationDidHide = { [weak self] in
            self?.tooltip.isHidden = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NavigationManager.shared.navigationOverlay?.onGameNavigationDidShow = nil
        NavigationManager.shared.navigationOverlay?.onGameNavigationDidHide = nil
    }
    
    deinit {
        tooltip.dismiss()
    }

    // MARK: - Interface Actions
    
    @IBAction func backButtonPressed(_ sender: Any) {
        dismissSelf()
    }
}

extension OnboardingSwipeNavViewController: ShowsNavigationOverlay {
    
    var floatingViewOverlayShouldDisplay: Bool {
        return false
    }
    
    var navigationBarShouldDisplay: Bool {
        return false
    }
    
    var joystickImage: NavigationJoystickViewImage {
        return .custom(#imageLiteral(resourceName: "GG_AI_Selected"))
    }
}
