//
//  UserTableViewCell.swift
//  GameGether
//
//  Created by James Ajhar on 8/8/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

protocol UserTableViewCellDelegate: class {
    func userTableViewCell(cell: UserTableViewCell, messageButtonTapped button: UIButton)
}

class UserTableViewCell: UITableViewCell {

    // MARK: Outlets
    @IBOutlet weak var userImageView: AvatarInitialsImageView!
    @IBOutlet weak var ignLabel: UILabel!
    @IBOutlet weak var userAvailabilityImageView: UserStatusImageView!
    @IBOutlet weak var availabilityLabel: UILabel!
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var checkMarkButton: UIButton!
    
    // MARK: Properties
    weak var delegate: UserTableViewCellDelegate?
    
    var user: User? {
        didSet {
            setupWithUser()
        }
    }
    
    var showsMessageButton: Bool = false {
        didSet {
            performOnMainThread {
                self.messageButton.isHidden = !self.showsMessageButton
                self.contentView.layoutIfNeeded()
            }
        }
    }
    
    var showsCheckMarkButton: Bool = false {
        didSet {
            performOnMainThread {
                self.checkMarkButton.isHidden = !self.showsCheckMarkButton
                self.checkMarkButton.isUserInteractionEnabled = false
                self.contentView.layoutIfNeeded()
            }
        }
    }
    
    var showsStatusLabel: Bool = true {
        didSet {
            performOnMainThread {
                self.userAvailabilityImageView.isHidden = !self.showsStatusLabel
                self.availabilityLabel.isHidden = !self.showsStatusLabel
            }
        }
    }

    var availabilityPrefixText: String = ""
    
    override func awakeFromNib() {
        super.awakeFromNib()

        userImageView.layer.cornerRadius = userImageView.bounds.width / 2
        userImageView.contentMode = .scaleAspectFill
        styleUI()
    }
    
    private func styleUI() {
        ignLabel.font = AppConstants.Fonts.robotoRegular(14).font
        ignLabel.layoutMargins = .zero
        availabilityLabel.font = AppConstants.Fonts.robotoLight(13).font
        availabilityLabel.textColor = UIColor(hexString: "#989898")
    }
    
    override func prepareForReuse() {
        userImageView.image = nil
        ignLabel.text = ""
        availabilityLabel.text = ""
        availabilityPrefixText = ""
    }

    private func setupWithUser() {
        guard let user = user else { return }
        userImageView.configure(withUser: user, andFont: AppConstants.Fonts.robotoRegular(16).font)
        ignLabel.attributedText = user.fullIGNText
        
        user.observeStatus { [weak self] (status, lastOnline) in
            guard let weakSelf = self else { return }
            weakSelf.userAvailabilityImageView.status = status
            
            switch status {
            case .online:
                weakSelf.availabilityLabel.text = "\(weakSelf.availabilityPrefixText)active now"
            case .away:
                weakSelf.availabilityLabel.text = "\(weakSelf.availabilityPrefixText)away"
            case .offline:
                if let lastOnline = lastOnline?.userStatusTimestampFormat() {
                    weakSelf.availabilityLabel.text = "\(weakSelf.availabilityPrefixText)\(lastOnline)"
                }
            }
        }
    }
    
    // MARK: Interface Actions
    
    @IBAction func messageButtonTapped(_ sender: UIButton) {
        delegate?.userTableViewCell(cell: self, messageButtonTapped: sender)
    }
}
