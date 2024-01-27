//
//  TagsChatViewController.swift
//  GameGether
//
//  Created by James Ajhar on 9/13/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit
import SDWebImage
import PKHUD
import EasyTipView
import BABFrameObservingInputAccessoryView

class TagsChatViewController: UIViewController {

    struct Constants {
        static let defaultJoystickOffset: CGFloat = 0.0
        static let followTagsButtonWidth: CGFloat = 40.0
        static let defaultTextInputViewBottomOffset: CGFloat = 10.0
        static let partyTableViewMinHeight: CGFloat = 0.0
    }
    
    // MARK: - Outlets
    @IBOutlet weak var messagesTableView: MessagesTableView!
    @IBOutlet var messagesTableViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var textInputContainerView: UIView!
    @IBOutlet weak var textInputViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var textInputViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet var textInputViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var partiesEmptyStateImageView: UIImageView!
    @IBOutlet weak var bottomHeaderContainerView: UIView!
    
    @IBOutlet weak var startPartyButton: UIButton! {
        didSet {
            startPartyButton.tintColor = UIColor(hexString: "#7AD088")
            startPartyButton.titleLabel?.font = AppConstants.Fonts.robotoMedium(16).font
        }
    }
    
    @IBOutlet weak var partyTableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var partyObservationTableView: PartyTableView! {
        didSet {
            partyObservationTableView.maxVisibleRows = 2
        }
    }
    @IBOutlet weak var activeUsersTimelineView: ActiveUsersTimelineView!
    
    // MARK: - Properties
    var game: Game? {
        didSet {
            guard isViewLoaded else { return }
            setupWithGame()
        }
    }
    var showWalkthroughOnAppear: Bool = false   // set externally by presenting view controller
    
    private let firebaseChat = FirebaseChat()
    private let firebaseParty = FirebaseParty()
    
    private(set) var activeParty: FRParty? {
        didSet {
            // Not nil if the user is in a pending party (used for the leaving screen alert)
            FirebasePartyManager.shared.activeParty = activeParty
            startPartyButton.tintColor = activeParty != nil ? UIColor(hexString: "#CD3333") : UIColor(hexString: "#7AD088")
            updateStartPartyButton()
        }
    }
    private(set) var profileQuickView: ProfileQuickViewController?
    private var shouldShowParties: Bool = true
    
    private var textInputFieldMinWidth: CGFloat {
        return (view.bounds.width / 2) - 30 // -30pt for "half the size of the GG nav icon"
    }
    
    private var textInputFieldMaxWidth: CGFloat {
        return view.bounds.width
    }
        
    var selectedTags = [Tag]() {
        willSet {
            guard isViewLoaded else { return }
            
            if newValue.hashedValue != selectedTags.hashedValue {
                // If the chatroom changed. Leave the old one.
                leaveRoom()
            }
        }
        didSet {
            guard isViewLoaded else { return }
            
            if !selectedTags.isGameModeTagSelected {
                // Force the user to select a game mode first before showing other lobbies
                selectedTags = []
            }
            
            if selectedTags.count > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.showPartyOnboardingTooltipIfNeeded()
                }
            }
            
            messagesTableView.gameTags = selectedTags
//            observeParties()
            joinRoom()
            resizePartyTableView()
            updateStartPartyButton()
            
            onSelectedTagsChanged?(selectedTags)
        }
    }
    
    var onSelectedTagsChanged: (([Tag]) -> Void)?
    
    private let textInputView: TextInputView = {
        let nib = UINib(nibName: TextInputView.nibName, bundle: nil)
        let view = nib.instantiate(withOwner: self, options: nil).first as! TextInputView
        view.translatesAutoresizingMaskIntoConstraints = false
        view.toggleCollapsedState(collapsed: true)
        return view
    }()
    
    private var isMovingToParty: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let emptyStateTap = UITapGestureRecognizer(target: self, action: #selector(partiesEmptyStateTapped(_:)))
        partiesEmptyStateImageView.isUserInteractionEnabled = true
        partiesEmptyStateImageView.addGestureRecognizer(emptyStateTap)
        
        hideKeyboardWhenBackgroundTapped()
        
        messagesTableView.contentInset = UIEdgeInsets(top: 15, left: 0, bottom: 75, right: 0)

        firebaseChat.signIn()
        firebaseParty.signIn()
        
        textInputContainerView.addSubview(textInputView)
        textInputView.delegate = self
        textInputView.constrainToSuperview()
        textInputViewBottomConstraint?.constant = -Constants.defaultTextInputViewBottomOffset
        textInputViewWidthConstraint.constant = textInputFieldMinWidth
        
        let keyboardObserverInputView = BABFrameObservingInputAccessoryView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 44))
        textInputView.textView.inputAccessoryView = keyboardObserverInputView
        
        keyboardObserverInputView.keyboardFrameChangedBlock = { [weak self] (_, newFrame) in
            performOnMainThread {
                guard let weakSelf = self else { return }
                
                let offset: CGFloat = UIDevice.current.hasNotch ? 30 : 0
                var value: CGFloat = (weakSelf.view.window?.bounds.height ?? 0) - (keyboardObserverInputView.superview?.frame.minY ?? 0) - keyboardObserverInputView.frame.height - offset
                
                if value < Constants.defaultTextInputViewBottomOffset {
                    value = Constants.defaultTextInputViewBottomOffset
                }
                
                weakSelf.textInputViewBottomConstraint?.constant = -value
                weakSelf.view.layoutIfNeeded()
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
        
        messagesTableView.onUserTapped = { [weak self] (user, cell) in
            self?.showProfileQuickView(forUser: user)
        }
        
        setupWithGame()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        activeParty = FirebasePartyManager.shared.activeParty
        
        // Only show the joystick navigation view if the profile quick view is not visible
        NavigationManager.shared.toggleJoystickNavigation(visible: profileQuickView == nil, joystickOffset: joystickBottomOffset)
        
        NavigationManager.shared.navigationOverlay?.onAIButtonTapped = { [weak self] (_) in
            guard let weakSelf = self, weakSelf.isVisible else { return }
            
            if !DataCoordinator.shared.isUserSignedIn() {
                // onboarding, go to create account screen
                let viewController = UIStoryboard(name: AppConstants.Storyboards.onboarding, bundle: nil).instantiateViewController(withIdentifier: RegisterUserViewController.storyboardIdentifier)
                let nav = GGNavigationViewController(rootViewController: viewController)
                NavigationManager.shared.present(nav)
            }
        }
        
        if showWalkthroughOnAppear {
            showWalkthroughOnAppear = false
            showFindLobbyWalkthrough()
        }
        
        joinRoom()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NavigationManager.shared.navigationOverlay?.onAIButtonTapped = nil
        
        leaveRoom()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        leaveRoom()
    }
    
    private func updateStartPartyButton() {
        if activeParty != nil {
            startPartyButton.setTitle("leave party", for: .normal)
        } else {
            startPartyButton.setTitle(selectedTags.count > 0 ? "start a party" : "find a lobby", for: .normal)
        }
    }
    
    private func joinRoom() {
        guard let game = game else { return }
        firebaseChat.joinLobby(forGame: game, withTags: selectedTags)
        observeActiveUsers(forGame: game)
    }
    
    private func leaveRoom() {
        guard let game = game else { return }
        firebaseChat.leaveLobby(forGame: game, withTags: selectedTags)
    }
        
    private func setupWithGame() {
        guard let game = game else { return }
        
        messagesTableView.game = game
        messagesTableView.reloadMessagesDataSource()
        
//        observeParties()
        
        observeActiveUsers(forGame: game)
        
        if selectedTags.count == 0 {
            // Delete all bookmarks since none are selected
            DataCoordinator.shared.deleteBookmarkedTags(forGame: game.identifier)
            
            // Bookmark the general lobby
            UserDefaults.standard.set(true, forKey: AppConstants.UserDefaults.generalLobbyTagBookmark(for: game))
            UserDefaults.standard.synchronize()
        }
        
        view.layoutIfNeeded()
    }
    
    private func showPartyOnboardingTooltipIfNeeded() {
        guard !DataCoordinator.shared.isUserSignedIn(),
            !UserDefaults.standard.bool(forKey: AppConstants.UserDefaults.Onboarding.partyOnboardingTooltipShown) else {
                return
        }
        
        // We're in the onboarding flow. Show the onboarding tooltip if needed
        UserDefaults.standard.set(true, forKey: AppConstants.UserDefaults.Onboarding.partyOnboardingTooltipShown)
        UserDefaults.standard.synchronize()

        var prefs = EasyTipView.gamegetherPreferences
        prefs.drawing.arrowPosition = .bottom
        prefs.positioning.contentVInset = 10
        prefs.drawing.arrowWidth = 30
        prefs.drawing.arrowHeight = 16
        prefs.positioning.bubbleVInset = 20
        let tipView = EasyTipView.tooltip(withText: "look for gamers (LFG) above & party up!", preferences: prefs)
        
        tipView.dismissOnTap()
        tipView.show(forView: startPartyButton, withinSuperview: view)
        tipView.animate()
        
        Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { (_) in
            tipView.dismiss()
        }
    }
    
    private func observeActiveUsers(forGame game: Game) {
        
        // Reset state to empty
        activeUsersTimelineView.configure(withUsers: [])
        let selectedTags = self.selectedTags
        
        firebaseChat.observeUsers(forGame: game.identifier, withTags: selectedTags) { [weak self] (activeUsers, inactiveUsers) in
            guard let weakSelf = self else { return }
            
            // Reset state to empty
            weakSelf.activeUsersTimelineView.configure(withUsers: [])

            var usersToFetch = activeUsers.count > 0 ? activeUsers : inactiveUsers
            guard usersToFetch.count > 0 else { return }
            
            weakSelf.activeUsersTimelineView.set(state: activeUsers.count > 0 ? .currentlyInLobby : .recentlyInLobby)
            
            // Only fetch the first 4 users profile info
            let firstNUsers = usersToFetch.prefix(4)
            usersToFetch = Array(usersToFetch.dropFirst(4))
            
            DataCoordinator.shared.getProfiles(forUsersWithIds: firstNUsers.compactMap({ $0.identifier }), completion: { (remoteUsers, error) in
                guard weakSelf.selectedTags.hashedValue == selectedTags.hashedValue else { return }
                
                guard var remoteUsers = remoteUsers else {
                    weakSelf.activeUsersTimelineView.configure(withUsers: [])
                    return
                }
                
                remoteUsers.append(contentsOf: usersToFetch)
                
                weakSelf.activeUsersTimelineView.configure(withUsers: remoteUsers)
            })
        }
    }
    
    private func showProfileQuickView(forUser user: User) {
        let storyboard = UIStoryboard(name: AppConstants.Storyboards.profile, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: ProfileQuickViewController.storyboardIdentifier) as! ProfileQuickViewController
        profileQuickView = vc
        vc.user = user
        
        // Hide the joystick navigation view
        NavigationManager.shared.toggleJoystickNavigation(visible: false, joystickOffset: joystickBottomOffset)
        
        // Hide the floating audio overlay
        NavigationManager.shared.window?.toggleFloatingViewOverlay(visible: false)

        vc.onBackgroundTapped = { [weak self] (viewController) in
            guard let weakSelf = self else { return }
            
            viewController.animateOut {
                viewController.view.removeFromSuperview()
                viewController.removeFromParent()
                weakSelf.profileQuickView = nil
                AnalyticsManager.track(event: .quickViewClosed, withParameters: nil)
            }
            
            // Show the joystick navigation view
            NavigationManager.shared.toggleJoystickNavigation(visible: true, joystickOffset: weakSelf.joystickBottomOffset)
            
            // show the floating audio overlay
            NavigationManager.shared.window?.toggleFloatingViewOverlay(visible: true)
        }
        
        AnalyticsManager.track(event: .quickViewOpened, withParameters: nil)
        
        let presenter = self.parent ?? self
        vc.willMove(toParent: presenter)
        presenter.addChild(vc)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        presenter.view.addSubview(vc.view)
        vc.view.constrainToSuperview()
        vc.didMove(toParent: presenter)
        vc.animateIn()
    }
    
    private func toggleHeaders(visible: Bool) {
        messagesTableViewTopConstraint.isActive = visible
        bottomHeaderContainerView.isHidden = !visible
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func hidePartyTableView() {
        shouldShowParties = false
        self.partyTableViewHeightConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func showPartyTableView() {
        shouldShowParties = true
        resizePartyTableView()
    }
    
    private func resizePartyTableView() {
        guard selectedTags.count > 0, shouldShowParties else {
            // general lobby, hide the entire party section
            self.partyTableViewHeightConstraint.constant = 0
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
            return
        }
        
        // Resize the parties table
        let contentHeight = partyObservationTableView.contentHeight < Constants.partyTableViewMinHeight ? Constants.partyTableViewMinHeight : partyObservationTableView.contentHeight
        
        self.partyTableViewHeightConstraint.constant = contentHeight
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func keyboardWillChangeFrame(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo else { return }
        
        let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        let endFrameY = endFrame.origin.y
        let duration:TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
        let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        let animationCurve:UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)
        
        if endFrameY >= UIScreen.main.bounds.size.height {
            // Keyboard will hide
            textInputViewBottomConstraint?.constant = -Constants.defaultTextInputViewBottomOffset
            messagesTableView.contentInset = UIEdgeInsets(top: 15, left: 0, bottom: 75, right: 0)
            textInputViewWidthConstraint.constant = textInputFieldMinWidth
            textInputViewHeightConstraint.isActive = true
            textInputView.toggleCollapsedState(collapsed: true)
            showPartyTableView()
            toggleHeaders(visible: true)
            
        } else {
            // keyboard will show
            messagesTableView.contentInset = UIEdgeInsets(top: 15, left: 0, bottom: 15, right: 0)
            textInputViewWidthConstraint.constant = textInputFieldMaxWidth
            textInputViewHeightConstraint.isActive = false
            textInputView.toggleCollapsedState(collapsed: false)
            hidePartyTableView()
            toggleHeaders(visible: false)

            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0),
                           options: animationCurve,
                           animations: { self.view.layoutIfNeeded() },
                           completion: { (_) in
                            self.messagesTableView.scrollToBottom()
            })
        }
    }
    
    private func observeParties() {
        guard let game = game else { return }
        partyObservationTableView.partyTableViewDelegate = self
        partyObservationTableView.observeGame(game, withTags: selectedTags)
        FirebasePartyManager.shared.observeParties(forGame: game, withTags: selectedTags)
    }
    
    private func showPartySizeSelector() {
        guard let game = game else { return }
        
        guard selectedTags.sizeTags().isEmpty else {
            showPartySizeAlert(withSizes: selectedTags.sizeTags())
            return
        }
        
        DataCoordinator.shared.getTags(forGame: game.identifier) { [weak self] (remoteTags, error) in
            guard let weakSelf = self, error == nil, let remoteTags = remoteTags else {
                GGLog.error("Error: \(String(describing: error))")
                return
            }
            
            performOnMainThread {
                weakSelf.showPartySizeAlert(withSizes: remoteTags.sizeTags())
            }
        }
    }
    
    private func showPartySizeAlert(withSizes sizeTags: [Tag]) {
        guard let game = game else { return }

        let alert = UIAlertController(title: "select a party size", message: nil, preferredStyle: .actionSheet)

        var sizeTags = sizeTags
        sizeTags.sortByPriority()
        
        for sizeTag in sizeTags {

            alert.addAction(UIAlertAction(title: sizeTag.title, style: .default, handler: { (_) in
                // Create the party with this selected size tag
                var partyTags = self.selectedTags
                partyTags.append(sizeTag)
                
                let partySize = PartySize(size: UInt(sizeTag.size), title: sizeTag.title)
                FirebasePartyManager.shared.createParty(forGame: game, withSize: partySize, andTags: partyTags, completion: { [weak self] (createdParty) in
                    guard let weakSelf = self else { return }
                    
                    performOnMainThread {
                        if createdParty == nil {
                            weakSelf.presentGenericErrorAlert()
                        }
                    }
                })
            }))
        }
        
        alert.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    private func showFindLobbyWalkthrough() {
        let vc = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: "\(LobbyWalkthroughViewController.self)") as! LobbyWalkthroughViewController
        
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        
        vc.game = game
        
        vc.onBackgroundTapped = {
            vc.dismissSelf()
            NavigationManager.shared.toggleJoystickNavigation(visible: true)
        }
        
        vc.onCloseButtonPressed = {
            vc.dismissSelf()
            NavigationManager.shared.toggleJoystickNavigation(visible: true)
        }
        
        vc.onFindLobbyPressed = { [weak self] (tags) in
            guard let weakSelf = self else { return }
            weakSelf.selectedTags = tags
            vc.dismissSelf()
            NavigationManager.shared.toggleJoystickNavigation(visible: true)
        }
        
        NavigationManager.shared.present(vc)
    }
    
    // MARK: - Interface Actions
        
    @IBAction func startPartyButtonPressed(_ sender: UIButton) {
        
        guard DataCoordinator.shared.isUserSignedIn() else {
            // onboarding, go to create account screen
            let viewController = UIStoryboard(name: AppConstants.Storyboards.onboarding, bundle: nil).instantiateViewController(withIdentifier: RegisterUserViewController.storyboardIdentifier)
            let nav = GGNavigationViewController(rootViewController: viewController)
            NavigationManager.shared.present(nav)
            return
        }
        
        guard let game = game else { return }
        
        if let activeParty = FirebasePartyManager.shared.activeParty {
            // user is already in a party, leave it
            self.firebaseParty.leaveParty(activeParty, completion: { (error) in
                self.activeParty = nil
            })
            return
        }
        
        guard selectedTags.count > 0 else {
            // Show find lobby walkthrough since no tags are selected
            showFindLobbyWalkthrough()
            return
        }
        
        if selectedTags.sizeTags().count == 0 {
            // No size tag selected, show the party size selector
            showPartySizeSelector()
            return
            
        } else if selectedTags.sizeTags().count > 1 {
            // Multiple size tags found, show selector
            showPartySizeSelector()
            return
        }
        
        guard let sizeTag = selectedTags.sizeTags().first else {
            // No size tag selected, show the party size selector
            showPartySizeSelector()
            return
        }
        
        let partySize = PartySize(size: UInt(sizeTag.size), title: sizeTag.title)
        FirebasePartyManager.shared.createParty(forGame: game, withSize: partySize, andTags: selectedTags, completion: { [weak self] (createdParty) in
            guard let weakSelf = self else { return }
            
            performOnMainThread {
                if createdParty == nil {
                    weakSelf.presentGenericErrorAlert()
                }
            }
        })
    }
    
    @objc func partiesEmptyStateTapped(_ sender: UITapGestureRecognizer) {
        startPartyButtonPressed(startPartyButton)
    }
}

extension TagsChatViewController: TextInputViewDelegate {
    
    func textInputViewShouldBecomeFirstResponder(_ textInputView: TextInputView) -> Bool {
        guard DataCoordinator.shared.isUserSignedIn() else {
            // onboarding, go to create account screen
            let viewController = UIStoryboard(name: AppConstants.Storyboards.onboarding, bundle: nil).instantiateViewController(withIdentifier: RegisterUserViewController.storyboardIdentifier)
            let nav = GGNavigationViewController(rootViewController: viewController)
            NavigationManager.shared.present(nav)
            return false
        }
        return true
    }
    
    func textInputView(textInputView: TextInputView, heightDidChange height: CGFloat) {
        // NOP
    }
    
    func textInputView(textInputView: TextInputView, sendButtonTapped sendButton: UIButton, gif: Gif?) {
        guard let game = game, (!textInputView.text.isEmpty || gif != nil) else { return }
        
        SoundManager.shared.playSound(.messageSent)

        let messageType: FRMessageType = gif == nil ? .message : .media
        firebaseChat.sendMessage(ofType: messageType, text: textInputView.text, gif: gif, toGame: game, withTags: selectedTags)
    }
    
    func textInputView(textInputView: TextInputView, giphyButtonTapped giphyButton: UIButton) {
        
        AnalyticsManager.track(event: .giphyIconTapped)
        
        guard DataCoordinator.shared.isUserSignedIn() else {
            // onboarding, go to create account screen
            let viewController = UIStoryboard(name: AppConstants.Storyboards.onboarding, bundle: nil).instantiateViewController(withIdentifier: RegisterUserViewController.storyboardIdentifier)
            let nav = GGNavigationViewController(rootViewController: viewController)
            NavigationManager.shared.present(nav)
            return
        }
        
        let storyboard = UIStoryboard(name: AppConstants.Storyboards.giphy, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: GiphyViewController.storyboardIdentifier) as! GiphyViewController
        
        vc.onGifSelected = { [weak self] (gif) in
            self?.textInputView.setMediaURL(gif.url, withSize: gif.size ?? .zero)
            
            vc.dismissSelf(completion: {
                self?.textInputView.textView.becomeFirstResponder()
            })
        }
        
        vc.onBackButtonPressed = { [weak self] in
            vc.dismissSelf(completion: {
                self?.textInputView.textView.becomeFirstResponder()
            })
        }
        
        present(vc, animated: true, completion: nil)
    }
    
    func textInputView(textInputView: TextInputView, textDidChange text: String) {
        // NOP
    }
}

extension TagsChatViewController: PartyTableViewDelegate {

    func partyTableView(tableView: PartyTableView, canJoinParty party: FRParty) -> Bool {
        guard DataCoordinator.shared.isUserSignedIn() else {
            // onboarding, go to create account screen
            let viewController = UIStoryboard(name: AppConstants.Storyboards.onboarding, bundle: nil).instantiateViewController(withIdentifier: RegisterUserViewController.storyboardIdentifier)
            let nav = GGNavigationViewController(rootViewController: viewController)
            NavigationManager.shared.present(nav)
            return false
        }
        
        return FirebasePartyManager.shared.partyTableView(tableView: tableView, canJoinParty: party)
    }

    func partyTableView(tableView: PartyTableView, didJoinParty party: FRParty) {
        activeParty = party
    }

    func partyTableView(tableView: PartyTableView, didLeaveParty party: FRParty) {
        activeParty = nil
    }

    func partyTableView(tableView: PartyTableView, partiesDidUpdate parties: [FRParty]) {
        partiesEmptyStateImageView.isHidden = parties.count > 0
        resizePartyTableView()
        
        for party in parties {
            
            if party.containsLoggedInUser {
                // Redundancy is fun!
                activeParty = party
            }

            guard party.containsLoggedInUser,
                party.chatroomCreated,
                activeParty != nil else {
                    continue
            }
            // A chatroom has been created from this party.
            activeParty = nil
        }
    }
}
