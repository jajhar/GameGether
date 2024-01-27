//
//  WelcomePageOneViewController.swift
//  GameGether
//
//  Created by James Ajhar on 6/20/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

class OnboardingPageOneViewController: UIViewController {

    @IBOutlet weak var playerView: AVPlayerView! {
        didSet {
            guard let path = Bundle.main.path(forResource: "onboarding_video", ofType: "mp4") else {
                GGLog.error("Failed to load onboarding video")
                return
            }
            
            let url = URL(fileURLWithPath: path)
            
            playerView.shouldShowControls = false
            playerView.forceSoundOn = true
            playerView.configurePlayer(withURL: url, videoGravity: .resizeAspect)
            playerView.player.actionAtItemEnd = .pause
            playerView.play()
        }
    }
    
    @IBOutlet weak var loginButtonsBackgroundView: UIView! {
        didSet {
            loginButtonsBackgroundView.cornerRadius = 14
            loginButtonsBackgroundView.addDropShadow(color: .black, opacity: 0.17, offset: CGSize(width: 0, height: 3), radius: 3)
        }
    }
    
    @IBOutlet weak var exploreButton: UIButton! {
        didSet {
            exploreButton.titleLabel?.font = AppConstants.Fonts.robotoMedium(18).font
        }
    }
    
    @IBOutlet weak var existingUserButton: UIButton! {
        didSet {
            existingUserButton.titleLabel?.font = AppConstants.Fonts.robotoMedium(18).font
        }
    }
    
    // MARK: - Properties
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Reset onboarding flags
        UserDefaults.standard.set(false, forKey: AppConstants.UserDefaults.Onboarding.gameTagsOnboardingTooltipShown)
        UserDefaults.standard.set(false, forKey: AppConstants.UserDefaults.Onboarding.tagsChatOnboardingTooltipShown)
        UserDefaults.standard.synchronize()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        playerView.stop()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        view.layoutIfNeeded()
        exploreButton.roundCorners(corners: [.topLeft, .bottomLeft], radius: 14)
        existingUserButton.roundCorners(corners: [.topRight, .bottomRight], radius: 14)
    }

    // MARK: - Interface Actions

    @IBAction func loginButtonPressed(_ sender: Any) {
        AnalyticsManager.track(event: .onboardingSignInPressed)
        
        let viewController = UIStoryboard(name: AppConstants.Storyboards.onboarding, bundle: nil).instantiateViewController(withIdentifier: RegisterUserViewController.storyboardIdentifier) as! RegisterUserViewController
        viewController.state = .existingUser
        let nav = GGNavigationViewController(rootViewController: viewController)
        NavigationManager.shared.present(nav)
    }
    
    @IBAction func exploreButtonPressed(_ sender: Any) {
        AnalyticsManager.track(event: .onboardingExplorePressed)
        NavigationManager.shared.showMainView()
    }
}
