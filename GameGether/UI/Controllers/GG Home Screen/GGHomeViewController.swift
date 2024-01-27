//
//  GGHomeViewController.swift
//  GameGether
//
//  Created by James Ajhar on 9/16/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit
import EasyTipView

class GGHomeViewController: UIViewController, ShowsNavigationOverlay {
    
    struct Constants {
        static let brawlStarsId = "5dca0736f8521650b21fe56a"
        static let powerPlayTagId = "5df69fc45b0b493a959ce02d"
        static let followTagsButtonWidth: CGFloat = 40.0
    }
    
    // MARK: - Outlets
    @IBOutlet weak var headerTitleLabel: UILabel! {
        didSet {
            headerTitleLabel.font = AppConstants.Fonts.robotoBold(25).font
            headerTitleLabel.textColor = UIColor(hexString: "#3399FF")
            headerTitleLabel.text = "Home"
//            let game = NSAttributedString(string: "Game", attributes: [.foregroundColor: UIColor(hexString: "#66CC33")])
//            let gether = NSAttributedString(string: "Home", attributes: [.foregroundColor: UIColor(hexString: "#3399FF")])
//            let text = NSMutableAttributedString(attributedString: game)
//            text.append(gether)
//            headerTitleLabel.attributedText = text
        }
    }
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var gameSessionsContainerVC: UIView!
    
    @IBOutlet weak var tagsHeaderView: TagsHeaderCollectionView! {
        didSet {
            tagsHeaderView.tagsHeaderDelegate = self
        }
    }
    @IBOutlet weak var followTagsButton: UIButton!
    @IBOutlet weak var followTagsButtonWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var createLFGButton: UIButton!
    
    // MARK: - Properties
    private var gameSessionsVC: PlayLaterSessionsViewController?
    private var brawlStars: Game?
    
    private var selectedTags = [Tag]() {
        didSet {
            gameSessionsVC?.tags = selectedTags
        }
    }
    
    private var starredTooltip: UIImageView?
    private var starredTooltipTimer: Timer?

    private var pbTooltip: EasyTipView?
    private var starredTagsTooltip: EasyTipView?

    private var followedTags = [TagsGroup]() {
        didSet {
            updateFollowButton()
        }
    }

    var joystickImage: NavigationJoystickViewImage {
        return .doItMyDamnSelf
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViewForBrawlStars()
        getFollowedTags()
        updateFollowButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setNeedsStatusBarAppearanceUpdate()
                
//        NavigationManager.shared.navigationOverlay?.deselectAllTabs()
        
//        NavigationManager.shared.navigationOverlay?.onAIButtonTapped = { [weak self] (_) in
//            guard let weakSelf = self, weakSelf.isVisible else { return }
//            weakSelf.dismissSelf()
//        }
        
        updateFollowButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        NavigationManager.shared.navigationOverlay?.deselectAllTabs()

        UIDevice.checkPushNotificationEnabled { [weak self] (isEnabled) in
            performOnMainThread {
                if !isEnabled {
                    self?.presentNotificationTutorialIfNeeded()
                } else {
                    self?.presentPlayNowTutorialIfNeeded()
                }
            }
        }
        
        updateFollowButton()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
//        NavigationManager.shared.navigationOverlay?.restoreSelectedTab()

//        NavigationManager.shared.navigationOverlay?.onAIButtonTapped = nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let vc = segue.destination as? PlayLaterSessionsViewController {
            
            vc.onCreateSessionCellTapped = { [weak self] in
                self?.presentGameSelectorView()
            }
            
            vc.onSessionSelected = { [weak self] (session) in
                
                AnalyticsManager.track(event: .gameSessionSelected, withParameters: ["session": session.identifier])

                // Show session details screen
                let detailsVC = UIStoryboard(name: AppConstants.Storyboards.ggHome, bundle: nil).instantiateViewController(withIdentifier: GameSessionDetailsContainerViewController.storyboardIdentifier) as! GameSessionDetailsContainerViewController
                detailsVC.session = session
                
                detailsVC.onDismiss = {
                    NavigationManager.shared.toggleJoystickNavigation(visible: true)
                    NavigationManager.shared.navigationOverlay?.toggleBottomNavigationBar(visible: true)
                }

                detailsVC.onGoToLobbyPressed = { [weak self] (session) in
                    
                    guard DataCoordinator.shared.isUserSignedIn() else {
                        // onboarding, go to create account screen
                        let viewController = UIStoryboard(name: AppConstants.Storyboards.onboarding, bundle: nil).instantiateViewController(withIdentifier: RegisterUserViewController.storyboardIdentifier)
                        let nav = GGNavigationViewController(rootViewController: viewController)
                        NavigationManager.shared.present(nav)
                        return
                    }
                    
                    detailsVC.dismissSelf(animated: true) {
                        self?.goToSession(session)
                    }
                }
                
                detailsVC.onSessionJoined = { [weak self, weak vc] (session) in
                    
                    guard DataCoordinator.shared.isUserSignedIn() else {
                        // onboarding, go to create account screen
                        let viewController = UIStoryboard(name: AppConstants.Storyboards.onboarding, bundle: nil).instantiateViewController(withIdentifier: RegisterUserViewController.storyboardIdentifier)
                        let nav = GGNavigationViewController(rootViewController: viewController)
                        NavigationManager.shared.present(nav)
                        return
                    }
                    
                    vc?.reload()

                    detailsVC.dismissSelf(animated: true) {
                        self?.goToSession(session)
                    }
                }
                
                detailsVC.onSessionLeft = { [weak vc] (_) in
                    vc?.reload()
                }
                
                NavigationManager.shared.toggleJoystickNavigation(visible: false)
                NavigationManager.shared.navigationOverlay?.toggleBottomNavigationBar(visible: false)

                let nav = GGNavigationViewController(rootViewController: detailsVC)
                nav.hidesBottomBarWhenPushed = true
                nav.isNavigationBarHidden = true
                nav.modalTransitionStyle = .crossDissolve
                nav.modalPresentationStyle = .overCurrentContext

                self?.present(nav, animated: true, completion: nil)
            }
                        
            gameSessionsVC = vc
        }
    }
    
    public func selectTags(_ tags: [Tag]) {
        tagsHeaderView.select(tags: tags)
    }
    
    private func showCreateLFGTooltipIfNeeded() {
        guard UserDefaults.standard.value(forKey: AppConstants.UserDefaults.Onboarding.ggHomeCreateLFGTooltipShown) as? Bool != true else { return }

        UserDefaults.standard.set(true, forKey: AppConstants.UserDefaults.Onboarding.ggHomeCreateLFGTooltipShown)
        UserDefaults.standard.synchronize()
        
        var prefs = EasyTipView.gamegetherPreferences
        prefs.drawing.arrowPosition = .bottom
        prefs.positioning.contentVInset = 10
        prefs.drawing.arrowWidth = 30
        prefs.drawing.arrowHeight = 16
        let tipView = EasyTipView.tooltip(withText: "Tap here to create an LFG post!", preferences: prefs)
        
        tipView.show(forView: createLFGButton, withinSuperview: self.view)
        tipView.animate()
        
        Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { (_) in
            tipView.dismiss()
        }
    }
    
    private func showPBTooltipIfNeeded() {
        guard pbTooltip == nil else { return }

        let count = UserDefaults.standard.integer(forKey: AppConstants.UserDefaults.Onboarding.ggHomePBTooltipShown)
        
        guard count < 2 else { return }
                        
        var prefs = EasyTipView.gamegetherPreferences
        prefs.drawing.arrowPosition = .bottom
        prefs.positioning.contentVInset = 5
        prefs.drawing.arrowWidth = 30
        prefs.drawing.arrowHeight = 16
        
        let tipView = EasyTipView.tooltip(withText: "PB means personal best", preferences: prefs, delegate: self)
        tipView.show(forView: tagsHeaderView, withinSuperview: self.view)
        tipView.animate(distance: -3)
        pbTooltip = tipView
        
        Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { (_) in
            tipView.dismiss()
        }
    }

    private func showStarredTagsTooltipIfNeeded() {
        guard starredTagsTooltip == nil else { return }
        
        let count = UserDefaults.standard.integer(forKey: AppConstants.UserDefaults.Onboarding.ggHomeStarredTagsTooltipShown)
        
        guard count < 3 else { return }
                        
        var prefs = EasyTipView.gamegetherPreferences
        prefs.drawing.arrowPosition = .bottom
        prefs.positioning.contentVInset = 5
        prefs.drawing.arrowWidth = 30
        prefs.drawing.arrowHeight = 16
        
        let tipView = EasyTipView.tooltip(withText: "tap here to star your favorite tags", preferences: prefs, delegate: self)
        tipView.show(forView: followTagsButton, withinSuperview: self.view)
        tipView.animate(distance: -3)
        starredTagsTooltip = tipView
        
        Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { (_) in
            tipView.dismiss()
        }
    }

    
    private func goToSession(_ session: GameSession) {
        guard let chatroomId = session.chatroomId else { return }
        // If there is a chatroom associated with this session, go to it now.
        
        FirebaseChat().fetchChatroom(chatroomId) { (chatroom) in
            guard let chatroom = chatroom else { return }
                
            performOnMainThread {
                let viewController = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: ChatViewController.storyboardIdentifier) as! ChatViewController
                viewController.chatroom = chatroom
                viewController.session = session
                NavigationManager.shared.push(viewController)
            }
        }
    }
    
    private func setupViewForBrawlStars() {
        DataCoordinator.shared.getGames { [weak self] (games, error) in
            guard let weakSelf = self, let brawlStars = games.filter({ $0.identifier == Constants.brawlStarsId }).first else { return }
            
            weakSelf.brawlStars = brawlStars
            
            performOnMainThread {
                weakSelf.tagsHeaderView.game = brawlStars
                weakSelf.tagsHeaderView.filter = .gameMode
                weakSelf.gameSessionsVC?.game = brawlStars
                weakSelf.gameSessionsVC?.tags = weakSelf.selectedTags
                weakSelf.gameSessionsVC?.reloadDataSource()
            }
        }
    }
    
    private func presentNotificationTutorialIfNeeded() {
        guard UserDefaults.standard.value(forKey: AppConstants.UserDefaults.Onboarding.pushNotificationAccessAlertShown) as? Bool != true else { return }
        
        let vc = UIStoryboard(name: AppConstants.Storyboards.ggHome, bundle: nil).instantiateViewController(withIdentifier: PushNotificationTutorialViewController.storyboardIdentifier) as! PushNotificationTutorialViewController
        
        vc.onDismiss = { [weak self] in
            NavigationManager.shared.toggleJoystickNavigation(visible: true)
            NavigationManager.shared.navigationOverlay?.toggleBottomNavigationBar(visible: true)
            
            UserDefaults.standard.set(true, forKey: AppConstants.UserDefaults.Onboarding.pushNotificationAccessAlertShown)
            UserDefaults.standard.synchronize()

            if !UIDevice.current.hasMicrophonePermission {
                self?.presentMicrophoneAccessTutorialIfNeeded()
            } else {
                self?.presentPlayNowTutorialIfNeeded()
            }
        }
        
        NavigationManager.shared.toggleJoystickNavigation(visible: false)
        NavigationManager.shared.navigationOverlay?.toggleBottomNavigationBar(visible: false)

        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        
        present(vc, animated: true, completion: nil)
    }
    
    private func presentMicrophoneAccessTutorialIfNeeded() {
        guard UserDefaults.standard.value(forKey: AppConstants.UserDefaults.Onboarding.microphoneAccessAlertShown) as? Bool != true else { return }
                
        let vc = UIStoryboard(name: AppConstants.Storyboards.ggHome, bundle: nil).instantiateViewController(withIdentifier: MicAccessTutorialViewController.storyboardIdentifier) as! MicAccessTutorialViewController
        
        vc.onDismiss = { [weak self] in
            NavigationManager.shared.toggleJoystickNavigation(visible: true)
            NavigationManager.shared.navigationOverlay?.toggleBottomNavigationBar(visible: true)
            
            UserDefaults.standard.set(true, forKey: AppConstants.UserDefaults.Onboarding.microphoneAccessAlertShown)
            UserDefaults.standard.synchronize()

            self?.presentPlayNowTutorialIfNeeded()
        }
        
        NavigationManager.shared.toggleJoystickNavigation(visible: false)
        NavigationManager.shared.navigationOverlay?.toggleBottomNavigationBar(visible: false)

        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        
        present(vc, animated: true, completion: nil)
    }

    private func presentPlayNowTutorialIfNeeded() {
        guard UserDefaults.standard.value(forKey: AppConstants.UserDefaults.Onboarding.ggHomeTutorialShown) as? Bool != true else { return }

        let vc = UIStoryboard(name: AppConstants.Storyboards.ggHome, bundle: nil).instantiateViewController(withIdentifier: PlayNowTutorialViewController.storyboardIdentifier) as! PlayNowTutorialViewController
        
        vc.onDismiss = { [weak self] in
            UserDefaults.standard.set(true, forKey: AppConstants.UserDefaults.Onboarding.ggHomeTutorialShown)
            UserDefaults.standard.synchronize()
            
            self?.showCreateLFGTooltipIfNeeded()
        }
        
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .crossDissolve
        
        present(vc, animated: true, completion: nil)
    }
    
    private func presentGameSelectorView() {
        let storyboard = UIStoryboard(name: AppConstants.Storyboards.scheduling, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: ScheduleSessionGameTagsModalViewController.storyboardIdentifier) as! ScheduleSessionGameTagsModalViewController
        
        vc.onGameSelected = { [weak self, weak vc] (game, tags) in
            guard let weakSelf = self, let vc = vc else { return }
            
            AnalyticsManager.track(event: .scheduleSessionGameSelected, withParameters: [
                "game": game.title,
                "tags": tags.compactMap({ $0.jsonValue })
                ])
                        
            let storyboard = UIStoryboard(name: AppConstants.Storyboards.lfg, bundle: nil)
            let lfgVC = storyboard.instantiateViewController(withIdentifier: CreateLFGViewController.storyboardIdentifier) as! CreateLFGViewController
            lfgVC.game = game
            lfgVC.tags = tags
            
            lfgVC.onPostCreated = { [weak self] (session) in
                self?.gameSessionsVC?.reloadDataSource()
                lfgVC.dismissSelf()
            }
            
            vc.dismissSelf(animated: true) {
                weakSelf.present(lfgVC, animated: true, completion: nil)
            }
        }

        vc.onCancelPressed = { [weak vc] in
            guard let vc = vc else { return }
            AnalyticsManager.track(event: .scheduleSessionSelectGameCancelTapped)
            vc.dismissSelf()
            NavigationManager.shared.toggleJoystickNavigation(visible: true)
            NavigationManager.shared.navigationOverlay?.toggleBottomNavigationBar(visible: true)
            NavigationManager.shared.navigationOverlay?.shouldShowNavigationBar = true
        }
        
        NavigationManager.shared.toggleJoystickNavigation(visible: false)
        NavigationManager.shared.navigationOverlay?.toggleBottomNavigationBar(visible: false)
        NavigationManager.shared.navigationOverlay?.shouldShowNavigationBar = false
        
        vc.selectedTags = selectedTags
        vc.selectedGame = brawlStars
        
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        NavigationManager.shared.present(vc)
    }

    private func getFollowedTags() {
       DataCoordinator.shared.getFollowedTags { [weak self] (followedTags, error) in
           if let tags = followedTags {
               performOnMainThread {
                   self?.followedTags = tags
               }
           }
       }
    }
    
    private func updateFollowButton() {
        guard isViewLoaded, let game = brawlStars else { return }
        performOnMainThread {
            
            let showFollowButton = self.tagsHeaderView.selectedTags.count > 0
            
            // show/hide the follow tags button
            self.followTagsButtonWidthConstraint.constant = showFollowButton ? Constants.followTagsButtonWidth : 0
            
            self.followTagsButton.isSelected = self.followedTags.containsTags(tags: self.tagsHeaderView.selectedTags, forGame: game.identifier)
            
            self.tagsHeaderView.leftInset = showFollowButton ? 0 : 8
            
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Interface Actions
    
    @IBAction func starredLobbiesButtonPressed(_ sender: Any) {
        
        AnalyticsManager.track(event: .addFriendPressed, withParameters: nil)

        guard DataCoordinator.shared.isUserSignedIn() else {
            // onboarding, go to create account screen
            let viewController = UIStoryboard(name: AppConstants.Storyboards.onboarding, bundle: nil).instantiateViewController(withIdentifier: RegisterUserViewController.storyboardIdentifier)
            let nav = GGNavigationViewController(rootViewController: viewController)
            NavigationManager.shared.present(nav)
            return
        }
        
        AnalyticsManager.track(event: .ggHomeStarredLobbiesPressed)
        
        let storyboard = UIStoryboard(name: AppConstants.Storyboards.ggHome, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: StarredLobbiesViewController.storyboardIdentifier) as! StarredLobbiesViewController
        
        vc.onTagsSelected = { [weak self, weak vc] (_, tags) in
            vc?.dismissSelf()
            self?.tagsHeaderView.select(tags: tags)
        }
        
        NavigationManager.shared.present(vc)
    }
    
    @IBAction func addFriendButtonpressed(_ sender: Any) {
        guard DataCoordinator.shared.isUserSignedIn() else {
            // onboarding, go to create account screen
            let viewController = UIStoryboard(name: AppConstants.Storyboards.onboarding, bundle: nil).instantiateViewController(withIdentifier: RegisterUserViewController.storyboardIdentifier)
            let nav = GGNavigationViewController(rootViewController: viewController)
            NavigationManager.shared.present(nav)
            return
        }
        
        AnalyticsManager.track(event: .addFriendPressed, withParameters: nil)
        
        let storyboard = UIStoryboard(name: AppConstants.Storyboards.friends, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: AddFriendsViewController.storyboardIdentifier)
        NavigationManager.shared.present(vc)
    }
    
    @IBAction func gameButtonPressed(_ sender: UIButton) {
        guard DataCoordinator.shared.isUserSignedIn() else {
            // onboarding, go to create account screen
            let viewController = UIStoryboard(name: AppConstants.Storyboards.onboarding, bundle: nil).instantiateViewController(withIdentifier: RegisterUserViewController.storyboardIdentifier)
            let nav = GGNavigationViewController(rootViewController: viewController)
            NavigationManager.shared.present(nav)
            return
        }
        
        presentGameSelectorView()
    }
        
    @IBAction func followTagsButtonPressed(_ sender: UIButton) {
        
        guard DataCoordinator.shared.isUserSignedIn() else {
            // onboarding, go to create account screen
            let viewController = UIStoryboard(name: AppConstants.Storyboards.onboarding, bundle: nil).instantiateViewController(withIdentifier: RegisterUserViewController.storyboardIdentifier)
            let nav = GGNavigationViewController(rootViewController: viewController)
            NavigationManager.shared.present(nav)
            return
        }
        
        let selectedTags = tagsHeaderView.selectedTags
        
        guard selectedTags.count > 0, let game = brawlStars else { return }
        
        DataCoordinator.shared.deleteBookmarkedTags(forGame: game.identifier)
        
        starredTooltip?.removeFromSuperview()
        
        if let group = followedTags.group(withTags: selectedTags, forGame: game.identifier) {
            // Already following, unfollow this tag group
            DataCoordinator.shared.unfollowTags(withIdentifier: group.identifier){ [weak self] (followedTags, error) in
                performOnMainThread {
                    guard error == nil else {
                        self?.presentGenericErrorAlert()
                        return
                    }
                    
                    if let tags = followedTags {
                        self?.followedTags = tags
                    }
                }
            }
            
        } else {
            // Not yet following these tags, follow them.
            
//            // Show the little starred tooltip above the button
//            let tooltip = UIImageView(image: #imageLiteral(resourceName: "lobbystarred"))
//            tooltip.translatesAutoresizingMaskIntoConstraints = false
//            view.addSubview(tooltip)
//            tooltip.constrain(attribute: .leading, toItem: sender, attribute: .leading, constant: -4)
//            tooltip.constrain(attribute: .bottom, toItem: sender, attribute: .top, constant: 6)
//            starredTooltip = tooltip
//
//            starredTooltipTimer?.invalidate()
//            starredTooltipTimer = nil
//
//            starredTooltipTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { (_) in
//                self.starredTooltip?.removeFromSuperview()
//            }
            
            DataCoordinator.shared.followTags(tags: selectedTags, forGame: game.identifier) { [weak self] (followedTags, error) in
                performOnMainThread {
                    guard error == nil else {
                        self?.presentGenericErrorAlert()
                        return
                    }
                    
                    if let tags = followedTags {
                        self?.followedTags = tags
                    }
                }
            }
        }
    }
}

extension GGHomeViewController: TagsHeaderCollectionViewDelegate {
    
    func tagsHeaderCollectionView(collectionView: TagsHeaderCollectionView, selectedTagsDidChange selectedTags: [Tag]) {
        
        if !selectedTags.isEmpty, !selectedTags.isGameModeTagSelected {
            // Force the user to select a game mode
            collectionView.select(tags: [])
            return
        }
        
        if selectedTags.count == 1, selectedTags.contains(where: { $0.identifier == Constants.powerPlayTagId }) {
            showPBTooltipIfNeeded()
        }

        self.selectedTags = selectedTags
        collectionView.filter = selectedTags.isGameModeTagSelected ? nil : .gameMode
        gameSessionsVC?.collectionView.reloadDataSource(withGame: brawlStars, andTags: selectedTags)
        updateFollowButton()
        
        if !selectedTags.isEmpty {
            showStarredTagsTooltipIfNeeded()
        }
    }
}

extension GGHomeViewController: EasyTipViewDelegate {
    
    func easyTipViewDidDismiss(_ tipView: EasyTipView) {
        
        if tipView == pbTooltip {
            pbTooltip = nil
            let count = UserDefaults.standard.integer(forKey: AppConstants.UserDefaults.Onboarding.ggHomePBTooltipShown)
            UserDefaults.standard.set(count + 1, forKey: AppConstants.UserDefaults.Onboarding.ggHomePBTooltipShown)
            UserDefaults.standard.synchronize()

        } else if tipView == starredTagsTooltip {
            starredTagsTooltip = nil
            let count = UserDefaults.standard.integer(forKey: AppConstants.UserDefaults.Onboarding.ggHomeStarredTagsTooltipShown)
            UserDefaults.standard.set(count + 1, forKey: AppConstants.UserDefaults.Onboarding.ggHomeStarredTagsTooltipShown)
            UserDefaults.standard.synchronize()
        }
    }
}
