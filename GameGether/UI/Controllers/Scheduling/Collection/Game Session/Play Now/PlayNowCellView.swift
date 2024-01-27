//
//  PlayNowCellView.swift
//  GameGether
//
//  Created by James Ajhar on 11/1/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class PlayNowCellView: UIView {

    // MARK: - Outlets
    @IBOutlet weak var gameImageView: UIImageView!

    @IBOutlet weak var gameIconShadowView: UIView! {
        didSet {
            gameIconShadowView.cornerRadius = 15
            gameIconShadowView.addDropShadow(color: .black, opacity: 0.15, offset: CGSize(width: 1, height: 1), radius: 2)
        }
    }

    @IBOutlet weak var favoriteIcon: UIImageView!
    
    @IBOutlet weak var tagsCollectionView: TagsDisplayCollectionView! {
        didSet {
            tagsCollectionView.cellHeight = 15
            tagsCollectionView.cellPadding = 2
            tagsCollectionView.cellFont = AppConstants.Fonts.robotoBold(11).font
            
            tagsCollectionView.onReload = { [weak self] in
                guard let weakSelf = self else { return }
                // Resize to fit content
                weakSelf.tagsCollectionHeightConstraint.constant = weakSelf.tagsCollectionView.collectionViewLayout.collectionViewContentSize.height
                weakSelf.layoutIfNeeded()
            }
        }
    }
    @IBOutlet weak var tagsCollectionHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var chatBubbleImageView: UIImageView!

    @IBOutlet weak var chatTextView: UITextViewNoPadding! {
        didSet {
            chatTextView.textContainer.maximumNumberOfLines = 2
            chatTextView.textContainer.lineBreakMode = .byTruncatingTail
            chatTextView.font = AppConstants.Fonts.robotoMedium(12).font
        }
    }
    
    @IBOutlet weak var avatarsView: HorizontalAvatarsView! {
        didSet {
            avatarsView.maxVisibleUsers = 4
            avatarsView.spacing = -10
            avatarsView.showRemainingUserCounter = false
            avatarsView.alignment = .left
        }
    }
    
    @IBOutlet weak var joinButton: UIButton! {
        didSet {
            joinButton.borderWidth = 1
            joinButton.borderColor = .black
            joinButton.setTitleColor(.black, for: .normal)
            joinButton.titleLabel?.font = AppConstants.Fonts.robotoRegular(13).font
            joinButton.setBackgroundImage(#imageLiteral(resourceName: "TimeButton"), for: .normal)
            joinButton.addTarget(self, action: #selector(joinButtonPressed(_:)), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var shadowView: UIView! {
        didSet {
            shadowView.addDropShadow(color: .black, opacity: 0.15, offset: CGSize(width: 0, height: 1), radius: 2)
        }
    }
    
    // MARK: - Properties
    
    var lobby: ActiveLobby?
    
    var onJoinPressed: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

    }
    
    public func configure(withLobby lobby: ActiveLobby) {
        self.lobby = lobby
        
        gameImageView.sd_setImage(with: lobby.game?.iconImageURL, completed: nil)
        
        if lobby.messageMediaURL != nil {
            chatTextView.text = "sent a gif"
        } else {
            chatTextView.text = lobby.lastMessage
        }
        
        if let user = lobby.lastMessageUser {
            avatarsView.users = [user] + lobby.users
        } else {
            avatarsView.users = lobby.users
        }
        
        if lobby.tags.isEmpty {
            // General Lobby
            let generalLobbyTag = TagObject(withIdentifier: "General_Lobby", title: "General Lobby", type: .gameMode)
            tagsCollectionView.tags = [generalLobbyTag]
        } else {
            tagsCollectionView.tags = lobby.tags
        }
        
        chatBubbleImageView.tintColor = UIColor(hexString: lobby.game?.headerColor ?? "")
        favoriteIcon.isHidden = !lobby.isFavorited

        layoutIfNeeded()
    }
    
    func prepareForReuse() {
        lobby = nil
        avatarsView.prepareForReuse()
        gameImageView.sd_cancelCurrentImageLoad()
        gameImageView.image = nil
        tagsCollectionView.tags = []
        onJoinPressed = nil
        chatTextView.text = nil
        chatBubbleImageView.tintColor = .black
        favoriteIcon.isHidden = true
    }
    
    @objc func joinButtonPressed(_ sender: UIButton) {
        onJoinPressed?()
    }
}
