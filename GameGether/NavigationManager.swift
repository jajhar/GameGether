//
//  NavigationManager.swift
//  GameGether
//
//  Created by James Ajhar on 8/6/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

class NavigationManager {
    
    static let shared: NavigationManager = NavigationManager()

    private(set) var tabBarController: GGTabBarViewController?
    
    weak var window: FloatingViewWindow?
    
    var navigationOverlay: NavigationOverlayView? {
        return window?.navigationOverlayView
    }
    
    /// Call to get the highest level view controller in the UI stack
    ///
    /// - Parameter controller: The root view controller to start at. Defaults to app's root view controller.
    /// - Returns: The top level view controller in the app
    static func topMostViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        guard controller?.modalPresentationStyle != .popover else {
            // Ignore popover views
            return nil
        }
        if let presented = controller?.presentedViewController, presented.modalPresentationStyle != .popover {
            // Check for modal controllers first (non-popover)
            return topMostViewController(controller: presented) ?? controller
        } else if let navigationController = controller as? UINavigationController {
            // Check for navigation controllers
            return topMostViewController(controller: navigationController.visibleViewController) ?? navigationController.topViewController
        } else if let tabController = controller as? UITabBarController, let selected = tabController.selectedViewController {
            // Check for tab bar controllers
            return topMostViewController(controller: selected) ?? selected
        }
        return controller
    }
    
    /// Call to display or hide the voice chat overlay view on top of the application window
    ///
    /// - Parameters:
    ///   - visible: true if it should be visible
    ///   - chatroom: The chatroom where the voice chat is taking place.
    func toggleActiveCallView(visible: Bool, forChatroom chatroom: FRChatroom? = nil) {

        if visible {
            guard FloatingAudioView.activeView == nil else { return }
            
            window?.floatingView?.removeFromSuperview()
            let nib = UINib(nibName: "\(FloatingAudioView.self)", bundle: nil)
            let view = nib.instantiate(withOwner: window, options: nil).first as? FloatingAudioView
            view?.translatesAutoresizingMaskIntoConstraints = false
            view?.chatroom = chatroom
            window?.floatingView = view
            FloatingAudioView.activeView = view
            
        } else {
            guard FloatingAudioView.activeView != nil else { return }

            // Make a copy of the reference for animation completion purposes
            var floatingView = window?.floatingView
            FloatingAudioView.activeView = nil
            window?.floatingView = nil
            
            UIView.animate(withDuration: 0.3, animations: {
                floatingView?.alpha = 0.0
            }) { (_) in
                floatingView?.removeFromSuperview()
                floatingView = nil
            }
        }
    }
    
    func toggleJoystickNavigation(visible: Bool, joystickOffset: CGFloat = 0.0) {
        UIView.animate(withDuration: 0.3) {
            self.navigationOverlay?.alpha = visible ? 1.0 : 0.0
            self.navigationOverlay?.setJoystickBottomOffset(to: joystickOffset)
        }
    }
    
    func setViewControllers(_ viewControllers: [UIViewController], animated: Bool = true) {
        UIApplication.topViewController()?.navigationController?.setViewControllers(viewControllers, animated: animated)
    }
    
    func present(_ viewController: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        
         if #available(iOS 13.0, *) {
            if viewController.modalPresentationStyle == .pageSheet {
                 viewController.modalPresentationStyle = .fullScreen
             }
         }

        viewController.disableDarkMode()
        
        UIApplication.topViewController()?.present(viewController, animated: animated, completion: completion)
    }
    
    func push(_ viewController: UIViewController, animated: Bool = true) {
        
        viewController.disableDarkMode()
        
        let topController = UIApplication.topViewController()
        
        if topController?.modalPresentationStyle == .popover {
            topController?.dismiss(animated: false, completion: {
                UIApplication.topViewController()?.navigationController?.pushViewController(viewController, animated: animated)
            })
        } else {
            topController?.navigationController?.pushViewController(viewController, animated: animated)
        }
    }
    
    func popViewController(animated: Bool = true) {
        let topController = UIApplication.topViewController()
        topController?.dismissSelf()
    }
    
    func showMainView() {
        guard let window = window else { return }
        
        navigationOverlay?.beginObservingUnreadMessageCount()
        toggleJoystickNavigation(visible: true)

        let storyboard = UIStoryboard(name: AppConstants.Storyboards.tabBar, bundle: nil)
        tabBarController = storyboard.instantiateViewController(withIdentifier: GGTabBarViewController.storyboardIdentifier) as? GGTabBarViewController
        
        // Animate the tab bar controller in
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
        UIView.transition(with: window,
                          duration: 0.3,
                          options: .transitionCrossDissolve,
                          animations: nil) { (_) in
            window.navigationOverlayView.joyStickView.resetJoystick()
        }
        
        window.navigationOverlayView.updateProfileButtonImage()
                
        // Default to showing GG Home screen
        window.navigationOverlayView.setSelectedTab(.home)
        
        window.navigationOverlayView.joyStickView.resetJoystick()
        
        // Make the joystick hover for a bit
//        NavigationManager.shared.navigationOverlay?.joyStickView.addHoverAnimation(duration: 1, distance: -7, repeatCount: 2)
    }
    
    func showOnboarding() {
        guard let window = window else { return }
        
        toggleJoystickNavigation(visible: false)

        let onboardingStoryboard = UIStoryboard(name: AppConstants.Storyboards.onboarding, bundle: nil)
        let vc = onboardingStoryboard.instantiateInitialViewController()
        
        window.rootViewController = vc
        window.makeKeyAndVisible()
        UIView.transition(with: window,
                          duration: 0.3,
                          options: .transitionCrossDissolve,
                          animations: nil,
                          completion: nil)
    }
    
    func setSelectedTab(_ tab: GGTabBarViewControllerIndex) {
        tabBarController?.setSelectedTab(tab)
    }
}
