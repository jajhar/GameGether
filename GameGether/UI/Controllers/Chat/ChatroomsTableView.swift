//
//  ChatroomsTableView.swift
//  GameGether
//
//  Created by James Ajhar on 7/29/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit
import ViewAnimator
import DeepDiff

protocol ChatroomsTableViewDelegate: class {
    func tableview(tableview: ChatroomsTableView, didSelectChatRoom chatroom: FRChatroom, atIndex index: IndexPath)
}

enum ChatroomsTableViewMode {
    case privateChats
    case groupChats
    case all
    case game(Game)
}

class ChatroomsTableView: UITableView {

    // MARK: Properties
    weak var chatroomsDelegate: ChatroomsTableViewDelegate?
    private let firebaseChat = FirebaseChat()
    private(set) var chatrooms: [FRChatroom] = [FRChatroom]()
    
    private var groupChatrooms: [FRChatroom] {
        return chatrooms.filter({
            $0.isGroupChat
        })
    }
    
    private var privateChatrooms: [FRChatroom] {
        return chatrooms.filter({
            !$0.isGroupChat
        })
    }
    
    private(set) var selectedChatrooms = [FRChatroom]()
    
    var mode: ChatroomsTableViewMode = .all {
        didSet {
            reloadData()
        }
    }
    
    var maxSelectableChatrooms: Int?
    
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
        register(UINib(nibName: "\(ChatroomTableViewCell.self)", bundle: nil),
                 forCellReuseIdentifier: ChatroomTableViewCell.reuseIdentifier)
        rowHeight = UITableView.automaticDimension
        estimatedRowHeight = 44
        contentInset = UIEdgeInsets.init(top: 10, left: 0, bottom: 100, right: 0)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        reloadChatroomsDataSource()
    }
    
    func reloadChatroomsDataSource(showSpinner: Bool = true, _ completion: (([FRChatroom]) -> Void)? = nil) {
        
        var spinner: UIActivityIndicatorView?
        
        if showSpinner {
            spinner = displaySpinner()
        }
        
        firebaseChat.signIn { [weak self] (result, error) in
            guard let weakSelf = self else {
                performOnMainThread {
                    if let spinner = spinner {
                        self?.removeSpinner(spinner: spinner)
                    }
                    completion?([])
                }
                return
            }
            
            weakSelf.firebaseChat.fetchPrivateRooms(completion: { (remoteChatrooms) in
                
                performOnMainThread {
                    if let spinner = spinner {
                        weakSelf.removeSpinner(spinner: spinner)
                    }
                    
                    if weakSelf.chatrooms.isEmpty || remoteChatrooms.isEmpty || weakSelf.numberOfRows(inSection: 0) == 0 {
                        weakSelf.chatrooms = remoteChatrooms
                        weakSelf.reloadData()
                    } else {
                        let changes = diff(old: weakSelf.chatrooms, new: remoteChatrooms)
                        weakSelf.reload(changes: changes, section: 0, updateData: {
                            weakSelf.chatrooms = remoteChatrooms
                        })
                    }
                    
                    completion?(remoteChatrooms)
                }
            })
        }
    }
    
    func chatrooms(forFilter filter: ChatroomsTableViewMode) -> [FRChatroom] {
        switch filter {
        case .privateChats:
            return privateChatrooms
        case .groupChats:
            return groupChatrooms
        case .all:
            return chatrooms
        case .game(let game):
            return chatrooms.filter({ $0.game?.identifier == game.identifier })
        }
    }
    
    func animate() {
        UIView.animate(views: visibleCells,
                       animations: [],
                       initialAlpha: 0.5,
                       finalAlpha: 1.0,
                       duration: 0.3)
    }
}

extension ChatroomsTableView: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatrooms(forFilter: mode).count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatroomTableViewCell.reuseIdentifier, for: indexPath) as! ChatroomTableViewCell
        let chatrooms = self.chatrooms(forFilter: mode)
        let chatroom = chatrooms[indexPath.row]
        cell.chatroom = chatroom
        cell.allowsSelection = allowsMultipleSelection
        cell.isChatroomSelected = selectedChatrooms.contains(where: { $0.identifier == chatroom.identifier})
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // auto-deselect the cell because we manage selection via a separate boolean `isChatroomSelected`
        tableView.deselectRow(at: indexPath, animated: false)

        let chatrooms = self.chatrooms(forFilter: mode)
        guard indexPath.row < chatrooms.count, let _ = tableView.cellForRow(at: indexPath) as? ChatroomTableViewCell else { return }
        
        let chatroom = chatrooms[indexPath.row]
        
        if allowsMultipleSelection {
            if selectedChatrooms.contains(where: { $0.identifier == chatroom.identifier}) {
                // Chatroom is already selected, remove it from the list
                selectedChatrooms.removeAll(where: { $0.identifier == chatroom.identifier })

            } else {
                // Chatroom is not selected, add it to the list (if there's room)
                if let maxSelectable = maxSelectableChatrooms, selectedChatrooms.count >= maxSelectable {
                    // Remove the first selected chatroom from the list to make room.
                    selectedChatrooms.removeFirst()
                }
                
                selectedChatrooms.append(chatroom)
            }
            
            // Update all selected cells
            tableView.reloadData()
        }
        
        chatroomsDelegate?.tableview(tableview: self, didSelectChatRoom: chatroom, atIndex: indexPath)
    }
}
