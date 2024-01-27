//
//  UIAlertController+Extensions.swift
//  GameGether
//
//  Created by James Ajhar on 5/17/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

extension UIAlertController {
    
    /// This is a fancy way of showing alerts so that our Floating View Overlay works well with alerts and action sheets
    ///
    /// - Parameter animated: true if animated
    func show(animated: Bool = true) {
        
        if #available(iOS 13.0, *) {
            NavigationManager.shared.present(self)
            return
        }
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.windowLevel = UIWindow.Level.alert
        window.isHidden = false
        window.rootViewController?.present(self, animated: animated, completion: nil)
    }
}
