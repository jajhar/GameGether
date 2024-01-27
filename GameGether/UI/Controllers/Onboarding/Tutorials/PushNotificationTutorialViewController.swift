//
//  PushNotificationTutorialViewController.swift
//  GameGether
//
//  Created by James Ajhar on 11/13/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class PushNotificationTutorialViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var nextButton: UIButton! {
        didSet {
            nextButton.titleLabel?.font = AppConstants.Fonts.robotoMedium(15).font
        }
    }
    
    // MARK: - Properties
    var onDismiss: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    // MARK: - Interface Actions
    
    @IBAction func nextButtonPressed(_ sender: UIButton) {
        AnalyticsManager.track(event: .onboardingNotificationsNextTapped)
        PushNotificationsManager.shared.registerForRemoteNotifications()
        dismissSelf(animated: true) { [weak self] in
            self?.onDismiss?()
        }
    }
}
