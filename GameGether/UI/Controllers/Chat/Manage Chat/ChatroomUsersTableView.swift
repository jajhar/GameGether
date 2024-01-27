//
//  ChatUsersTableView.swift
//  GameGether
//
//  Created by James Ajhar on 8/19/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit
import PKHUD

class ChatroomUsersTableView: UITableView {

    // MARK: Properties
    private(set) var users: [User] = [User]()
    private(set) var firebaseChat = FirebaseChat()
    
    var chatroom: FRChatroom? {
        didSet {
            reloadDataSource()
        }
    }

    var onMessageButtonTapped: ((User) -> Void)?

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
        separatorStyle = .none
        allowsSelection = true
        register(UINib(nibName: "\(UserTableViewCell.self)", bundle: nil),
                 forCellReuseIdentifier: UserTableViewCell.reuseIdentifier)
        register(UINib(nibName: "\(AddChatroomUserCell.self)", bundle: nil),
                 forCellReuseIdentifier: AddChatroomUserCell.reuseIdentifier)
        rowHeight = UITableView.automaticDimension
        estimatedRowHeight = 44
        reloadDataSource()
        
        firebaseChat.signIn()        
    }
    
    func reloadDataSource(breakCache: Bool = false) {
        guard let chatroom = chatroom else { return }
        
        chatroom.fetchUsers(breakCache: breakCache, completion: { [weak self] (users) in
            guard let strongself = self, let users = users else { return }
            
            performOnMainThread {
                strongself.users = users
                strongself.reloadData()
            }
        })
    }
}

extension ChatroomUsersTableView: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        default:
            return users.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: AddChatroomUserCell.reuseIdentifier, for: indexPath) as! AddChatroomUserCell
            cell.addFriendLabel.text = chatroom?.isGroupChat == true ? "add to group" : "create a group"
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: UserTableViewCell.reuseIdentifier, for: indexPath) as! UserTableViewCell
        cell.user = users[indexPath.row]
        cell.showsMessageButton = true
        cell.delegate = self
        return cell
    }
    
    private func showAddFriendsToChatView() {
        guard let chatroom = chatroom else { return }
        let storyboard = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: NewMessageViewController.storyboardIdentifier) as! NewMessageViewController
        vc.chatroom = chatroom
        vc.initialUsersToPopulate = users
       
        vc.onChatroomCreation = { (newMessageVC, chatroom) in
            newMessageVC.dismissSelf(animated: true, completion: {
                // Navigate to the new private chatroom
                let viewController = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: ChatViewController.storyboardIdentifier) as! ChatViewController
                viewController.chatroom = chatroom
                NavigationManager.shared.push(viewController)
            })
        }
        
        vc.onChatroomEdited = { [weak self] (newMessageVC, chatroom) in
            self?.reloadDataSource(breakCache: true)
            newMessageVC.dismissSelf()
        }
        
        NavigationManager.shared.present(vc)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            // Add new user cell tapped
            showAddFriendsToChatView()
            return
        }
        
        guard indexPath.row < users.count else { return }
        
        let user = users[indexPath.row]
        AnalyticsManager.track(event: .chatroomUserSelected, withParameters: ["selected": user.identifier])
        
        let viewController = UIStoryboard(name: AppConstants.Storyboards.profile, bundle: nil).instantiateViewController(withIdentifier: ProfileViewControllerV2.storyboardIdentifier) as! ProfileViewControllerV2
        viewController.user = user
        NavigationManager.shared.push(viewController)
    }
}

extension ChatroomUsersTableView: UserTableViewCellDelegate {
    
    func userTableViewCell(cell: UserTableViewCell, messageButtonTapped button: UIButton) {
        guard let user = cell.user else { return }
        onMessageButtonTapped?(user)
    }
}
