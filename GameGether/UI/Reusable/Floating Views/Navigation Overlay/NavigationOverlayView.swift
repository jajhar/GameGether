//
//  NavigationOverlayView.swift
//  GameGether
//
//  Created by James Ajhar on 2/3/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit
import ViewAnimator
import FLAnimatedImage
import SDWebImage

enum NavigationJoystickViewImage {
    case defaultImage
    case custom(UIImage)
    case doItMyDamnSelf // Set to this if you want the view controller to handle the joystick image on its own. (Will not auto set the image)
    
    var image: UIImage {
        switch self {
        case .defaultImage, .doItMyDamnSelf:
            return #imageLiteral(resourceName: "Brawl Stars Nav Button")
        case .custom(let image):
            return image
        }
    }
}

class NavigationOverlayView: UIView {
    
    struct Constants {
        static let joystickBaseBottomOffset: CGFloat = 10.0
        static let joystickDisplacement: CGFloat = 0.8
        static let brawlStarsId = "5dca0736f8521650b21fe56a"
    }
    
    // MARK: Outlets
    @IBOutlet weak var joyStickView: JoyStickView! {
        didSet {
            joyStickView.lock = true // Disable swipe nav for now
        }
    }
    
    @IBOutlet weak var joystickBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var navigationBarView: UIView!
    @IBOutlet weak var navigationBarSretchableView: UIView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var gameNavCollectionView: GameNavCollectionView!
    @IBOutlet weak var profileNavButton: UIButton!
    @IBOutlet weak var chatNavButton: UIButton!
    @IBOutlet weak var profileNavImageView: AvatarInitialsImageView!
    @IBOutlet weak var chatNotificationLabel: UILabel!
    @IBOutlet weak var profileNavContainerView: UIView!
    @IBOutlet weak var profileNavSelectedCircleView: UIView!
    @IBOutlet weak var chatNavContainerView: UIView!
    
    @IBOutlet weak var onboardingTooltipView: UIView!
    @IBOutlet weak var onboardingTooltipBottomConstraint: NSLayoutConstraint!

    // MARK: Properties
    
//    override var bounds: CGRect {
//        didSet {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                // I dunno, the joystick just doesn't want to layout in the center without this dispatch wait...
//                self.joyStickView.resetJoystick()
//            }
//        }
//    }
    
    public var onAIButtonTapped: ((UIView) -> Void)?
    public var onGameNavigationDidShow: (() -> Void)?
    public var onGameNavigationDidHide: (() -> Void)?

    public var shouldShowNavigationBar: Bool = true {
        didSet {
            toggleBottomNavigationBar(visible: shouldShowNavigationBar)
        }
    }
    
    public var joystickImage: NavigationJoystickViewImage = .defaultImage {
        didSet {
            joyStickView.handleImage = joystickImage.image
        }
    }
    
    private(set) var selectedTab: GGTabBarViewControllerIndex = .profile
    private(set) var isNavigationBarShowing: Bool = true
    private(set) var isGameNavShowing: Bool = false
    
    private var shouldGameNavDismiss: Bool = false
    private var shouldNavBarDismiss: Bool = false
    private var isMovingJoystick: Bool = false
    private var currentJoyStickDirection: JoyStickDirection?
    private let firebaseChat = FirebaseChat()
    
    private var brawlStars: Game?
    private var brawlStarsImage: UIImage?
    
    // MARK: - Observers
    fileprivate var selectedTabDidChangeObservers = [AnyHashable: (GGTabBarViewControllerIndex) -> Void]()
    
    /// Selected tab did change
    public func addSelectedTabDidChangeObserver(_ observer: AnyHashable, onTabDidChange: @escaping (GGTabBarViewControllerIndex) -> Void) {
        selectedTabDidChangeObservers[observer] = onTabDidChange
    }
    
    public func removeSelectedTabDidChangeObserver(_ observer: AnyHashable) {
        selectedTabDidChangeObservers[observer] = nil
    }
    
    private func broadcastSelectedTabDidChangeEvent(tab: GGTabBarViewControllerIndex) {
        performOnMainThread {
            for (_, subscriber) in self.selectedTabDidChangeObservers {
                subscriber(tab)
            }
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view == self ? nil : view
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
    }
    
    public func setJoystickBottomOffset(to offset: CGFloat) {
        joystickBottomConstraint.constant = Constants.joystickBaseBottomOffset + offset
        layoutIfNeeded()
    }
    
    private func commonInit() {
        
        setupViewForBrawlStars()
        
        // Default tab is chat
        setSelectedTab(.home)
        
//        // Add a gaussian blur effect to the background view
//        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.regular)
//        let backgroundBlurEffectView = UIVisualEffectView(effect: blurEffect)
//        backgroundBlurEffectView.translatesAutoresizingMaskIntoConstraints = false
//        backgroundView.addSubview(backgroundBlurEffectView)
//        backgroundBlurEffectView.constrainToSuperview()
        
        chatNotificationLabel.font = AppConstants.Fonts.robotoMedium(12).font
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateProfileButtonImage), name: UserNotifications.updatedProfileImage.name, object: nil)
        updateProfileButtonImage()
        
        gameNavCollectionView.onBackgroundTapped = { [weak self] in
            guard let weakSelf = self else { return }
            // dismiss the game nav when the background is tapped
            weakSelf.toggleGameNavigationBar(visible: false)
            weakSelf.toggleBottomNavigationBar(visible: weakSelf.shouldShowNavigationBar)
        }

        joyStickView.monitor = { [weak self] (stickDirection, displacement, stickLocation) in
            guard let weakSelf = self else { return }
            
            // Remove any risidual hovering animation
            weakSelf.joyStickView.removeHoverAnimation()
            
            weakSelf.handleJoystickPoint(stickLocation)
            
            guard displacement >= Constants.joystickDisplacement else { return }
            
            if weakSelf.isMovingJoystick, weakSelf.currentJoyStickDirection == stickDirection { return }
            
            weakSelf.isMovingJoystick = true
            weakSelf.currentJoyStickDirection = stickDirection

            switch stickDirection {
            case .top:
                AnalyticsManager.track(event: .navigationOverlayJoystickSwipeUp, withParameters: nil)
                
                // Provide haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.prepare()
                generator.impactOccurred()

                // Show the game nav
                weakSelf.toggleGameNavigationBar(visible: true)

                // Show the bottom nav bar
                weakSelf.toggleBottomNavigationBar(visible: true)

            case .left, .right, .bottom:
                // Show the bottom nav bar only
                weakSelf.toggleBottomNavigationBar(visible: true)
            }
        }
        
        joyStickView.onHandleTapped = { [weak self] (handleView) in
            guard let weakSelf = self, !weakSelf.isMovingJoystick else { return }
            
            AnalyticsManager.track(event: .navigationOverlayGGButtonTapped)
            
            if let block = weakSelf.onAIButtonTapped {
                // let the handler do its own thing
                block(handleView)
            } else if DataCoordinator.shared.isUserSignedIn() {
//                // Default to showing starred lobbies
//                let viewController = UIStoryboard(name: AppConstants.Storyboards.ggHome, bundle: nil).instantiateViewController(withIdentifier: GGHomeViewController.storyboardIdentifier) as! GGHomeViewController
//
//                let nav = GGNavigationViewController(rootViewController: viewController)
//                nav.hidesBottomBarWhenPushed = true
//                nav.isNavigationBarHidden = true
//                nav.modalTransitionStyle = .crossDissolve
//                NavigationManager.shared.present(nav)
                weakSelf.setSelectedTab(.home)
            }
            
            // Remove any risidual hovering animation
            weakSelf.joyStickView.removeHoverAnimation()
        }
        
        joyStickView.onTouchesEnded = { [weak self] (stickDirection, displacement, stickLocation) in
            // This is called when the user has released the joystick
            guard let weakSelf = self else { return }
            
            weakSelf.isMovingJoystick = false

            if weakSelf.isGameNavShowing {
                let pointRelativeToGameNav = weakSelf.joyStickView.convert(stickLocation, to: weakSelf.gameNavCollectionView)
                let didSelectGame = weakSelf.gameNavCollectionView.selectCellAtPoint(pointRelativeToGameNav) != nil
                
                if weakSelf.shouldGameNavDismiss && !didSelectGame {
                    // If this is the next swipe up AND the user did not select a game, dismiss the game nav overlay.
                    //  Note: If the user selected a game, the game controller's presentation logic will handle the dismissal of the game nav.
                    weakSelf.toggleGameNavigationBar(visible: false)
                }
            }
            
            if weakSelf.isNavigationBarShowing {
               
                if weakSelf.selectNavItem(atPoint: stickLocation) {
                    // Provide haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.prepare()
                    generator.impactOccurred()
                }
                
                if weakSelf.shouldNavBarDismiss || !weakSelf.isGameNavShowing {
                    // Reset the bottom nav to whatever state it should be in
                    weakSelf.toggleBottomNavigationBar(visible: weakSelf.shouldShowNavigationBar)
                } else {
                    // Let's us know that on the NEXT swipe, the bottom nav can dismiss
                    weakSelf.shouldNavBarDismiss = weakSelf.isNavigationBarShowing
                }
            }

            // Let's us know that on the NEXT swipe UP, the game nav can dismiss
            weakSelf.shouldGameNavDismiss = weakSelf.isGameNavShowing
            
            // Reset the current stick direction value
            weakSelf.currentJoyStickDirection = nil
        }

        gameNavCollectionView.onAddNewGameSelected = { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.toggleGameNavigationBar(visible: false)

            let vc = UIStoryboard(name: AppConstants.Storyboards.onboarding, bundle: nil).instantiateViewController(withIdentifier: SelectGameViewController.storyboardIdentifier) as! SelectGameViewController
            
            vc.onGamesSelected = { [weak self] (games) in
                self?.gameNavCollectionView.reloadFavoriteGamesDataSource()
            }
            
            NavigationManager.shared.present(vc)
        }
        
        gameNavCollectionView.onGameSelected = { [weak self] (game) in
            guard let weakSelf = self else { return }
            
            AnalyticsManager.track(event: .navigationOverlayGameSelected, withParameters: ["game": game.title,
                                                                                           "gameId": game.identifier])
            
            if let vc = NavigationManager.topMostViewController() as? GameTagsViewController, vc.game?.identifier == game.identifier {
                // This game screen is already showing, stop here.
                weakSelf.toggleGameNavigationBar(visible: false)
                return
            }
            
            let presentationBlock = {
                // Present the lobby screen
                
                let lobbyVC = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: GameLobbyContainerViewController.storyboardIdentifier) as! GameLobbyContainerViewController
                lobbyVC.loadViewIfNeeded()
                lobbyVC.game = game

                let nav = GGNavigationViewController(rootViewController: lobbyVC)
                nav.hidesBottomBarWhenPushed = true
                nav.isNavigationBarHidden = true
                nav.modalTransitionStyle = .crossDissolve
                
                NavigationManager.shared.present(nav)
                                        
                // Add a bit of timing leeway with this garbage block
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                    // Dismiss the game nav only after the game view is fully presented.
                    weakSelf.toggleGameNavigationBar(visible: false)
                })
            }
            
            if NavigationManager.shared.tabBarController?.presentedViewController != nil {
                // Dismiss all modals before presenting this one. (Games should be root controllers)
                NavigationManager.shared.tabBarController?.dismissSelf(animated: false, completion: {
                    presentationBlock()
                })
            } else {
                presentationBlock()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            // I dunno, the joystick just doesn't want to layout in the center without this dispatch wait...
            self.joyStickView.resetJoystick()
        }
    }
    
    public func toggleBottomNavigationBar(visible: Bool) {
        
        guard isNavigationBarShowing != visible else { return }
        
        // Don't show the bottom nav if the user isn't signed in (used for onboarding screens)
        let newAlpha: CGFloat = visible ? 1.0 : 0.0

        // Reset flag
        shouldNavBarDismiss = false
        
        UIView.animate(withDuration: 0.1) {
            self.navigationBarView.alpha = newAlpha
            self.navigationBarSretchableView.alpha = newAlpha
        }

        if isNavigationBarShowing != visible {
            // Prevent duplicate animations
            isNavigationBarShowing = visible
            
            if visible {
                let zoomAnimation = AnimationType.zoom(scale: 0.2)
                UIView.animate(views: [profileNavImageView, chatNavButton],
                               animations: [zoomAnimation],
                               duration: 0.3)
            }
        }
    }
    
    public func toggleGameNavigationBar(visible: Bool) {
        guard isGameNavShowing != visible else { return}
        
        if visible {
            onboardingTooltipView.isHidden = false
        } else {
            onboardingTooltipView.isHidden = true
        }
        
        if visible {
            onGameNavigationDidShow?()
        } else {
            onGameNavigationDidHide?()
        }
        
        isGameNavShowing = visible
        let newAlpha: CGFloat = isGameNavShowing ? 1.0 : 0.0
       
        // Reset flag
        shouldGameNavDismiss = false
        
        // Adjust the nav bar background color
        navigationBarView.backgroundColor = visible ? .clear : .white
        navigationBarSretchableView.backgroundColor = visible ? .clear : .white
        
        if isGameNavShowing {
            gameNavCollectionView.reloadFavoriteGamesDataSource { [weak self] (_, _) in
                guard let weakSelf = self else { return }
                weakSelf.onboardingTooltipBottomConstraint.constant = weakSelf.gameNavCollectionView.contentHeight
                weakSelf.layoutIfNeeded()
            }
        }
        
        if newAlpha == 1 {
            gameNavCollectionView.isHidden = false
            backgroundView.isHidden = false
        }
        
        UIView.animate(withDuration: 0.15, animations: {
            self.gameNavCollectionView.alpha = newAlpha
            self.backgroundView.alpha = newAlpha
        }) { (_) in
            self.gameNavCollectionView.isHidden = newAlpha == 0
            self.backgroundView.isHidden = newAlpha == 0
        }
    }
    
    // MARK: Joystick drag and drop handling
    
    private func handleJoystickPoint(_ point: CGPoint) {
        let pointRelativeToGameNav = joyStickView.convert(point, to: gameNavCollectionView)
        gameNavCollectionView.animateCellAtPoint(pointRelativeToGameNav)
    
        // Bottom nav handling
        let pointRelativeToBottomNav = joyStickView.convert(point, to: navigationBarView)

        guard navigationBarView.bounds.contains(pointRelativeToBottomNav) else {
            UIView.animate(withDuration: 0.3) {
                self.profileNavImageView.transform = .identity
                self.chatNavButton.transform = .identity
            }
            return
        }
        
        var viewToAnimate: UIView?

        if profileNavContainerView.frame.contains(pointRelativeToBottomNav) {
            viewToAnimate = profileNavImageView
            
            UIView.animate(withDuration: 0.3) {
                self.chatNavButton.transform = .identity
            }
            
        } else if chatNavContainerView.frame.contains(pointRelativeToBottomNav) {
            viewToAnimate = chatNavButton
            
            UIView.animate(withDuration: 0.3) {
                self.profileNavImageView.transform = .identity
            }
            
        } else {
            UIView.animate(withDuration: 0.3) {
                self.profileNavImageView.transform = .identity
                self.chatNavButton.transform = .identity
            }
        }
        
        if let view = viewToAnimate {
            UIView.animate(withDuration: 0.3) {
                view.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            }
        }
    }
    
    /// Call to select a bottom navigation item at a specific point
    ///
    /// - Parameter point: The point of the nav item to select
    /// - Returns: True if a nav item was selected or false if nothing was found at the given point
    @discardableResult
    private func selectNavItem(atPoint point: CGPoint) -> Bool {
        let pointRelativeToBottomNav = joyStickView.convert(point, to: navigationBarView)
        guard navigationBarView.bounds.contains(pointRelativeToBottomNav) else {
            // Point is out of bounds of the navigation view. Select nothing.
            return false
        }
        
        if profileNavContainerView.frame.contains(pointRelativeToBottomNav) {
            profileNavButtonPressed(profileNavButton)
            AnalyticsManager.track(event: .navigationOverlayProfileButtonSwiped, withParameters: nil)
            return true
            
        } else if chatNavContainerView.frame.contains(pointRelativeToBottomNav) {
            chatNavButtonPressed(chatNavButton)
            AnalyticsManager.track(event: .navigationOverlayChatButtonSwiped, withParameters: nil)
            return true
        }
        
        // Nothing selected
        return false
    }
    
    @objc func updateProfileButtonImage() {
        guard let user = DataCoordinator.shared.signedInUser else {
            // Not signed in, show default user pic
            profileNavImageView.image = #imageLiteral(resourceName: "default avatar")
            return
        }
        profileNavImageView.configure(withUser: user, andFont: AppConstants.Fonts.robotoRegular(16).font)
    }
    
    // MARK: - Chat Notifications
    
    public func beginObservingUnreadMessageCount() {
        firebaseChat.signIn { [weak self] (_, _) in
            self?.firebaseChat.observeTotalUnreadMessageCount(completion: { (totalUnreadCount) in
                guard let weakSelf = self else { return }
                
                performOnMainThread {
                    weakSelf.chatNotificationLabel.isHidden = totalUnreadCount == 0
                    weakSelf.chatNotificationLabel.text = totalUnreadCount < 100 ? "\(totalUnreadCount)" : "99"
                }
            })
        }
    }

    // MARK: Interface Actions
    
    @IBAction func profileNavButtonPressed(_ sender: UIButton) {
        guard DataCoordinator.shared.isUserSignedIn() else {
            // onboarding, go to create account screen
            let viewController = UIStoryboard(name: AppConstants.Storyboards.onboarding, bundle: nil).instantiateViewController(withIdentifier: RegisterUserViewController.storyboardIdentifier)
            let nav = GGNavigationViewController(rootViewController: viewController)
            NavigationManager.shared.present(nav)
            return
        }
        
        toggleGameNavigationBar(visible: false)
//        toggleBottomNavigationBar(visible: shouldShowNavigationBar)
        NavigationManager.shared.tabBarController?.dismissSelf()
        setSelectedTab(.profile)
        AnalyticsManager.track(event: .navigationOverlayProfileButtonTapped, withParameters: nil)
    }
    
    @IBAction func chatNavButtonPressed(_ sender: UIButton) {
        guard DataCoordinator.shared.isUserSignedIn() else {
            // onboarding, go to create account screen
            let viewController = UIStoryboard(name: AppConstants.Storyboards.onboarding, bundle: nil).instantiateViewController(withIdentifier: RegisterUserViewController.storyboardIdentifier)
            let nav = GGNavigationViewController(rootViewController: viewController)
            NavigationManager.shared.present(nav)
            return
        }
        
        toggleGameNavigationBar(visible: false)
//        toggleBottomNavigationBar(visible: shouldShowNavigationBar)
        NavigationManager.shared.tabBarController?.dismissSelf()
        setSelectedTab(.chat)
        AnalyticsManager.track(event: .navigationOverlayChatButtonTapped, withParameters: nil)
    }
    
    func setSelectedTab(_ tab: GGTabBarViewControllerIndex) {

        switch tab {
        case .profile:
            profileNavSelectedCircleView.isHidden = false
            chatNavButton.setImage(#imageLiteral(resourceName: "Chat"), for: .normal)
            joystickImage = .custom(#imageLiteral(resourceName: "Brawl Stars Nav Button"))
            
        case .home:
            profileNavSelectedCircleView.isHidden = true
            chatNavButton.setImage(#imageLiteral(resourceName: "Chat"), for: .normal)
            
            if let image = brawlStarsImage {
               joystickImage = .custom(image)
            } else {
                SDWebImageDownloader().downloadImage(with: brawlStars?.iconImageURL, options: [], progress: nil) { [weak self] (image, _, _, _) in
                    guard let image = image else { return }
                    self?.brawlStarsImage = image
                    
                    performOnMainThread {
                        self?.joystickImage = .custom(image)
                    }
                }
            }
            
        case .chat:
            profileNavSelectedCircleView.isHidden = true
            chatNavButton.setImage(#imageLiteral(resourceName: "Chat_Filled"), for: .normal)
            joystickImage = .custom(#imageLiteral(resourceName: "Brawl Stars Nav Button"))
        }
        
        selectedTab = tab
        NavigationManager.shared.setSelectedTab(tab)
        
        broadcastSelectedTabDidChangeEvent(tab: selectedTab)
    }
    
    private func setupViewForBrawlStars() {
        DataCoordinator.shared.getGames { [weak self] (games, error) in
            guard let weakSelf = self, let brawlStars = games.filter({ $0.identifier == Constants.brawlStarsId }).first else { return }
            weakSelf.brawlStars = brawlStars
            weakSelf.setSelectedTab(weakSelf.selectedTab)
        }
    }

    
//    func deselectAllTabs() {
//        profileNavSelectedCircleView.isHidden = true
//        chatNavButton.setImage(#imageLiteral(resourceName: "Chat"), for: .normal)
//    }
//    
//    func restoreSelectedTab() {
//        switch selectedTab {
//        case .profile:
//            profileNavSelectedCircleView.isHidden = false
//            chatNavButton.setImage(#imageLiteral(resourceName: "Chat"), for: .normal)
//        case .home:
//            profileNavSelectedCircleView.isHidden = true
//            chatNavButton.setImage(#imageLiteral(resourceName: "Chat"), for: .normal)
//        case .chat:
//            profileNavSelectedCircleView.isHidden = true
//            chatNavButton.setImage(#imageLiteral(resourceName: "Chat_Filled"), for: .normal)
//        }
//    }
}
