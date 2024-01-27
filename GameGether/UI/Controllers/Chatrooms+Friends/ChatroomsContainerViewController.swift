//
//  ChatroomsContainerViewController.swift
//  GameGether
//
//  Created by James Ajhar on 5/13/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class ChatroomsContainerViewController: UIViewController, ShowsNavigationOverlay {

    struct Constants {
        static let defaultColorScheme = UIColor(hexString: "#3399FF")
    }
    
    // MARK: Outlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var sectionBar: SectionBarView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerTopMarginView: UIView!
    
    // MARK: Properties
    
    lazy var chatroomsViewController: ChatroomsViewController = {
        let viewController = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: ChatroomsViewController.storyboardIdentifier) as! ChatroomsViewController
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        return viewController
    }()
    
    lazy var sessionsViewController: LFGChatroomsViewController = {
        let viewController = LFGChatroomsViewController()
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        return viewController
    }()
    
    lazy var friendsViewController: FriendsViewController = {
        let viewController = UIStoryboard(name: AppConstants.Storyboards.friends, bundle: nil).instantiateViewController(withIdentifier: FriendsViewController.storyboardIdentifier) as! FriendsViewController
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        return viewController
    }()
    
    private var didAppear: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        styleUI()

        scrollView.delegate = self

        chatroomsViewController.willMove(toParent: self)
        addChild(chatroomsViewController)
        scrollView.addSubview(chatroomsViewController.view)
        chatroomsViewController.view.constrainTo(edges: .top, .bottom, .left)
        chatroomsViewController.view.constrain(attribute: .height, toItem: scrollView, attribute: .height)
        chatroomsViewController.view.constrain(attribute: .width, toItem: scrollView, attribute: .width)
        chatroomsViewController.didMove(toParent: self)

        chatroomsViewController.onHomeSelected = { [weak self] in
            self?.headerView.backgroundColor = Constants.defaultColorScheme
            self?.headerTopMarginView.backgroundColor = Constants.defaultColorScheme
            self?.titleLabel.text = "Chat"
        }
        
        chatroomsViewController.onGameSelected = { [weak self] (game) in
            self?.headerView.backgroundColor = UIColor(hexString: game.headerColor ?? "#3399FF")
            self?.headerTopMarginView.backgroundColor = UIColor(hexString: game.headerColor ?? "#3399FF")
            self?.titleLabel.text = game.title
        }
        
        chatroomsViewController.onUnreadCountChanged = { [weak self] (_) in
            self?.sectionBar.refreshView()
        }
        
        sessionsViewController.willMove(toParent: self)
        addChild(sessionsViewController)
        scrollView.addSubview(sessionsViewController.view)
        sessionsViewController.view.constrainTo(edges: .top, .bottom)
        sessionsViewController.view.constrain(attribute: .left, toItem: chatroomsViewController.view, attribute: .right)
        sessionsViewController.view.constrain(attribute: .height, toItem: scrollView, attribute: .height)
        sessionsViewController.view.constrain(attribute: .width, toItem: scrollView, attribute: .width)
        sessionsViewController.didMove(toParent: self)
        
        sessionsViewController.onUnreadCountChanged = { [weak self] (_) in
            self?.sectionBar.refreshView()
        }
        
        friendsViewController.willMove(toParent: self)
        addChild(friendsViewController)
        scrollView.addSubview(friendsViewController.view)
        friendsViewController.view.constrainTo(edges: .top, .bottom, .right)
        friendsViewController.view.constrain(attribute: .left, toItem: sessionsViewController.view, attribute: .right)
        friendsViewController.view.constrain(attribute: .height, toItem: scrollView, attribute: .height)
        friendsViewController.view.constrain(attribute: .width, toItem: scrollView, attribute: .width)
        friendsViewController.didMove(toParent: self)
        
        sectionBar.delegate = self
        sectionBar.numberOfTabs = 3
        
        view.layoutIfNeeded()
        
//        NavigationManager.shared.navigationOverlay?.addSelectedTabDidChangeObserver(self, onTabDidChange: { [weak self] (selectedTab) in
//            if selectedTab == .chat {
//                self?.sectionBar.selectTab(atIndex: 0)
//            }
//        })
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        NavigationManager.shared.navigationOverlay?.onAIButtonTapped = { [weak self] (_) in
//            guard let weakSelf = self, weakSelf.isVisible else { return }
//            
//            let viewController = UIStoryboard(name: AppConstants.Storyboards.ggHome, bundle: nil).instantiateViewController(withIdentifier: GGHomeViewController.storyboardIdentifier) as! GGHomeViewController
//            
//            let nav = GGNavigationViewController(rootViewController: viewController)
//            nav.hidesBottomBarWhenPushed = true
//            nav.isNavigationBarHidden = true
//            nav.modalTransitionStyle = .crossDissolve
//            NavigationManager.shared.present(nav)
//        }
        
        sessionsViewController.reloadDataSource()
        
        if !didAppear {
            didAppear = true
            // LFG is default tab
            scrollTo(page: 1)
            sectionBar.selectTab(atIndex: 1, animated: false)
        }
    }
    
    deinit {
        NavigationManager.shared.navigationOverlay?.removeSelectedTabDidChangeObserver(self)
    }
    
    private func styleUI() {
        titleLabel.font = AppConstants.Fonts.robotoBold(20).font
        titleLabel.textColor = .white
    }
    
    private func scrollTo(page: Int, animated: Bool = true) {
        switch page {
        case 0:
            scrollView.scrollRectToVisible(chatroomsViewController.view.frame, animated: animated)
        case 1:
            scrollView.scrollRectToVisible(sessionsViewController.view.frame, animated: animated)
        case 2:
            scrollView.scrollRectToVisible(friendsViewController.view.frame, animated: animated)
        default:
            break
        }
    }
    
    private func goToNewMessageView() {
        AnalyticsManager.track(event: .createNewChatroomTapped, withParameters: nil)
        
        let storyboard = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: NewMessageViewController.storyboardIdentifier) as! NewMessageViewController
        
        vc.game = chatroomsViewController.selectedGame
        
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
    
    private func goToAddFriendsView() {
        AnalyticsManager.track(event: .addFriendPressed, withParameters: nil)
        
        let storyboard = UIStoryboard(name: AppConstants.Storyboards.friends, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: AddFriendsViewController.storyboardIdentifier)
        NavigationManager.shared.present(vc)
    }
    
    // MARK: - Interface Actions
    
    @IBAction func addFriendPressed(_ sender: UIButton) {
        goToAddFriendsView()
    }
    
    @IBAction func startChatPressed(_ sender: UIButton) {
        chatroomsViewController.startChatButtonPressed(sender)
    }
}

extension ChatroomsContainerViewController: SectionBarViewDelegate {
    
    func sectionBarView(view: SectionBarView, titleForTabAt index: Int) -> String {
        switch index {
        case 0:
            return "Messages"
        case 1:
            return "LFG"
        case 2:
            return "Friends"
        default:
            return ""
        }
    }
    
    func sectionBarView(view: SectionBarView, didSelectTabAt index: Int) {
        scrollTo(page: index)
        
        switch index {
        case 0:
            AnalyticsManager.track(event: .chatSubheaderMessagesSelected)
        case 1:
            AnalyticsManager.track(event: .chatSubheaderLFGSelected)
        case 2:
            AnalyticsManager.track(event: .chatSubheaderFriendsSelected)
        default:
            break
        }
    }
    
    func sectionBarView(view: SectionBarView, showNotificationForTabAt index: Int) -> Bool {
        switch index {
        case 0:
            return chatroomsViewController.unreadMessageCount > 0
        case 1:
            return sessionsViewController.unreadMessageCount > 0
        default:
            return false
        }
    }
}

extension ChatroomsContainerViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / scrollView.frame.width)
        sectionBar.selectTab(atIndex: page)
    }
}
