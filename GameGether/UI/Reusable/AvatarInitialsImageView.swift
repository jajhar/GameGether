//
//  AvatarInitialsImageView.swift
//  GameGether
//
//  Created by James Ajhar on 8/13/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class AvatarInitialsImageView: UIImageView {

    let initialsLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        addSubview(initialsLabel)
        initialsLabel.constrainToSuperview()
        layoutIfNeeded()
    }
    
    public func configure(withUser user: User, andFont font: UIFont) {
        initialsLabel.font = font
        
        initialsLabel.text = user.initials
        
        initialsLabel.isHidden = user.profileImageURL != nil

        if let url = user.profileImageURL {
            sd_setImage(with: url, placeholderImage: #imageLiteral(resourceName: "Pastel Green #66CC33"), options: [], completed: nil)
        
        } else {
            sd_setImage(with: user.profileImageColoredBackgroundURL, placeholderImage: #imageLiteral(resourceName: "Pastel Green #66CC33"), options: [], completed: nil)
        }
    }
}

class AvatarInitialsButton: UIButton {
    
    let initialsLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        addSubview(initialsLabel)
        initialsLabel.constrainToSuperview()
        layoutIfNeeded()
    }
    
    public func configure(withUser user: User, andFont font: UIFont) {
        initialsLabel.font = font
        
        initialsLabel.text = user.initials
        sd_setImage(with: user.profileImageURL, for: .normal, placeholderImage: #imageLiteral(resourceName: "Pastel Green #66CC33"), options: []) { (image, error, _, _) in
            performOnMainThread {
                self.initialsLabel.isHidden = image != nil
            }
        }
    }
}

