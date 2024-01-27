//
//  MessageActionTableViewCell.swift
//  GameGether
//
//  Created by James Ajhar on 9/30/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

class MessageActionTableViewCell: UITableViewCell {

    // MARK: Properties
    
    let actionLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.constrainHeight(40)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = AppConstants.Fonts.robotoRegular(12).font
        label.textColor = AppConstants.Colors.messageAction.color
        return label
    }()
        
    private(set) var chatroom: FRChatroom?
    private(set) var message: FRMessage?
    
    func configure(withMessage message: FRMessage, andChatroom chatroom: FRChatroom? = nil) {
        self.message = message
        self.chatroom = chatroom
        setupWithMessage()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        contentView.addSubview(actionLabel)
        actionLabel.constrainToSuperview()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        actionLabel.text = ""
    }
    
    private func setupWithMessage() {
        guard let message = message else { return }
        
        switch message.type {
        case .message:
            actionLabel.text = ""
        case .media:
            actionLabel.text = ""
        case .chatroomNameUpdated:
            
            if message.createdBy == DataCoordinator.shared.signedInUser?.identifier {
                actionLabel.text = "You named the group \(message.text)"
            } else {
                actionLabel.text = "\(message.fromUserName) named the group \(message.text)"
            }

        case .chatroomImageUpdated:
            
            if message.createdBy == DataCoordinator.shared.signedInUser?.identifier {
                actionLabel.text = "You changed the group photo"
            } else {
                actionLabel.text = "\(message.fromUserName) changed the group photo"
            }
            
        case .sentFriendRequest:
            
            if message.createdBy == DataCoordinator.shared.signedInUser?.identifier {
                // Sent this friend request
                actionLabel.text = "You sent a friend request"
            } else {
                // Received this friend request
                actionLabel.text = "You received a friend request"
            }

        case .friendRequestAccepted:
            actionLabel.text = "You are now friends"
        case .cancelledFriendRequest:
            if message.createdBy == DataCoordinator.shared.signedInUser?.identifier {
                actionLabel.text = "You cancelled a friend request"
            } else {
                actionLabel.text = "\(message.fromUserName) cancelled a friend request"
            }
        case .leftChatroom, .addedToChatroom:
            actionLabel.text = message.text
        case .createdParty:
            
            let tagsText = message.tags.marqueeText
            let attributedString = NSMutableAttributedString(string: "party created with these tags in common\n")
            
            let tappableString = NSAttributedString(string: "\(message.game?.title ?? "") \(tagsText)", attributes: [
                NSAttributedString.Key.font: AppConstants.Fonts.robotoRegular(12).font,
                NSAttributedString.Key.foregroundColor: AppConstants.Colors.ggBlue.color
            ])
            
            attributedString.append(tappableString)
            actionLabel.attributedText = attributedString

        case .createdPartyNotification:
            actionLabel.text = "\(message.text) \(message.createdAt.ggTimestampFormat())"
            
        case .micTurnedOff, .micTurnedOn:
            let micActionString = message.type == .micTurnedOn ? "joined call" : "left call"
            
            if message.createdBy == DataCoordinator.shared.signedInUser?.identifier {
                actionLabel.text = "you \(micActionString)"
            } else {
                actionLabel.text = "\(message.fromUserName) \(micActionString)"
            }
            
        case .sessionCreated:
            actionLabel.text = message.text
        }
        
        contentView.layoutIfNeeded()
    }
}
