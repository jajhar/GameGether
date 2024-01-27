//
//  GGTabBarViewController.swift
//  GameGether
//
//  Created by James Ajhar on 2/10/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

enum GGTabBarViewControllerIndex: Int {
    case profile = 0
    case home
    case chat
}

class GGTabBarViewController: UITabBarController {
    
    private(set) lazy var profileViewController: ProfileViewControllerV2 = {
        let storyboard = UIStoryboard(name: AppConstants.Storyboards.profile, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: ProfileViewControllerV2.storyboardIdentifier) as! ProfileViewControllerV2
        vc.hidesBottomBarWhenPushed = true
        return vc
    }()
    
    private(set) lazy var chatroomsViewController: ChatroomsContainerViewController = {
        let storyboard = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: ChatroomsContainerViewController.storyboardIdentifier) as! ChatroomsContainerViewController
        vc.hidesBottomBarWhenPushed = true
        return vc
    }()
    
    private(set) lazy var homeViewController: GGHomeViewController = {
        let storyboard = UIStoryboard(name: AppConstants.Storyboards.ggHome, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: GGHomeViewController.storyboardIdentifier) as! GGHomeViewController
        vc.hidesBottomBarWhenPushed = true
        return vc
    }()
    
    func setSelectedTab(_ tab: GGTabBarViewControllerIndex) {
        guard selectedIndex != tab.rawValue else {
            // this tab was already selected, pop to root (as is normal iOS tab bar behavior)
            if viewControllers?[selectedIndex].presentedViewController != nil {
                // custom behavior - pop ALL modals first
                viewControllers?[selectedIndex].dismiss(animated: true, completion: nil)
            } else {
                // No modals left to pop. pop to root controller (as is tradition)
                (viewControllers?[selectedIndex] as? UINavigationController)?.popToRootViewController(animated: true)
            }
            
            return
        }
        
        selectedIndex = tab.rawValue
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let profileNav = GGNavigationViewController(rootViewController: profileViewController)
        profileNav.view.bounds = view.bounds
        profileNav.hidesBottomBarWhenPushed = true
        profileNav.isNavigationBarHidden = true
        profileNav.view.frame = view.bounds
        profileViewController.loadViewIfNeeded()
        
        let homeNav = GGNavigationViewController(rootViewController: homeViewController)
        homeNav.hidesBottomBarWhenPushed = true
        homeNav.isNavigationBarHidden = true
        homeNav.view.frame = view.bounds
        homeViewController.loadViewIfNeeded()

        let chatNav = GGNavigationViewController(rootViewController: chatroomsViewController)
        chatNav.hidesBottomBarWhenPushed = true
        chatNav.isNavigationBarHidden = true
        chatNav.view.frame = view.bounds
        chatroomsViewController.loadViewIfNeeded()

        setViewControllers([profileNav, homeNav, chatNav], animated: false)
        
        // manually call because we are manually switching tabs to the chat screen on init and
        //  viewWillDisappear doesn't get called
        profileViewController.viewWillDisappear(false)
        profileViewController.viewDidDisappear(false)

        selectedIndex = GGTabBarViewControllerIndex.chat.rawValue
    }
}
