//
//  ChatMessageNotificationBanner.swift
//  GameGether
//
//  Created by James Ajhar on 1/13/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class ChatMessageNotificationBanner: UIView {

    // MARK: Outlets
    @IBOutlet weak var userImageView: AvatarInitialsImageView!
    @IBOutlet weak var messageLabel: UILabel!
    
    // MARK: Properties
    var user: User? {
        didSet {
            setupWithUser()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        messageLabel.font = AppConstants.Fonts.robotoRegular(15).font
    }

    private func setupWithUser() {
        guard let user = user else { return }
        
        userImageView.configure(withUser: user, andFont: AppConstants.Fonts.robotoRegular(16).font)
    }
}
