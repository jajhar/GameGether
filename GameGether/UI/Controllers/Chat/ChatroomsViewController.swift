//
//  ChatroomsViewController.swift
//  GameGether
//
//  Created by James Ajhar on 7/29/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

class ChatroomsViewController: UIViewController, ShowsNavigationOverlay {

    // MARK: Outlets
    @IBOutlet weak var tableView: ChatroomsTableView!
    @IBOutlet weak var chatroomFilterView: ChatroomFilterView!
    @IBOutlet weak var emptyStateView: UIView!
    
    // MARK: Properties
    private let firebaseChat = FirebaseChat()
    private var newMessagePopUpViewController: NewMessagePopUpViewController?
    private(set) var selectedGame: Game?
    private(set) var unreadMessageCount: Int = 0

    var onGameSelected: ((Game) -> Void)?
    var onHomeSelected: (() -> Void)?
    var onUnreadCountChanged: ((Int) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.chatroomsDelegate = self
        chatroomFilterView.user = DataCoordinator.shared.signedInUser
        
        chatroomFilterView.onHomeSelected = { [weak self] in
            self?.setMode(.all)
            AnalyticsManager.track(event: .chatroomFilterSelected, withParameters: ["icon": "home"])
            self?.onHomeSelected?()
        }

        chatroomFilterView.onGameSelected = { [weak self] (game) in
            self?.selectedGame = game
            self?.setMode(.game(game))
            AnalyticsManager.track(event: .chatroomFilterSelected, withParameters: ["icon": game.title])
            self?.onGameSelected?(game)
        }
        
        observeUnreadMessageCount()
        
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { (_) in
            self.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Fetch the latest chatrooms
        tableView.reloadChatroomsDataSource(showSpinner: false) { [weak self] (chatrooms) in
            self?.emptyStateView.isHidden = chatrooms.count > 0
        }
        
        chatroomFilterView.reload()
    }
    
    private func observeUnreadMessageCount() {
        firebaseChat.signIn { [weak self] (result, error) in
            self?.firebaseChat.observeTotalChatroomUnreadMessageCount(completion: { [weak self] (_, count) in
                guard let weakSelf = self else { return }
                
                performOnMainThread {
                    // If the unread message count changed on a given chatroom, reload the chatrooms datasource so we get the latest
                    //  messages and reorder the rooms by most recent message.
                    weakSelf.unreadMessageCount = count
                    weakSelf.onUnreadCountChanged?(count)
                    weakSelf.tableView.reloadChatroomsDataSource(showSpinner: false)
                }
            })
        }
    }

    func setMode(_ mode: ChatroomsTableViewMode) {
        tableView.mode = mode
        tableView.animate()
    }

    // MARK: Interface Actions
    
    @IBAction func startChatButtonPressed(_ sender: Any) {
        goToNewMessageView()
    }
    
    func goToNewMessageView() {
        AnalyticsManager.track(event: .createNewChatroomTapped, withParameters: nil)
        
        let storyboard = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: NewMessageViewController.storyboardIdentifier) as! NewMessageViewController
        
        vc.game = selectedGame

        vc.onChatroomCreation = { [weak self] (newMessageVC, chatroom) in
            newMessageVC.dismissSelf(animated: true, completion: {
                // Navigate to the new private chatroom
                let viewController = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: ChatViewController.storyboardIdentifier) as! ChatViewController
                viewController.chatroom = chatroom
                self?.navigationController?.pushViewController(viewController, animated: true)
            })
        }

        NavigationManager.shared.present(vc)
    }
}

extension ChatroomsViewController: ChatroomsTableViewDelegate {
 
    func tableview(tableview: ChatroomsTableView, didSelectChatRoom chatroom: FRChatroom, atIndex index: IndexPath) {
        AnalyticsManager.track(event: .chatroomOpened, withParameters: ["chatroom": chatroom.identifier])
        let viewController = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: ChatViewController.storyboardIdentifier) as! ChatViewController
        viewController.chatroom = chatroom
        navigationController?.pushViewController(viewController, animated: true)
    }
}

