//
//  GameSessionCollectionViewCell.swift
//  GameGether
//
//  Created by James Ajhar on 9/10/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class GameSessionView: UIView {
    
    // MARK: - Outlets
    @IBOutlet weak var gameImageView: UIImageView!
    
    @IBOutlet weak var gameIconShadowView: UIView! {
        didSet {
            gameIconShadowView.cornerRadius = 15
            gameIconShadowView.addDropShadow(color: .black, opacity: 0.15, offset: CGSize(width: 1, height: 1), radius: 2)
        }
    }
    
    // Request Types
    @IBOutlet weak var requestInfoView: UIView!
    @IBOutlet weak var requestUserImageView: AvatarInitialsImageView!
    @IBOutlet weak var unreadLabel: UILabel!
    
    @IBOutlet weak var requestUserShadowView: UIView! {
        didSet {
            requestUserShadowView.cornerRadius = 17.5
            requestUserShadowView.addDropShadow(color: .black, opacity: 0.15, offset: CGSize(width: 1, height: 1), radius: 2)
        }
    }
    @IBOutlet weak var requestTextView: UITextView! {
        didSet {
            requestTextView.clipsToBounds = false
        }
    }
    
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

    @IBOutlet weak var gameBackgroundImageView: UIImageView!
    
    @IBOutlet weak var avatarsView: HorizontalAvatarsView! {
        didSet {
            avatarsView.maxVisibleUsers = 10
            avatarsView.spacing = -10
            avatarsView.showRemainingUserCounter = true
        }
    }
        
    @IBOutlet weak var shadowView: UIView! {
        didSet {
            shadowView.addDropShadow(color: .black, opacity: 0.3, offset: CGSize(width: 2, height: 2), radius: 2)
        }
    }
    
    @IBOutlet weak var messageIGNLabel: UILabel! {
        didSet {
            messageIGNLabel.font = AppConstants.Fonts.robotoRegular(13).font
        }
    }
    
    @IBOutlet weak var messageLabel: UILabel! {
        didSet {
            messageLabel.font = AppConstants.Fonts.robotoLight(13).font
        }
    }
    
    @IBOutlet weak var messageTimestampLabel: UILabel! {
        didSet {
            messageTimestampLabel.font = AppConstants.Fonts.robotoLight(10).font
            messageTimestampLabel.textColor = UIColor(hexString: "#ACACAC")
        }
    }
    
    // MARK: - Properties
    
    private let firebaseChat = FirebaseChat()
    
    var session: GameSession? {
        didSet {
            setupWithSession()
        }
    }
    
    var onJoinPressed: ((GameSession) -> Void)?
    var onLeavePressed: ((GameSession) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

    }
    
    func prepareForReuse() {
        avatarsView.prepareForReuse()
        session = nil
        gameImageView.sd_cancelCurrentImageLoad()
        gameImageView.image = nil
        gameBackgroundImageView.sd_cancelCurrentImageLoad()
        gameBackgroundImageView.image = nil
        tagsCollectionView.tags = []
        onJoinPressed = nil
        onLeavePressed = nil
        
        messageLabel.text = nil
        messageIGNLabel.text = nil
        messageTimestampLabel.text = nil
    }
    
    public func configureForHeightCalculation(session: GameSession) {
        // Only do the bare minimum to calculate the height of this view
        configureDescriptionText(forSession: session)
        tagsCollectionView.tags = session.tags
    }

    private func setupWithSession() {
        guard let session = session else { return }
        
        configureView(forSession: session)
        configureDescriptionText(forSession: session)
        
        gameImageView.sd_setImage(with: session.game?.iconImageURL, completed: nil)
        
        tagsCollectionView.tags = session.tags
        avatarsView.users = session.attendees
        
        fetchFirstMessage()
        
        observeUnreadMessageCount()
    }
    
    private func configureDescriptionText(forSession session: GameSession) {
        // extra big ass indent here
        requestTextView.text = "            \(session.description)"
    }
    
    private func configureView(forSession session: GameSession) {
        guard let sessionType = session.sessionType else { return }
        
        switch sessionType.type {
        case .gameMode:
            requestInfoView.isHidden = true
            gameBackgroundImageView.sd_setImage(with: session.sessionType?.imageURL ?? session.game?.tagThemeImageURL, completed: nil)

        case .request:
            requestInfoView.isHidden = false
            
            if let user = session.createdBy {
                requestUserImageView.configure(withUser: user, andFont: AppConstants.Fonts.robotoMedium(12).font)
            }
            
            if let color = session.game?.headerColor {
                gameBackgroundImageView.backgroundColor = UIColor(hexString: color)
                gameBackgroundImageView.image = nil
            }
        }
    }
    
    private func observeUnreadMessageCount() {
        guard let chatroomId = session?.chatroomId else { return }
        
        firebaseChat.signIn { [weak self] (result, error) in
            guard let weakSelf = self else { return }
            
            weakSelf.firebaseChat.observeUnreadMessageCount(forChatroom: chatroomId) { (unreadCount) in
                guard weakSelf.session?.chatroomId == chatroomId else {
                    // cell reuse check
                    return
                }

                weakSelf.updateUnreadCount(unreadCount)
            }
        }
    }
    
    private func updateUnreadCount(_ newCount: Int) {
        
        guard newCount > 0 else {
            unreadLabel.isHidden = true
            return
        }
        
        unreadLabel.isHidden = false
        
        if newCount > 99 {
            unreadLabel.text = "99"
        } else {
            unreadLabel.text = "\(newCount)"
        }
    }

    private func fetchFirstMessage() {
        guard let chatroomId = session?.chatroomId, let signedInUser = DataCoordinator.shared.signedInUser else { return }

        firebaseChat.signIn { [weak self] (result, error) in
            self?.firebaseChat.fetchMessages(forChatroom: chatroomId, limit: 1) { (messages) in
                performOnMainThread {
                    
                    guard self?.session?.chatroomId == chatroomId else {
                        // cell reuse check
                        return
                    }
                                        
                    guard let message = messages.first else {
                        self?.messageLabel.text = ""
                        return
                    }
                    
                    self?.messageIGNLabel.text = message.fromUserName
                    
                    switch message.type {
                    case .message:
                        self?.messageLabel.text = message.text
                    case .media:
                        self?.messageLabel.text = "sent a gif"
                    case .chatroomNameUpdated:
                        
                        if message.createdBy == signedInUser.identifier {
                            self?.messageLabel.text = "you named the group \(message.text)"
                        } else {
                            self?.messageLabel.text = "\(message.fromUserName) named the group \(message.text)"
                        }
                        
                    case .chatroomImageUpdated:
                        
                        if message.createdBy == signedInUser.identifier {
                            self?.messageLabel.text = "you changed the group photo"
                        } else {
                            self?.messageLabel.text = "\(message.fromUserName) changed the group photo"
                        }
                        
                    case .sentFriendRequest:
                                                    
                        if message.createdBy == signedInUser.identifier {
                            // Sent this friend request
                            self?.messageLabel.text = "you sent a friend request"
                        } else {
                            // Received this friend request
                            self?.messageLabel.text = "you received a friend request"
                        }

                    case .friendRequestAccepted:
                        self?.messageLabel.text = "you are now friends"
                    case .cancelledFriendRequest:
                        if message.createdBy == signedInUser.identifier {
                            self?.messageLabel.text = "you cancelled a friend request"
                        } else {
                            self?.messageLabel.text = "\(message.fromUserName) cancelled a friend request"
                        }
                        
                    case .leftChatroom, .addedToChatroom:
                        self?.messageLabel.text = message.text
                        
                    case .createdParty:
                        self?.messageLabel.text = "a party was created"
                        
                    case .createdPartyNotification:
                        self?.messageLabel.text = "\(message.text)"
                        
                    case .micTurnedOff, .micTurnedOn:
                        let micActionString = message.type == .micTurnedOn ? "joined call" : "left call"
                        
                        if message.createdBy == signedInUser.identifier {
                            self?.messageLabel.text = "you \(micActionString)"
                        } else {
                            self?.messageLabel.text = "\(message.fromUserName) \(micActionString)"
                        }
                        
                    case .sessionCreated:
                        self?.messageLabel.text = "\(message.text)"
                    }
                    
                    self?.messageTimestampLabel.text = message.createdAt.ggTimestampFormat()
                    
                    // Bring last message user to left of avatars view
                    self?.avatarsView.pushUserToBack(userId: message.createdBy, animated: true)
                    self?.layoutIfNeeded()
                }
            }
        }
    }
}
