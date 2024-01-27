//
//  LFGChatroomsCollectionViewController.swift
//  GameGether
//
//  Created by James Ajhar on 12/10/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit
import PKHUD

class LFGChatroomsViewController: UIViewController {

    struct Constants {
        static let brawlStarsId = "5dca0736f8521650b21fe56a"
    }

    // MARK: - Properties
    lazy var collectionView: UICollectionView = {
        
        let layout = PinterestLayout()
        layout.delegate = self
        layout.cellPadding = 5
        layout.numberOfColumns = 2

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        // Register cell classes
        collectionView.register(GameSessionCollectionViewCell.self, forCellWithReuseIdentifier: GameSessionCollectionViewCell.reuseIdentifier)
        collectionView.register(UINib(nibName: NewGameSessionCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: NewGameSessionCollectionViewCell.reuseIdentifier)

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.contentInset = UIEdgeInsets(top: 9, left: 9, bottom: 100, right: 0)
        
        return collectionView
    }()
    
    private lazy var createLFGButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(#imageLiteral(resourceName: "LFG Post Button"), for: .normal)
        button.addTarget(self, action: #selector(createLFGButtonPressed(_:)), for: .touchUpInside)
        return button
    }()
    
    private let firebaseChat = FirebaseChat()
    
    private(set) var sessions = [GameSession]() {
        didSet {
            collectionView.reloadData()
        }
    }
    
    private(set) var unreadMessageCount: Int = 0
    
    var onUnreadCountChanged: ((Int) -> Void)?
    
    override func loadView() {
        super.loadView()

        collectionView.backgroundColor = .white
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        collectionView.constrainToSuperview()
        
        view.addSubview(createLFGButton)
        createLFGButton.constrainTo(edge: .right)?.constant = -24
        createLFGButton.constrainTo(edge: .bottom)?.constant = -70

        view.layoutIfNeeded()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reloadDataSource()
        observeUnreadMessageCount()
    }
    
    public func reloadDataSource(_ completion: (() -> Void)? = nil) {
        
        let spinner = view.displaySpinner()
        
        DataCoordinator.shared.getGameSessionsAttending()
        { [weak self] (sessions, error) in
            guard let weakSelf = self else { return }
            
            performOnMainThread {
                weakSelf.view.removeSpinner(spinner: spinner)
                 weakSelf.sessions.removeAll()
                
                guard error == nil else {
                    GGLog.error("\(error?.localizedDescription ?? "unknown error")")
                    completion?()
                    return
                }
            
                weakSelf.sessions = sessions
                completion?()
            }
        }
    }
    
    private func observeUnreadMessageCount() {
        firebaseChat.signIn { [weak self] (result, error) in
            self?.firebaseChat.observeTotalChatroomUnreadMessageCount(sessionsOnly: true, completion: { [weak self] (unreadCountTuple, totalUnreadCount) in
                guard let weakSelf = self else { return }
                
                performOnMainThread {
                    // If the unread message count changed on a given chatroom, reload the chatrooms datasource so we get the latest
                    //  messages and reorder the rooms by most recent message.
                    weakSelf.unreadMessageCount = totalUnreadCount
                    weakSelf.collectionView.reloadData()
                    weakSelf.onUnreadCountChanged?(totalUnreadCount)
                }
            })
        }
    }
}

extension LFGChatroomsViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sessions.count + 1 // +1 for create session cell
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.item >= sessions.count {
            // Create session cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewGameSessionCollectionViewCell.reuseIdentifier, for: indexPath)
            return cell
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GameSessionCollectionViewCell.reuseIdentifier, for: indexPath) as! GameSessionCollectionViewCell
        cell.sessionView.session = sessions[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if indexPath.item >= sessions.count {
            // Create session cell
            
            HUD.show(.progress)
            
            DataCoordinator.shared.getGames { [weak self] (games, error) in
                
                performOnMainThread {
                    HUD.hide()
                }
                
                guard let weakSelf = self, let brawlStars = games.filter({ $0.identifier == Constants.brawlStarsId }).first else { return }
                
                performOnMainThread {
                    weakSelf.presentGameSelectorView(forGame: brawlStars)
                }
            }
            
            return
        }

        let session = sessions[indexPath.item]
        
        guard let chatroomId = session.chatroomId else { return }
        
        AnalyticsManager.track(event: .lfgOpened, withParameters: ["session": session.identifier])
        
        FirebaseChat().fetchChatroom(chatroomId) { (chatroom) in
            let viewController = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: ChatViewController.storyboardIdentifier) as! ChatViewController
            viewController.chatroom = chatroom
            viewController.session = session
            NavigationManager.shared.push(viewController)
        }
    }
    
    private func presentGameSelectorView(forGame game: Game) {
        let storyboard = UIStoryboard(name: AppConstants.Storyboards.scheduling, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: ScheduleSessionGameTagsModalViewController.storyboardIdentifier) as! ScheduleSessionGameTagsModalViewController
        
        vc.onGameSelected = { [weak self] (game, tags) in
            guard let weakSelf = self else { return }
            
            AnalyticsManager.track(event: .scheduleSessionGameSelected, withParameters: [
                "game": game.title,
                "tags": tags.compactMap({ $0.jsonValue })
                ])
                        
            let storyboard = UIStoryboard(name: AppConstants.Storyboards.lfg, bundle: nil)
            let lfgVC = storyboard.instantiateViewController(withIdentifier: CreateLFGViewController.storyboardIdentifier) as! CreateLFGViewController
            lfgVC.game = game
            lfgVC.tags = tags
            
            lfgVC.onPostCreated = { [weak self] (session) in
                self?.reloadDataSource()
                lfgVC.dismissSelf(animated: true) {
                    NavigationManager.shared.toggleJoystickNavigation(visible: true)
                    NavigationManager.shared.navigationOverlay?.toggleBottomNavigationBar(visible: true)
                    NavigationManager.shared.navigationOverlay?.shouldShowNavigationBar = true
                }
            }
            
            vc.dismissSelf(animated: true) {
                weakSelf.present(lfgVC, animated: true, completion: nil)
            }
        }

        vc.onCancelPressed = {
            AnalyticsManager.track(event: .scheduleSessionSelectGameCancelTapped)
            vc.dismissSelf()
            NavigationManager.shared.toggleJoystickNavigation(visible: true)
            NavigationManager.shared.navigationOverlay?.toggleBottomNavigationBar(visible: true)
        }
        
        vc.selectedGame = game
        
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        present(vc, animated: true, completion: nil)
    }
    
    // MARK: - Interface Actions
    
    @objc func createLFGButtonPressed(_ sender: UIButton) {
        
        HUD.show(.progress)
        
        DataCoordinator.shared.getGames { [weak self] (games, error) in
            
            performOnMainThread {
                HUD.hide()
            }
            
            guard let weakSelf = self, let brawlStars = games.filter({ $0.identifier == Constants.brawlStarsId }).first else { return }
            
            performOnMainThread {
                weakSelf.presentGameSelectorView(forGame: brawlStars)
            }
        }
    }
}

extension LFGChatroomsViewController: PinterestLayoutDelegate {
    
    func collectionView(collectionView: UICollectionView, heightForImageAtIndexPath indexPath: IndexPath, withWidth: CGFloat) -> CGFloat {
   
        guard indexPath.item < sessions.count else {
            return 136
        }
         
        let session = sessions[indexPath.item]

        // Calculate the height for request sessions based on the description length
        let view = UINib(nibName: "\(GameSessionView.self)", bundle: nil).instantiate(withOwner: self, options: nil).first as! GameSessionView
        view.translatesAutoresizingMaskIntoConstraints = false
        view.configureForHeightCalculation(session: session)
        view.constrainWidth(withWidth)
        view.layoutIfNeeded()

        return view.bounds.height
    }
    
    func collectionView(collectionView: UICollectionView, heightForAnnotationAtIndexPath indexPath: IndexPath, withWidth: CGFloat) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, sizeForSectionHeaderViewForSection section: Int) -> CGSize {
        return .zero
    }
}
