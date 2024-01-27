//
//  SessionNotificationBanner.swift
//  GameGether
//
//  Created by James Ajhar on 10/17/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class SessionNotificationBanner: UIView {

    // MARK: - Outlets
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.font = AppConstants.Fonts.robotoMedium(15).font
        }
    }
    
    @IBOutlet weak var subtitleLabel: UILabel! {
        didSet {
            subtitleLabel.font = AppConstants.Fonts.robotoRegular(15).font
        }
    }
    
    
    @IBOutlet weak var usersView: HorizontalAvatarsView! {
       didSet {
           usersView.spacing = -10 // overlap the views
           usersView.maxVisibleUsers = 4
       }
    }
    
    // MARK: - Properties
    
    private(set) var session: GameSession?
    
    public func configure(withSession session: GameSession) {
        self.session = session
        usersView.users = session.attendees
        
        layoutIfNeeded()
    }
}
