//
//  MessageTableViewCell.swift
//  GameGether
//
//  Created by James Ajhar on 8/4/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit
import FLAnimatedImage

class MessageTableViewCell: UITableViewCell {
    
    // MARK: Outlets
    @IBOutlet weak var userImageView: AvatarInitialsImageView!
    @IBOutlet weak var userImageShadowView: UIView! {
        didSet {
            userImageShadowView.addDropShadow(color: .black, opacity: 0.15, offset: CGSize(width: 1, height: 5), radius: 5)
        }
    }
    
    @IBOutlet weak var blockedUserView: UIView! {
        didSet {
            let blurEffect = UIBlurEffect(style: .extraLight)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.translatesAutoresizingMaskIntoConstraints = false
            blockedUserView.addSubview(blurEffectView)
            blockedUserView.sendSubviewToBack(blurEffectView)
            blurEffectView.constrainToSuperview()
            blockedUserView.layoutIfNeeded()
        }
    }
    @IBOutlet weak var blockedUsersViewTitleLabel: UILabel! {
        didSet {
            blockedUsersViewTitleLabel.font = AppConstants.Fonts.robotoLight(14).font
            blockedUsersViewTitleLabel.textColor = UIColor(hexString: "#ACACAC")
        }
    }
    
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet var messageTextViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var ignLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var topOffsetConstraint: NSLayoutConstraint!
    @IBOutlet var userImageBottomOffsetConstraint: NSLayoutConstraint!
    
    // Media (gifs, images, etc...) Only supports gifs currently.
    @IBOutlet weak var mediaImageView: FLAnimatedImageView!
    @IBOutlet weak var mediaImageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var mediaImageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet var mediaImageViewBottomConstraint: NSLayoutConstraint!
    
    // MARK: Properties
    var onUserTapped: ((User, MessageTableViewCell) -> Void)?
    
    private(set) var message: FRMessage?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        userImageView.layer.cornerRadius = userImageView.bounds.width / 2
        userImageShadowView.layer.cornerRadius = userImageShadowView.bounds.width / 2
        styleUI()
    }
    
    private func styleUI() {
        ignLabel.font = AppConstants.Fonts.robotoRegular(14).font
        messageTextView.font = AppConstants.Fonts.robotoLight(14).font
        dateLabel.font = AppConstants.Fonts.robotoLight(12).font
        dateLabel.textColor = UIColor(hexString: "#bdbdbd")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        message = nil
        
        userImageView.sd_cancelCurrentImageLoad()
        userImageView.image = nil
        userImageView.initialsLabel.text = nil
        
        ignLabel.text = ""
        messageTextView.text = ""
        dateLabel.text = ""
        
        mediaImageView.sd_cancelCurrentImageLoad()
        mediaImageView.image = nil
        mediaImageView.animatedImage = nil
        
        mediaImageViewBottomConstraint.isActive = false
        messageTextViewBottomConstraint.isActive = true
        
        blockedUserView.isHidden = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.bringSubviewToFront(blockedUserView)
    }
    
    public func setupWithMessage(_ message: FRMessage, andChatroom chatroom: FRChatroom? = nil, simplified: Bool = false) {
        self.message = message
        
        blockedUserView.isHidden = true
        
        if let user = DataCoordinator.shared.signedInUser, user.identifier == message.createdBy {
            userImageView.configure(withUser: user, andFont: AppConstants.Fonts.robotoRegular(16).font)
       
        } else {
            DataCoordinator.shared.getProfile(forUser: message.createdBy) { [weak self] (user, error) in
                guard self?.message?.identifier == message.identifier, error == nil, let user = user else { return }
                performOnMainThread {
                    self?.userImageView.configure(withUser: user, andFont: AppConstants.Fonts.robotoRegular(16).font)
                    self?.setBlockedStatus(forUser: user, simplified: simplified)
                }
            }
        }
        
        if !simplified {
            ignLabel.text = message.fromUserName
            dateLabel.text = message.createdAt.ggTimestampFormat()
        }
        
        userImageView.isHidden = simplified
        userImageShadowView.isHidden = simplified
        topOffsetConstraint.constant = simplified ? 0 : 8
        userImageBottomOffsetConstraint.isActive = !simplified
//        messageTextViewBottomConstraint.constant = simplified ? 0 : 9
//        mediaImageViewBottomConstraint.constant = simplified ? 0 : 9
        
        switch message.type {
        case .message:
            messageTextView.text = message.text
            mediaImageViewBottomConstraint.isActive = false
            messageTextViewBottomConstraint.isActive = true

        case .media:
            if let gif = message.gif {
                mediaImageView.sd_setImage(with: gif.mediaURL, completed: nil)
                mediaImageViewWidthConstraint.constant = gif.size.width
                mediaImageViewHeightConstraint.constant = gif.size.height
                mediaImageViewBottomConstraint.isActive = true
                messageTextViewBottomConstraint.isActive = false
            }
        default:
            break
        }
        
        contentView.layoutIfNeeded()
    }
    
    private func setBlockedStatus(forUser user: User, simplified: Bool) {
        
        guard user.relationship?.status == .blocked else {
            blockedUserView.isHidden = true
            return
        }
        
        blockedUserView.isHidden = false
        
        // Don't show the blocked title text if we're in a simplified state
        blockedUsersViewTitleLabel.isHidden = simplified
        
        if user.relationship?.creator == DataCoordinator.shared.signedInUser?.identifier {
            blockedUsersViewTitleLabel.text = "This user has been blocked"
        } else {
            blockedUsersViewTitleLabel.text = "This user has blocked you"
        }
    }
    
    @IBAction func AvatarTapped(_ sender: UIButton) {
        guard let userId = message?.createdBy, !userId.isEmpty else { return }
        let user = UserObject(identifier: userId)
        
        guard onUserTapped == nil else {
            onUserTapped?(user, self)
            return
        }
        
        // Default is show profile for user
        let viewController = UIStoryboard(name: AppConstants.Storyboards.profile, bundle: nil).instantiateViewController(withIdentifier: ProfileViewControllerV2.storyboardIdentifier) as! ProfileViewControllerV2
        viewController.user = user
        NavigationManager.shared.push(viewController)
    }
}
