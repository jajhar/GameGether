//
//  GameLobbyContainerViewController.swift
//  GameGether
//
//  Created by James Ajhar on 9/9/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit
import SDWebImage
import EasyTipView
import PKHUD

class GameLobbyContainerViewController: UIViewController {

    struct Constants {
        static let followTagsButtonWidth: CGFloat = 40.0
    }
    
    // MARK: - Outlets
    @IBOutlet weak var headerBarMarginView: UIView!
    @IBOutlet weak var headerBarView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.delegate = self
        }
    }
    @IBOutlet var scrollViewTagsSectionTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var sectionBarView: SectionBarView!
    
    @IBOutlet weak var tagsSectionContainerView: UIView!
    @IBOutlet weak var tagsHeaderCollectionView: TagsHeaderCollectionView! {
        didSet {
            tagsHeaderCollectionView.showSizeTags = false
            tagsHeaderCollectionView.tagsHeaderDelegate = self
        }
    }
    @IBOutlet weak var followTagsButton: UIButton!
    @IBOutlet weak var followTagsButtonWidthConstraint: NSLayoutConstraint!

    // MARK: - Properties
    var game: Game? {
        didSet {
            guard isViewLoaded, let game = game else { return }
            setupWithGame(game)
        }
    }
    
    var shouldRestoreBookmarkedTags: Bool = true    // True if the view should restore bookmarked tags from the cache on view load

    private var followedTags = [TagsGroup]() {
        didSet {
            updateFollowButton()
        }
    }
    
    @IBOutlet weak var tagsChatVCContainerView: UIView!
    private(set) var tagsChatViewController: TagsChatViewController? {
        didSet {
            tagsChatViewController?.onSelectedTagsChanged = { [weak self] (selectedTags) in
                guard let weakSelf = self else { return }
                
                weakSelf.tagsHeaderCollectionView.select(tags: selectedTags)
                
                if !selectedTags.isGameModeTagSelected {
                    // Force the user to select a game mode first before showing other lobbies
                    weakSelf.tagsHeaderCollectionView.filter = .gameMode
                    weakSelf.tagsHeaderCollectionView.select(tags: [])
                    
                } else {
                    weakSelf.tagsHeaderCollectionView.filter = nil
                }
                
                weakSelf.updateFollowButton()
            }
        }
    }
    
    @IBOutlet weak var gameSessionsVCContainerView: UIView!
    private(set) var gameSessionsViewController: LobbyGameSessionsViewController!
    
    private var starredTooltip: UIImageView?
    private var starredTooltipTimer: Timer?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        styleUI()
        
        sectionBarView.delegate = self
        sectionBarView.numberOfTabs = 2
        
        getFollowedTags()
        updateFollowButton()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showTagsTooltipIfNeeded()
        }
        
        if let game = game { setupWithGame(game) }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Handle the delegate for the swipe to dismiss gesture
        (navigationController as? GGNavigationViewController)?.panGestureRecognizer.delegate = self
        
//        NavigationManager.shared.navigationOverlay?.deselectAllTabs()

        SDWebImageDownloader().downloadImage(with: game?.iconImageURL, options: [], progress: nil) { (image, _, _, _) in
            performOnMainThread {
                if let image = image {
                    NavigationManager.shared.navigationOverlay?.joystickImage = .custom(image)
                }
            }
        }
        
        if tagsHeaderCollectionView?.selectedTags.hashedValue != tagsChatViewController?.selectedTags.hashedValue {
            tagsChatViewController?.selectedTags.sortByPriority()
            tagsHeaderCollectionView.select(tags: tagsChatViewController?.selectedTags ?? tagsHeaderCollectionView.selectedTags)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

//        NavigationManager.shared.navigationOverlay?.restoreSelectedTab()
    }
    
    private func setupWithGame(_ game: Game) {
        tagsChatViewController?.game = game
        tagsHeaderCollectionView.game = game
        gameSessionsViewController.game = game
        gameSessionsViewController.reloadSessions()

        if !tagsHeaderCollectionView.selectedTags.isGameModeTagSelected {
            // Force the user to select a platform first before showing other lobbies
            tagsHeaderCollectionView.filter = .gameMode
        } else {
            tagsHeaderCollectionView.filter = nil
        }
        
        styleUI()
        restoreBookmarkedTags()
    }
    
    private func styleUI() {
        titleLabel.font = AppConstants.Fonts.robotoBold(20).font
        titleLabel.textColor = .white
        
        headerBarView.backgroundColor = UIColor(hexString: game?.headerColor ?? "#000000")
        headerBarMarginView.backgroundColor = UIColor(hexString: game?.headerColor ?? "#000000")
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let vc = segue.destination as? TagsChatViewController {
            vc.game = game
            tagsChatViewController = vc
        } else if let vc = segue.destination as? LobbyGameSessionsViewController {
            vc.game = game
            
            vc.onSessionSelected = { [weak self] (session) in
                guard session.sessionType?.type != .request else { return }

                AnalyticsManager.track(event: .gameSessionSelected, withParameters: ["session": session.identifier])
                
                // Show session details screen
                let detailsVC = UIStoryboard(name: AppConstants.Storyboards.ggHome, bundle: nil).instantiateViewController(withIdentifier: GameSessionDetailsContainerViewController.storyboardIdentifier) as! GameSessionDetailsContainerViewController
                detailsVC.session = session
                
                detailsVC.onDismiss = {
                    NavigationManager.shared.toggleJoystickNavigation(visible: true)
                    NavigationManager.shared.navigationOverlay?.toggleBottomNavigationBar(visible: true)
                }
                
                detailsVC.onSessionJoined = { (_) in
                    vc.sessionsCollectionView.reloadData()
                }
                
                detailsVC.onSessionLeft = { (_) in
                    vc.sessionsCollectionView.reloadData()
                }
                                
                let nav = GGNavigationViewController(rootViewController: detailsVC)
                nav.hidesBottomBarWhenPushed = true
                nav.isNavigationBarHidden = true
                nav.modalTransitionStyle = .crossDissolve
                nav.modalPresentationStyle = .overCurrentContext

                self?.present(nav, animated: true, completion: nil)
            }

            gameSessionsViewController = vc
        }
    }
    
    @objc func keyboardWillChangeFrame(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        let endFrameY = endFrame.origin.y
        
        let keyboardWillShow = endFrameY < UIScreen.main.bounds.size.height
        scrollViewTagsSectionTopConstraint.isActive = !keyboardWillShow
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func restoreBookmarkedTags() {
        guard shouldRestoreBookmarkedTags, let game = game else { return }
        
        // Only restore once
        shouldRestoreBookmarkedTags = false
        
        DataCoordinator.shared.getBookmarkedTags(forGame: game.identifier) { [weak self] (bookmarkedTags, error) in
            guard error == nil, let bookmarkedTags = bookmarkedTags else {
                GGLog.error("Error: Failed to get bookmarked tags \(String(describing: error))")
                return
            }
            
            performOnMainThread {
                self?.tagsHeaderCollectionView.select(tags: bookmarkedTags)
            }
        }
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
    
    // MARK: - Interface Actions
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        
        let alertCounter = UserDefaults.standard.value(forKey: AppConstants.UserDefaults.activePartyAlertShown) as? Int ?? 0
        
        if tagsChatViewController?.activeParty != nil, alertCounter < 2 {
            // User has joined a party and should confirm they are leaving the screen and the party
            let alert = UIAlertController(title: "you are in an active party",
                                          message: "you can leave this lobby and we will place you in a room when the party is filled",
                                          preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "ok", style: .default, handler: { (_) in
                self.dismissSelf()
            }))
            
            UserDefaults.standard.set(alertCounter+1, forKey: AppConstants.UserDefaults.activePartyAlertShown)
            UserDefaults.standard.synchronize()
            
            alert.show()
            
            return
        }
        
        dismissSelf()
    }
    
    @IBAction func followTagsButtonPressed(_ sender: UIButton) {
        
        guard DataCoordinator.shared.isUserSignedIn() else {
            // onboarding, go to create account screen
            let viewController = UIStoryboard(name: AppConstants.Storyboards.onboarding, bundle: nil).instantiateViewController(withIdentifier: RegisterUserViewController.storyboardIdentifier)
            let nav = GGNavigationViewController(rootViewController: viewController)
            NavigationManager.shared.present(nav)
            return
        }
        
        let selectedTags = tagsHeaderCollectionView.selectedTags
        
        guard selectedTags.count > 0, let game = game else { return }
        
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
            
            // Show the little starred tooltip above the button
            let tooltip = UIImageView(image: #imageLiteral(resourceName: "lobbystarred"))
            tooltip.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(tooltip)
            tooltip.constrain(attribute: .leading, toItem: sender, attribute: .leading, constant: -4)
            tooltip.constrain(attribute: .bottom, toItem: sender, attribute: .top, constant: 6)
            starredTooltip = tooltip
            
            starredTooltipTimer?.invalidate()
            starredTooltipTimer = nil
            
            starredTooltipTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { (_) in
                self.starredTooltip?.removeFromSuperview()
            }
            
            if game.gamerTag.isEmpty {
                showEnterGamerTagAlert(forGame: game)
            }
            
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
    
    private func updateFollowButton() {
        guard isViewLoaded, let game = game else { return }
        performOnMainThread {
            
            let showFollowButton = self.tagsHeaderCollectionView.selectedTags.count > 0
            
            // show/hide the follow tags button
            self.followTagsButtonWidthConstraint.constant = showFollowButton ? Constants.followTagsButtonWidth : 0
            
            self.followTagsButton.isSelected = self.followedTags.containsTags(tags: self.tagsHeaderCollectionView.selectedTags, forGame: game.identifier)
            
            self.tagsHeaderCollectionView.leftInset = showFollowButton ? 0 : 8
            
            self.view.layoutIfNeeded()
        }
    }
    
    private func showEnterGamerTagAlert(forGame game: Game) {
        
        let gamerTagAlert = GamerTagAlertController(withgame: game,
                                                    title: "what's your \(game.title) gamertag?",
            message: "this will help others find your gamertag",
            cancelButtonTitle: "skip",
            onSaveAction: { (ign) in
                
                AnalyticsManager.track(event: .lobbyGamerTagModalSavePressed)
                
                HUD.show(.progress)
                
                DataCoordinator.shared.updateGamerTag(gamerTag: ign, forGame: game) { [weak self] (updatedGame, error) in
                    guard let weakSelf = self else { return }
                    
                    performOnMainThread {
                        HUD.hide()
                        
                        guard error == nil else {
                            weakSelf.presentGenericErrorAlert()
                            return
                        }
                        
                        // Update the local reference to the game
                        weakSelf.game = updatedGame
                    }
                }
        }, onCancelAction: {
            AnalyticsManager.track(event: .lobbyGamerTagModalSkipPressed)
        })
        
        gamerTagAlert.show()
    }
}

extension GameLobbyContainerViewController: SectionBarViewDelegate {
    
    func sectionBarView(view: SectionBarView, didSelectTabAt index: Int) {
        scrollTo(page: index)
    }
    
    func sectionBarView(view: SectionBarView, titleForTabAt index: Int) -> String {
        switch index {
        case 0:
            return "Play Now"
        case 1:
            return "Play Later"
        default:
            return ""
        }
    }
    
    func scrollTo(page: Int) {
        switch page {
        case 0:
            scrollView.scrollRectToVisible(tagsChatVCContainerView.frame, animated: true)
        case 1:
            scrollView.scrollRectToVisible(gameSessionsVCContainerView.frame, animated: true)
        default:
            break
        }
    }
}

extension GameLobbyContainerViewController: ShowsNavigationOverlay {
    
    var joystickImage: NavigationJoystickViewImage { return .doItMyDamnSelf }
    
    var navigationBarShouldDisplay: Bool { return true }

    var navigationViewShouldDisplay: Bool {
        guard isViewLoaded else { return true }
        // Only show the joystick navigation view if the profile quick view is not visible
        return tagsChatViewController?.profileQuickView == nil
    }
}

extension GameLobbyContainerViewController: TagsHeaderCollectionViewDelegate {
    
    func tagsHeaderCollectionView(collectionView: TagsHeaderCollectionView, canSelectTag tag: Tag, atIndexPath indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tagsHeaderCollectionView(collectionView: TagsHeaderCollectionView, selectedTagsDidChange selectedTags: [Tag]) {
        guard let game = game else { return }
        
        tagsChatViewController?.selectedTags = selectedTags
        gameSessionsViewController.tags = selectedTags
        
        titleLabel.text = "Looking for Group"
        
        guard selectedTags.count > 0 else {
            // Delete all bookmarks since none are selected
            DataCoordinator.shared.deleteBookmarkedTags(forGame: game.identifier)
            
            // Bookmark the general lobby
            UserDefaults.standard.set(true, forKey: AppConstants.UserDefaults.generalLobbyTagBookmark(for: game))
            UserDefaults.standard.synchronize()
            return
        }
        
        showStarredLobbyTooltipIfNeeded()
        
        UserDefaults.standard.set(false, forKey: AppConstants.UserDefaults.generalLobbyTagBookmark(for: game))
        UserDefaults.standard.synchronize()
        
        DataCoordinator.shared.bookmarkTags(tags: selectedTags, forGame: game.identifier) { (error) in
            if let error = error {
                GGLog.error("Error: Failed to bookmark tags \(error)")
            }
        }
    }
}

extension GameLobbyContainerViewController {
    
    // MARK: - Tooltips
    
    private func showTagsTooltipIfNeeded() {
        guard !DataCoordinator.shared.isUserSignedIn(),
            !UserDefaults.standard.bool(forKey: AppConstants.UserDefaults.Onboarding.tagsChatOnboardingTooltipShown) else {
                return
        }
        // We're in the onboarding flow. Show the onboarding tooltip if needed
        
        UserDefaults.standard.set(true, forKey: AppConstants.UserDefaults.Onboarding.tagsChatOnboardingTooltipShown)
        UserDefaults.standard.synchronize()
        
        var prefs = EasyTipView.gamegetherPreferences
        prefs.drawing.arrowPosition = .top
        prefs.positioning.contentVInset = 10
        let tipView = EasyTipView.tooltip(withText: "tap on the tags above to jump lobbies", preferences: prefs)
        
        tipView.dismissOnTap()
        tipView.show(forView: tagsSectionContainerView, withinSuperview: view)
        tipView.animate()
        
        Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { (_) in
            tipView.dismiss()
        }
    }
    
    private func showStarredLobbyTooltipIfNeeded() {
        guard isVisible, DataCoordinator.shared.isUserSignedIn() else { return }
        
        let count = UserDefaults.standard.integer(forKey: AppConstants.UserDefaults.Onboarding.starredLobbyTooltipShown)
        
        guard count < 2 else { return }
        
        UserDefaults.standard.set(count + 1, forKey: AppConstants.UserDefaults.Onboarding.starredLobbyTooltipShown)
        UserDefaults.standard.synchronize()
        
        view.layoutIfNeeded()
        
        let tipView = EasyTipView.tooltip(withText: "tap here to star your favorite lobbies")
        
        tipView.dismissOnTap()
        tipView.show(forView: followTagsButton, withinSuperview: view)
        tipView.animate()
        
        Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { (_) in
            tipView.dismiss()
        }
    }
}

extension GameLobbyContainerViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / scrollView.frame.width)
        sectionBarView.selectTab(atIndex: page)
    }
}

extension GameLobbyContainerViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        guard gestureRecognizer == (navigationController as? GGNavigationViewController)?.panGestureRecognizer, otherGestureRecognizer == scrollView.panGestureRecognizer else {
            return false
        }
        
        // Allow the user to swipe to go back if they are on the 1st page of content
        let page = Int(scrollView.contentOffset.x / scrollView.frame.width)
        return page == 0
    }
}

