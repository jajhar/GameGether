//
//  GGNavigationViewController.swift
//  GameGether
//
//  Created by James Ajhar on 2/13/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class GGNavigationViewController: UINavigationController {

    // MARK:- Interactive Pop Gesture
    private var percentDrivenInteractiveTransition: UIPercentDrivenInteractiveTransition?
    private(set) var panGestureRecognizer: UIPanGestureRecognizer!
    private var dismissingViewController: UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
        
        interactivePopGestureRecognizer?.delegate = nil
        setNavigationBarHidden(true, animated: false)
        addPopGesture()
    }
    
    private func addPopGesture() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        view.addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc func handlePanGesture(_ panGesture: UIPanGestureRecognizer) {
        
        let percent = max(panGesture.translation(in: view).x, 0) / view.frame.width
        
        switch panGesture.state {
            
        case .began:
            dismissingViewController = topViewController
            _ = popViewController(animated: true)
            
        case .changed:
            if let percentDrivenInteractiveTransition = percentDrivenInteractiveTransition {
                percentDrivenInteractiveTransition.update(percent)
            }
            
        case .ended:
            let velocity = panGesture.velocity(in: view).x
            
            // Continue if drag more than 50% of screen width or velocity is higher than 1000
            if percent > 0.5 || velocity > 1000 {
                percentDrivenInteractiveTransition?.finish()
                dismissingViewController = nil

            } else {
                percentDrivenInteractiveTransition?.cancel()
                restoreDismissedVCNavigationState()
            }
            
        case .cancelled, .failed:
            percentDrivenInteractiveTransition?.cancel()
            restoreDismissedVCNavigationState()

        default:
            break
        }
    }
    
    private func restoreDismissedVCNavigationState() {
        guard let vc = dismissingViewController else { return }
        updateNavigationOverlay(forViewController: vc)
        dismissingViewController = nil
    }
    
    private func updateNavigationOverlay(forViewController viewController: UIViewController) {
        NavigationManager.shared.toggleJoystickNavigation(visible: (viewController as? ShowsNavigationOverlay)?.navigationViewShouldDisplay == true,
                                                          joystickOffset: (viewController as? ShowsNavigationOverlay)?.joystickBottomOffset ?? 0.0)
        
        NavigationManager.shared.navigationOverlay?.shouldShowNavigationBar = (viewController as? ShowsNavigationOverlay)?.navigationBarShouldDisplay == true
        
        // Show/Hide the floating audio overlay
        NavigationManager.shared.window?.toggleFloatingViewOverlay(visible: (viewController as? ShowsNavigationOverlay)?.floatingViewOverlayShouldDisplay == true)
        
//        let joystickImage: NavigationJoystickViewImage = (viewController as? ShowsNavigationOverlay)?.joystickImage ?? .defaultImage
//        switch joystickImage {
//        case .doItMyDamnSelf:
//        break // NOP - Let the VC handle its own joystick image
//        default:
//            NavigationManager.shared.navigationOverlay?.joystickImage = joystickImage
//        }
        
        // Update the floating view window if needed
        NavigationManager.shared.window?.floatingViewOverlay.updateView()
    }
}

extension GGNavigationViewController: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        updateNavigationOverlay(forViewController: viewController)
        
        viewController.disableDarkMode()
    }
    
    // Fix bug when pop gesture is enabled for the root controller
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        self.interactivePopGestureRecognizer?.isEnabled = self.viewControllers.count > 1
    }
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if operation == .pop {
            return SlideAnimatedViewControllerTransition()
        }
    
        return nil
    }
    
    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {

        if panGestureRecognizer.state == .began {
            percentDrivenInteractiveTransition = UIPercentDrivenInteractiveTransition()
            percentDrivenInteractiveTransition?.completionCurve = .easeOut
        } else {
            percentDrivenInteractiveTransition = nil
        }
        
        return percentDrivenInteractiveTransition
    }
}
