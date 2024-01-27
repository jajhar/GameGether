//
//  MessagesTableView.swift
//  GameGether
//
//  Created by James Ajhar on 8/4/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit
import DeepDiff

protocol MessagesTableViewDelegate: class {
    func messagesTableView(tableView: MessagesTableView, didReceiveMessages messages: [FRMessage])
    func messagesTableView(tableView: MessagesTableView, didTap message: FRMessage)
}

class MessagesTableView: UITableView {
    
    struct Constants {
        static let groupedMessageIntervalMinutes: Int = 5 // 5 min
    }
    
    private let firebaseChat: FirebaseChat = {
        let chat = FirebaseChat()
        chat.signIn()
        return chat
    }()
    
    private(set) var messages: [FRMessage] = [FRMessage]()
    
    weak var messageDelegate: MessagesTableViewDelegate?
    
    var chatroom: FRChatroom? {
        didSet {
            guard oldValue?.identifier != chatroom?.identifier else { return }
            reloadMessagesDataSource()
        }
    }
    
    var onUserTapped: ((User, MessageTableViewCell) -> Void)?
    var game: Game?
    var gameTags = [Tag]() {
        didSet {
            reloadMessagesDataSource()
        }
    }
    
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        dataSource = self
        delegate = self
        keyboardDismissMode = .interactive
        separatorStyle = .none
        register(UINib(nibName: "\(MessageTableViewCell.self)", bundle: nil),
                 forCellReuseIdentifier: MessageTableViewCell.reuseIdentifier)
        register(MessageActionTableViewCell.self, forCellReuseIdentifier: MessageActionTableViewCell.reuseIdentifier)
        register(PartyFilledMessageTableViewCell.self, forCellReuseIdentifier: PartyFilledMessageTableViewCell.reuseIdentifier)
        rowHeight = UITableView.automaticDimension
        estimatedRowHeight = 44
        contentInset = UIEdgeInsets.init(top: 15, left: 0, bottom: 15, right: 0)
    }
    
    func reloadMessagesDataSource() {
        if chatroom != nil {
            observeMessagesForChatroom()
        } else {
            observeMessagesForTag()
        }
    }
    
    func reloadContent(animated: Bool = true) {
        UIView.transition(with: self,
                          duration: 0.3,
                          options: .transitionCrossDissolve,
                          animations: { self.reloadData() })
    }
    
    private func observeMessagesForChatroom() {
        guard let chatroom = chatroom else { return }
        
        messages.removeAll()
        reloadContent()
        
        firebaseChat.observeMessages(forChatroom: chatroom.identifier) { [weak self] (newMessages) in
            
            guard let weakSelf = self else { return }
            
            var trimmedMessages = newMessages
            
            // Only show the latest 100 messages (not sure if this is necessary given the limit on this Observe func)df
            while trimmedMessages.count > 100 {
                _ = trimmedMessages.removeFirst()
            }
            
            performOnMainThread {
                weakSelf.messageDelegate?.messagesTableView(tableView: weakSelf, didReceiveMessages: trimmedMessages)
                                
                let changes = diff(old: weakSelf.messages, new: trimmedMessages)
                weakSelf.reload(changes: changes, section: 0, insertionAnimation: .fade, updateData: {
                    weakSelf.messages = trimmedMessages
                })

                weakSelf.scrollToBottom()
            }
        }
    }
    
    private func observeMessagesForTag() {
        guard let game = game else { return }
        
        messages.removeAll()
        reloadContent()
        
        firebaseChat.observeMessages(forGame: game, withTags: gameTags.count > 0 ? gameTags : nil) { [weak self] (messages) in

            guard let weakSelf = self else { return }
            
            performOnMainThread {
                
                let changes = diff(old: weakSelf.messages, new: messages)
                
                // If nothing changed, don't reload
                guard changes.count > 0 else { return }
                
                weakSelf.reload(changes: changes, section: 0, insertionAnimation: .fade, updateData: {
                    weakSelf.messages = messages
                })
                
                weakSelf.scrollToBottom()
            }
        }
    }

}

extension MessagesTableView: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let message = messages[indexPath.row]
        if message.type == .message || message.type == .media {
            let cell = tableView.dequeueReusableCell(withIdentifier: MessageTableViewCell.reuseIdentifier, for: indexPath) as! MessageTableViewCell
            
            let message = messages[indexPath.row]
            let prevIndex = indexPath.row-1
            var isSimplified = false
            
            if prevIndex > 0,
                prevIndex < messages.count,
                messages[prevIndex].type == .message || messages[prevIndex].type == .media,
                messages[prevIndex].createdBy == message.createdBy,
                messages[prevIndex].createdAt.minutes(from: message.createdAt) < Constants.groupedMessageIntervalMinutes {
                // group together messages sent from the same user within x minutes
                isSimplified = true
            }
            
            cell.setupWithMessage(message, andChatroom: chatroom, simplified: isSimplified)
            cell.selectionStyle = .none
            cell.onUserTapped = onUserTapped
            return cell
            
        } else if message.type == .createdPartyNotification {
            let cell = tableView.dequeueReusableCell(withIdentifier: PartyFilledMessageTableViewCell.reuseIdentifier, for: indexPath) as! PartyFilledMessageTableViewCell
            cell.message = messages[indexPath.row]
            cell.selectionStyle = .none
            return cell

        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: MessageActionTableViewCell.reuseIdentifier, for: indexPath) as! MessageActionTableViewCell
            cell.selectionStyle = .none
            
            let message = messages[indexPath.row]
            cell.configure(withMessage: message, andChatroom: chatroom)

//            var prevIndex = indexPath.row-1
//            var actionText = ""
//            
//            while prevIndex > 0,
//                prevIndex < messages.count,
//                messages[prevIndex].type == .micTurnedOn || messages[prevIndex].type == .micTurnedOff,
//                messages[prevIndex].createdAt.minutes(from: message.createdAt) < Constants.groupedMessageIntervalMinutes
//            {
//                // group together messages sent from the same user within x minutes
//                prevIndex -= 1
//                actionText += "\(messages[prevIndex].fromUserName) "
//            }
//            
//            if !actionText.isEmpty {
//                actionText = message.type == .micTurnedOn ? " joined call" : " left call"
//                cell.actionLabel.text = actionText
//            }
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.row]
        messageDelegate?.messagesTableView(tableView: self, didTap: message)
    }
}

extension MessagesTableView: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

}
