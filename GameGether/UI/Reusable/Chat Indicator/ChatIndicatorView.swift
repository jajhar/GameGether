//
//  ChatIndicatorView.swift
//  GameGether
//
//  Created by James Ajhar on 10/21/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

class ChatIndicatorView: UIView {

    // MARK: Outlets
    @IBOutlet weak var firstProfileImageView: AvatarInitialsImageView!
    @IBOutlet weak var secondProfileImageView: AvatarInitialsImageView!
    @IBOutlet weak var animatedImageView: UIImageView!
    
    // MARK: Properties
    var users: [User]? {
        didSet {
            setupWithUsers()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        if let url = Bundle.main.url(forResource: "Typing", withExtension: "gif") {
            animatedImageView.sd_setImage(with: url, completed: nil)
        }
        
        firstProfileImageView.clipsToBounds = true
        secondProfileImageView.clipsToBounds = true
        
        firstProfileImageView.layer.borderWidth = 1
        firstProfileImageView.layer.borderColor = UIColor.white.cgColor
        secondProfileImageView.layer.borderWidth = 1
        secondProfileImageView.layer.borderColor = UIColor.white.cgColor

        firstProfileImageView.layer.cornerRadius = firstProfileImageView.bounds.width / 2
        secondProfileImageView.layer.cornerRadius = secondProfileImageView.bounds.width / 2
    }
    
    private func setupWithUsers() {
        guard let users = users else { return }
        
        if let user = users.first {
            firstProfileImageView.configure(withUser: user, andFont: AppConstants.Fonts.robotoRegular(16).font)
        }
        
        secondProfileImageView.isHidden = users.count <= 1

        if users.count > 1 {
            let user = users[1]
            secondProfileImageView.configure(withUser: user, andFont: AppConstants.Fonts.robotoRegular(16).font)
        }
    }
}
