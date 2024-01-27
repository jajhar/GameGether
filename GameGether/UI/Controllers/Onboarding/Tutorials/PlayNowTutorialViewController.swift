//
//  PlayNowTutorialViewController.swift
//  GameGether
//
//  Created by James Ajhar on 11/13/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit
import FLAnimatedImage

class PlayNowTutorialViewController: UIViewController {

    enum PlayNowTutorialState {
        case bottomNav
        case playWith
        case gameTags
        case swipeNav
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var nextButton: UIButton! {
        didSet {
            nextButton.cornerRadius = 10
            nextButton.layer.borderWidth = 2
            nextButton.layer.borderColor = UIColor.white.cgColor
            nextButton.titleLabel?.font = AppConstants.Fonts.robotoMedium(17).font
        }
    }
    
    @IBOutlet weak var swipeTutorialGifImageView: FLAnimatedImageView! {
        didSet {
            swipeTutorialGifImageView.contentMode = .scaleAspectFill
            
            if let path = Bundle.main.url(forResource: "Swipe-Nav-Tutorial", withExtension: "gif"), let data = try? Data(contentsOf: path) {
                swipeTutorialGifImageView.animatedImage = FLAnimatedImage(animatedGIFData: data)
            }
        }
    }

    @IBOutlet weak var imageView: UIImageView! {
        didSet {
            imageView.image = UIDevice.current.hasNotch ? #imageLiteral(resourceName: "GG Home Onboard") : #imageLiteral(resourceName: "GG Home Onboard iPhone 6")
        }
    }
    
    // MARK: - Properties
    
    private(set) var currentState: PlayNowTutorialState = .bottomNav
    
    var onDismiss: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

//        NavigationManager.shared.toggleJoystickNavigation(visible: false)
//        NavigationManager.shared.navigationOverlay?.toggleBottomNavigationBar(visible: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if currentState == .swipeNav {
            AnalyticsManager.track(event: .onboardingSwipeTutorialSwiped)
            UserDefaults.standard.set(true, forKey: AppConstants.UserDefaults.Onboarding.ggHomeTutorialShown)
            UserDefaults.standard.synchronize()
        }
    }
    
    private func goToNextState() {
        switch currentState {
        case .bottomNav:
            imageView.image = UIDevice.current.hasNotch ? #imageLiteral(resourceName: "GG Play With Onboard") : #imageLiteral(resourceName: "GG Play With Onboard iPhone 6")
            currentState = .playWith
            
        case .playWith:
            imageView.image = UIDevice.current.hasNotch ? #imageLiteral(resourceName: "GG Game Tags Onboard") : #imageLiteral(resourceName: "GG Game Tags Onboard iPhone 6")
            currentState = .gameTags
            
        case .gameTags:
            // Tutorial done
            dismissSelf() { [weak self] in
                self?.onDismiss?()
            }
            
        case .swipeNav:
            // Tutorial done
            dismissSelf() { [weak self] in
                self?.onDismiss?()
            }
        }
    }
    
    // MARK: - Interface Actions
    
    @IBAction func nextButtonPressed(_ sender: UIButton) {

        switch currentState {
        case .bottomNav:
            AnalyticsManager.track(event: .onboardingBottomNavNextTapped)
        case .playWith:
            AnalyticsManager.track(event: .onboardingPlayWithNextTapped)
        case .gameTags:
            AnalyticsManager.track(event: .onboardingGameTagsNextTapped)
        case .swipeNav:
            // NOP - End of tutorial
            break
        }

        goToNextState()
    }
}

extension PlayNowTutorialViewController: ShowsNavigationOverlay {
    
    var navigationBarShouldDisplay: Bool {
        return false
    }
    
    var navigationViewShouldDisplay: Bool {
        return currentState == .swipeNav
    }
}
