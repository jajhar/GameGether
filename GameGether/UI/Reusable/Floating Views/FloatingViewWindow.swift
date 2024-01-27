//
//  FloatingViewWindow.swift
//  GameGether
//
//  Created by James Ajhar on 12/12/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

class FloatingViewWindow: UIWindow {
    
    let floatingViewOverlay: FloatingViewOverlay = {
        let view = FloatingViewOverlay()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        return view
    }()
    
    var floatingView: UIView? {
        didSet {
            floatingViewOverlay.floatingView = floatingView
        }
    }
    
    let navigationOverlayView: NavigationOverlayView = {
        let view = UINib(nibName: "\(NavigationOverlayView.self)", bundle: nil).instantiate(withOwner: self, options: nil).first as! NavigationOverlayView
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        return view
    }()
    
    /// Used to show/hide the floating overlay view (using isHidden messes with all the alphas of it's subviews...
    ///  This is a hacky thing to temporarily show/hide the overlay without affecting its subviews
    private var floatingOverlayViewHeightConstraint: NSLayoutConstraint?
    private var floatingOverlayViewBottomConstraint: NSLayoutConstraint?

    init() {
        super.init(frame: UIScreen.main.bounds)
        commonInit()
    }
    
    public func toggleFloatingViewOverlay(visible: Bool) {
        
        UIView.animate(withDuration: 0.3) {
            self.floatingViewOverlay.alpha = visible ? 1 : 0
            self.floatingViewOverlay.floatingView?.alpha = visible ? 1 : 0
        }

//        floatingViewOverlay.isHidden = !visible
//        floatingViewOverlay.floatingView?.isHidden = !visible
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Always show these views on top of everything
        bringSubviewToFront(floatingViewOverlay)
        bringSubviewToFront(navigationOverlayView)

        updateNavigationOverlayIfNeeded()
    }
    
    private func updateNavigationOverlayIfNeeded() {
        guard let viewController = UIApplication.topViewController(),
            viewController.modalPresentationStyle != UIModalPresentationStyle.popover else {
            return
        }
        
        floatingViewOverlay.updateView()

        if let vc = viewController as? ShowsNavigationOverlay,
            !viewController.isBeingDismissed,
            viewController.parent?.isBeingDismissed != true {
            
            // Update the joystick image if necessary
//            let joystickImage: NavigationJoystickViewImage = vc.joystickImage
//            switch joystickImage {
//            case .doItMyDamnSelf:
//            break // NOP - Let the VC handle its own joystick image
//            default:
//                NavigationManager.shared.navigationOverlay?.joystickImage = joystickImage
//            }
        }
        
        // Show/Hide the floating audio overlay
        NavigationManager.shared.window?.toggleFloatingViewOverlay(visible: (viewController as? ShowsNavigationOverlay)?.floatingViewOverlayShouldDisplay == true)

        // This ensures that even for modal controllers the navigation overlay should show/hide properly
        NavigationManager.shared.toggleJoystickNavigation(visible: (viewController as? ShowsNavigationOverlay)?.navigationViewShouldDisplay == true,
                                                          joystickOffset: (viewController as? ShowsNavigationOverlay)?.joystickBottomOffset ?? 0.0)
        NavigationManager.shared.navigationOverlay?.shouldShowNavigationBar = (viewController as? ShowsNavigationOverlay)?.navigationBarShouldDisplay == true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        
        windowLevel = UIWindow.Level.normal - 1
        
        addSubview(floatingViewOverlay)
        floatingViewOverlay.constrainTo(edges: .left, .top, .right)
        floatingOverlayViewBottomConstraint = floatingViewOverlay.constrainTo(edge: .bottom)
        floatingOverlayViewHeightConstraint = floatingViewOverlay.constrainHeight(0)
        floatingOverlayViewHeightConstraint?.isActive = false

        addSubview(navigationOverlayView)
        navigationOverlayView.constrainToSuperview()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    // MARK: Keyboard Notifications
    
    @objc func keyboardWillChangeFrame(_ notification: Notification) {
        performOnMainThread {
            guard let userInfo = notification.userInfo else { return }
            
            let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
            let endFrameY = endFrame.origin.y
            
            if endFrameY >= UIScreen.main.bounds.size.height {
                // Keyboard will hide
                self.toggleFloatingViewOverlay(visible: true)
            } else {
                // Keyboard will show
                self.toggleFloatingViewOverlay(visible: false)
            }
        }
    }
}
