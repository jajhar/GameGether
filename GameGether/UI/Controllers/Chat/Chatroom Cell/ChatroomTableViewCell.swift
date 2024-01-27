//
//  ChatroomTableViewCell.swift
//  GameGether
//
//  Created by James Ajhar on 7/29/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

class ChatroomTableViewCell: UITableViewCell {

    // MARK: Outlets
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var ignLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var unreadLabel: UILabel!
    @IBOutlet weak var userStatusImageView: UserStatusImageView!
    @IBOutlet weak var multiAvatarView: MultiAvatarView!
    @IBOutlet weak var chatroomImageView: UIImageView!
    @IBOutlet weak var checkMarkImageView: UIImageView!
    
    // Selection Checkmark
    @IBOutlet weak var checkMarkWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var checkMarkLeadingConstraint: NSLayoutConstraint!
    
    private(set) var firebaseChat = FirebaseChat()
    
    // MARK: Properties
    var chatroom: FRChatroom? {
        didSet {
            setupWithChatroom()
        }
    }
    
    /// true if the selection checkmark should be visible
    var allowsSelection: Bool = false {
        didSet {
            // show/hide the checkmark selection view
            checkMarkWidthConstraint.constant = allowsSelection ? 30.0 : 0.0
            checkMarkLeadingConstraint.constant = allowsSelection ? 13.0 : 0.0
        }
    }
    
    var isChatroomSelected: Bool = false {
        didSet {
            checkMarkImageView.image = isChatroomSelected ? #imageLiteral(resourceName: "GreenCheckMark") : #imageLiteral(resourceName: "GreenCheckMarkGray")
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        unreadLabel.isHidden = true
        unreadLabel.layer.cornerRadius = 5.0
        chatroomImageView.layer.cornerRadius = chatroomImageView.bounds.width / 2
        
        styleUI()
    }
    
    private func styleUI() {
        ignLabel.font = AppConstants.Fonts.robotoRegular(14).font
        dateLabel.font = AppConstants.Fonts.robotoLight(12).font
        dateLabel.textColor = UIColor(hexString: "#bdbdbd")
        unreadLabel.font = AppConstants.Fonts.robotoMedium(11).font
        messageLabel.font = AppConstants.Fonts.robotoLight(14).font
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        ignLabel.text = ""
        messageLabel.text = ""
        dateLabel.text = ""
        unreadLabel.text = ""
        unreadLabel.isHidden = true
        multiAvatarView.prepareForReuse()
        chatroomImageView.image = nil
        firebaseChat = FirebaseChat()
    }

    private func setupWithChatroom() {
        guard let chatroom = chatroom, let signedInUser = DataCoordinator.shared.signedInUser else { return }
        
        userStatusImageView.isHidden = chatroom.isGroupChat
        
        chatroom.fetchUsers { [weak self] (users) in
            
            guard let weakSelf = self else { return }
            
            guard weakSelf.chatroom?.identifier == chatroom.identifier else {
                // cell reuse check
                return
            }

            performOnMainThread {
                
                if let imageURL = chatroom.imageURL {
                    weakSelf.multiAvatarView.isHidden = true
                    weakSelf.chatroomImageView.isHidden = false
                    weakSelf.chatroomImageView.sd_setImage(with: imageURL, completed: nil)
                } else {
                    weakSelf.multiAvatarView.isHidden = false
                    weakSelf.multiAvatarView.users = users ?? []
                    weakSelf.chatroomImageView.isHidden = true
                }

                if let name = chatroom.name, !name.isEmpty {
                    weakSelf.ignLabel.text = name
                    
                } else {
                    if chatroom.isGroupChat {
                        weakSelf.ignLabel.attributedText = users?.fullIGNText
                        
                    } else if let user = users?.first {
                        weakSelf.ignLabel.attributedText = user.fullIGNText
                        
                        user.observeStatus { (status, _) in
                            weakSelf.userStatusImageView.status = status
                        }
                    } else {
                        weakSelf.ignLabel.text = signedInUser.ign
                    }
                }
            }
        }
        
        observeUnreadMessageCount()
        fetchFirstMessage()
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
    
    private func observeUnreadMessageCount() {
        guard let chatroom = chatroom else { return }
        
        firebaseChat.signIn { [weak self] (result, error) in
            guard let weakSelf = self else { return }
            
            weakSelf.firebaseChat.observeUnreadMessageCount(forChatroom: chatroom.identifier) { (unreadCount) in
                guard weakSelf.chatroom?.identifier == chatroom.identifier else {
                    // cell reuse check
                    return
                }

                weakSelf.updateUnreadCount(unreadCount)
                // unread count changed so fetch the latest message that was added
                weakSelf.fetchFirstMessage()
            }
        }
    }

    private func fetchFirstMessage() {
        guard let chatroom = chatroom, let signedInUser = DataCoordinator.shared.signedInUser else { return }

        firebaseChat.signIn { [weak self] (result, error) in
            self?.firebaseChat.fetchMessages(forChatroom: chatroom.identifier, limit: 1) { (messages) in
                performOnMainThread {
                    
                    guard self?.chatroom?.identifier == chatroom.identifier else {
                        // cell reuse check
                        return
                    }
                                        
                    guard let message = messages.first else {
                        self?.messageLabel.text = ""
                        return
                    }
                    
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
                    
                    self?.dateLabel.text = message.createdAt.ggTimestampFormat()
                }
            }
        }
    }
}
