//
//  GameSessionsCollectionView.swift
//  GameGether
//
//  Created by James Ajhar on 9/10/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit
import PKHUD

class GameSessionsCollectionView: UICollectionView {

    enum GameSessionsCollectionViewFilter {
        case allSessionsAndPlayNow
        case allSessions
        case mySessions
    }
    
    // MARK: - Properties
    private(set) var sessions = [GameSession]() {
        didSet {
            reloadData()
        }
    }
    
    private(set) var activeLobbies = [ActiveLobby]() {
        didSet {
            reloadData()
        }
    }
    
    private var minStartDate: Date = Date.now
    private(set) var datasourceTags: [Tag]?
    
    var onCreateSessionCellTapped: ((Date) -> Void)?
    var onSectionChanged: ((String, Int) -> Void)?
    var onSessionSelected: ((GameSession) -> Void)?
    var onActiveLobbySelected: ((ActiveLobby) -> Void)?

    var filter: GameSessionsCollectionViewFilter = .allSessionsAndPlayNow {
        didSet {
            reloadData()
        }
    }
    
    var typeFilter: GameSessionType?
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    internal func commonInit() {
        dataSource = self
        delegate = self
        
        register(UINib(nibName: PlayNowCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: PlayNowCollectionViewCell.reuseIdentifier)
        register(UINib(nibName: GameSessionGroupCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: GameSessionGroupCollectionViewCell.reuseIdentifier)
        register(UINib(nibName: NewGameSessionCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: NewGameSessionCollectionViewCell.reuseIdentifier)
        register(GameSessionHeaderCollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "\(GameSessionHeaderCollectionReusableView.self)")
        
        contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)

        let layout = PinterestLayout()
        collectionViewLayout = layout
        layout.delegate = self
        layout.cellPadding = 5
        layout.numberOfColumns = 2
    }
    
    func reloadDataSource(withGame game: Game? = nil,
                          andTags tags: [Tag]? = nil,
                          minStartTime: Date? = nil,
                          maxStartTime: Date? = nil,
                          _ completion: (() -> Void)? = nil) {
        
        datasourceTags = tags
        
        if let date = minStartTime {
            minStartDate = date
        } else {
            minStartDate = Date.now
        }
        
        let group = DispatchGroup()

        switch filter {
        case .allSessionsAndPlayNow:
            group.enter()
            getActiveLobbies {
                group.leave()
            }
            group.enter()
            getAllSessions(withGame: game, andTags: tags, minStartTime: minStartTime, maxStartTime: maxStartTime) {
                group.leave()
            }
            
            group.notify(queue: .main) {
                completion?()
            }
            
        case .allSessions:
            getAllSessions(withGame: game, andTags: tags, minStartTime: minStartTime, maxStartTime: maxStartTime) {
                completion?()
            }
        case .mySessions:
            getMySessions(withGame: game, andTags: tags, minStartTime: minStartTime, maxStartTime: maxStartTime) {
                completion?()
            }
        }
    }
    
    private func getActiveLobbies(_ completion: (() -> Void)? = nil) {
        
        DataCoordinator.shared.getActiveLobbies
            { [weak self] (lobbies, error) in
                guard let weakSelf = self else { return }

                performOnMainThread {
                    
                    guard error == nil else {
                        GGLog.error("\(error?.localizedDescription ?? "unknown error")")
                        completion?()
                        return
                    }

                    weakSelf.activeLobbies = lobbies
                    completion?()
                }
        }
    }
    
    private func getAllSessions(withGame game: Game? = nil,
                                  andTags tags: [Tag]? = nil,
                                  minStartTime: Date? = nil,
                                  maxStartTime: Date? = nil,
                                  _ completion: (() -> Void)? = nil) {
        
        let spinner = displaySpinner(foregroundColor: .white, backgroundColor: UIColor(hexString: "#57A2E1"))

        DataCoordinator.shared.getGameSessions(forGame: game?.identifier,
                                               withTags: tags,
                                               ofType: typeFilter,
                                               startTime: minStartTime,
                                               maxStartTime: maxStartTime)
        { [weak self] (sessions, error) in
            guard let weakSelf = self else { return }
            
            performOnMainThread {
                weakSelf.removeSpinner(spinner: spinner)
                
                guard weakSelf.datasourceTags?.hashedValue == tags?.hashedValue else { return }
                
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
    
    private func getMySessions(withGame game: Game? = nil,
                               andTags tags: [Tag]? = nil,
                               minStartTime: Date? = nil,
                               maxStartTime: Date? = nil,
                               _ completion: (() -> Void)? = nil) {
        
        let spinner = displaySpinner()
        
        DataCoordinator.shared.getGameSessionsAttending(forGame: game?.identifier,
                                                        withTags: tags,
                                                        startTime: minStartTime,
                                                        maxStartTime: maxStartTime)
        { [weak self] (sessions, error) in
            guard let weakSelf = self else { return }
            
            performOnMainThread {
                weakSelf.removeSpinner(spinner: spinner)
                
                guard weakSelf.datasourceTags?.hashedValue == tags?.hashedValue else { return }
                
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
    
    private func joinGameSession(_ session: GameSession) {
        guard let user = DataCoordinator.shared.signedInUser else {
            // onboarding, go to create account screen
            let viewController = UIStoryboard(name: AppConstants.Storyboards.onboarding, bundle: nil).instantiateViewController(withIdentifier: RegisterUserViewController.storyboardIdentifier)
            let nav = GGNavigationViewController(rootViewController: viewController)
            NavigationManager.shared.present(nav)
            return
        }
        
        HUD.show(.progress)
        
        DataCoordinator.shared.joinGameSession(session) { [weak self] (chatroomId, error) in
            performOnMainThread {
                HUD.hide()
                
                guard error == nil else {
                    GGLog.error("\(error?.localizedDescription ?? "unknown error")")
                    NavigationManager.topMostViewController()?.presentGenericErrorAlert(message: error?.localizedDescription ?? "An unknown error occurred")
                    return
                }
                session.updateJoinedState(isJoined: true)
                session.addAttendee(user)
                self?.reloadData()
                
                if let chatroomId = chatroomId {
                    // If there is a chatroom associated with this session, go to it now.
                    
                    FirebaseChat().fetchChatroom(chatroomId) { (chatroom) in
                        guard let chatroom = chatroom else { return }
                            
                        performOnMainThread {
                            let viewController = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: ChatViewController.storyboardIdentifier) as! ChatViewController
                            viewController.chatroom = chatroom
                            NavigationManager.shared.push(viewController)
                        }
                    }
                    
                } else {
                    GGHUDView.show(withText: "session joined!",
                                   subText: "We’ll notify you 5 mins before it starts",
                                   textColor: .white,
                                   backgroundColor: UIColor(hexString: "#1C6EB9"),
                                   duration: 3)
                }
            }
        }
    }
    
    private func leaveGameSession(_ session: GameSession) {
        guard let user = DataCoordinator.shared.signedInUser else { return }
        HUD.show(.progress)

        DataCoordinator.shared.leaveGameSession(session) { [weak self] (error) in
            performOnMainThread {
                HUD.hide()
                
                guard error == nil else {
                    GGLog.error("\(error?.localizedDescription ?? "unknown error")")
                    NavigationManager.topMostViewController()?.presentGenericErrorAlert()
                    return
                }
                session.updateJoinedState(isJoined: false)
                session.removeAttendee(user)
                self?.reloadData()
                
                GGHUDView.show(withText: "session left",
                               textColor: .white,
                               backgroundColor: UIColor(hexString: "#BE2F2F").withAlphaComponent(0.9))
            }
        }
    }
}

extension GameSessionsCollectionView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if filter == .allSessionsAndPlayNow {
            return 2    // always show at least 2 sections (Play Now + Play Later)
        }
        
        return 1    // always show at least 1 section
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if section == 0, filter == .allSessionsAndPlayNow {
            // Play Now
            return activeLobbies.count
        }
        
        // Play Later
        return sessions.count + 1 // +1 for create session cell
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.section == 0, filter == .allSessionsAndPlayNow {
            // Play Now
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PlayNowCollectionViewCell.reuseIdentifier, for: indexPath) as! PlayNowCollectionViewCell
            cell.playNowView.configure(withLobby: activeLobbies[indexPath.item])
            return cell
        }
        
        // Play Later
        
        if indexPath.item >= sessions.count {
            // Create session cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewGameSessionCollectionViewCell.reuseIdentifier, for: indexPath)
            return cell
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GameSessionGroupCollectionViewCell.reuseIdentifier, for: indexPath) as! GameSessionGroupCollectionViewCell
        cell.sessionView.session = sessions[indexPath.item]
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if indexPath.section == 0, filter == .allSessionsAndPlayNow {
            // Play Now
            let view = dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "\(GameSessionHeaderCollectionReusableView.self)", for: indexPath) as! GameSessionHeaderCollectionReusableView
            return view
        }
        
        let view = dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "\(GameSessionHeaderCollectionReusableView.self)", for: indexPath) as! GameSessionHeaderCollectionReusableView
        
        let adjustedSection = filter == .allSessionsAndPlayNow ? indexPath.section - 1 : indexPath.section
        guard adjustedSection < sessions.count else { return view }
                
//        switch filter {
//        case .allSessionsAndPlayNow:
//            if indexPath.section == 0 {
//                view.setTitle("Play Now")
//            } else {
//                view.setTitle("Play With")
//            }
//        case .allSessions, .mySessions:
//            view.setTitle("Play With")
//        }

        return view
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if indexPath.section == 0, filter == .allSessionsAndPlayNow {
            // Play Now
            onActiveLobbySelected?(activeLobbies[indexPath.item])
            return
        }
        
        if indexPath.item >= sessions.count {
            // Create session cell
            onCreateSessionCellTapped?(Date.now)
            return
        }
        
        let session = sessions[indexPath.item]

        onSessionSelected?(session)
        
//        if session.sessionType?.type == .request {
//            // Special handling for REQUEST sessions
//            showRequestSessionAlert(forSession: session)
//        }
    }
    
    private func presentPushNotificationAlertIfNeeded(_ completion: @escaping () -> Void) {
        UIDevice.checkPushNotificationEnabled { (isEnabled) in
            performOnMainThread {
                guard !isEnabled else {
                    completion()
                    return
                }
                
                let alert = UIAlertController(title: "Enable Push Notifications",
                                              message: "Push is not enabled for GameGether. We can’t notify you when your sessions occur.",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "ok, I'll enable them in settings", style: .cancel, handler: { (_) in
                    completion()
                }))
                alert.show()
            }
        }
    }

    private func showRequestSessionAlert(forSession session: GameSession) {
        
        if session.isJoined, let chatroomId = session.chatroomId {
            // If there is a chatroom associated with this session, go to it now.
            HUD.show(.progress)
            
            FirebaseChat().fetchChatroom(chatroomId) { (chatroom) in
                performOnMainThread {
                    HUD.hide()
                }
                
                guard let chatroom = chatroom else { return }
                    
                performOnMainThread {
                    let viewController = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: ChatViewController.storyboardIdentifier) as! ChatViewController
                    viewController.chatroom = chatroom
                    NavigationManager.shared.push(viewController)
                }
            }
                        
        } else {
            let alert = UIAlertController(title: "Ready to join this party?!",
                                          message: "Joining will spawn you into a group chat - glhf!",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "join", style: .cancel, handler: { [weak self] (_) in
                
                self?.presentPushNotificationAlertIfNeeded {
                    self?.joinGameSession(session)
                }
            }))

            alert.addAction(UIAlertAction(title: "cancel", style: .default, handler: nil))
            alert.show()
        }
    }
}

extension GameSessionsCollectionView: PinterestLayoutDelegate {
    
    func collectionView(collectionView: UICollectionView, heightForImageAtIndexPath indexPath: IndexPath, withWidth: CGFloat) -> CGFloat {
        
        if indexPath.section == 0, filter == .allSessionsAndPlayNow {
            // Play Now
            return 136
        }
        
        guard indexPath.item < sessions.count else {
            return 136
        }
         
        let session = sessions[indexPath.item]
        
        guard session.sessionType?.type == .request else {
            return 180
        }
        
        // Calculate the height for request sessions based on the description length
        let view = UINib(nibName: "\(GameSessionGroupView.self)", bundle: nil).instantiate(withOwner: self, options: nil).first as! GameSessionGroupView
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
        if section == 0 {
            // Hide this for now
            return .zero //CGSize(width: bounds.width, height: 35)
        }
        return CGSize(width: bounds.width, height: 80)
    }
}
