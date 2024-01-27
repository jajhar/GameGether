//
//  ShowsNavigationOverlay.swift
//  GameGether
//
//  Created by James Ajhar on 2/13/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import Foundation
import UIKit

protocol ShowsNavigationOverlay {
    // NOP - If a view controller conforms to this protocol, it will display the joystick navigation overlay.
    // Logic for handling the display of this can be found in FloatingViewWindow
    
    /// How far from the bottom the AI button should be. 0.0 == default offset
    var joystickBottomOffset: CGFloat { get }
    
    /// true if the navigation view should display on view appear
    var navigationViewShouldDisplay: Bool { get }
    
    // true if the bottom nav bar should display on this view
    var navigationBarShouldDisplay: Bool { get }
    
    var joystickImage: NavigationJoystickViewImage { get }
    
    /// true if the floating overlay view should display on view appear
    var floatingViewOverlayShouldDisplay: Bool { get }
}

extension ShowsNavigationOverlay {
    var joystickBottomOffset: CGFloat {
        // default implementation
        return 0.0
    }
    
    var navigationViewShouldDisplay: Bool {
        return true // true by default
    }
    
    var floatingViewOverlayShouldDisplay: Bool {
        return navigationViewShouldDisplay
    }
    
    var navigationBarShouldDisplay: Bool {
        return true
    }
    
    var joystickImage: NavigationJoystickViewImage {
        return .defaultImage
    }
}

extension ChatViewController: ShowsNavigationOverlay { }
extension TagsChatViewController: ShowsNavigationOverlay { }
extension GameTagsViewController: ShowsNavigationOverlay { }
extension FriendsViewController: ShowsNavigationOverlay { }

