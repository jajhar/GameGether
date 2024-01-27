//
//  FriendOnlineNotificationBanner.swift
//  GameGether
//
//  Created by James Ajhar on 2/3/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class FriendOnlineNotificationBanner: UIView {

    // MARK: Outlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var userImageView: AvatarInitialsImageView!
    
    // MARK: Properties
    var user: User? {
        didSet {
            setupWithUser()
        }
    }
    
    private func setupWithUser() {
        guard let user = user else { return }

        userImageView.configure(withUser: user, andFont: AppConstants.Fonts.robotoRegular(16).font)
        setupTitleLabel()
        setupSubtitleLabel()
        layoutIfNeeded()
    }
    
    private func setupTitleLabel() {
        guard let user = user else { return }

        let attributedString = NSMutableAttributedString(string: user.ign)
        attributedString.addAttribute(.foregroundColor, value: UIColor.black, range: attributedString.fullRange)
        
        let loginAttributedtext = NSAttributedString(string: " is now online",
                                                     attributes: [.foregroundColor: UIColor(hexString: "#BDBDBD")])
        attributedString.append(loginAttributedtext)
        attributedString.addAttribute(.font, value: AppConstants.Fonts.robotoLight(12.0).font, range: attributedString.fullRange)
        
        titleLabel.attributedText = attributedString
    }
    
    private func setupSubtitleLabel() {
        guard let user = user else { return }
        subtitleLabel.text = user.tagline
    }
    
    // MARK: Interface Actions

    @IBAction func chatButtonPressed(_ sender: UIButton) {
        //TODO:
    }
}
