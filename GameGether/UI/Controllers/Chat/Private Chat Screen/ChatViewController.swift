//
//  ChatViewController.swift
//  GameGether
//
//  Created by James Ajhar on 7/24/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit
import GrowingTextView
import PKHUD
import BABFrameObservingInputAccessoryView
import SDWebImage

class ChatViewController: UIViewController {

    struct Constants {
        static let defaultJoystickOffset: CGFloat = 0.0
        static let defaultTextInputViewBottomOffset: CGFloat = 10.0
    }
    
    // MARK: Outlets
    @IBOutlet weak var messagesTableView: MessagesTableView!
    @IBOutlet weak var inputViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var chatAvatarsCollectionView: ChatAvatarsCollectionView!
    @IBOutlet weak var textInputContainerView: UIView!
    @IBOutlet var textInputContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var dividerView: UIView!
    @IBOutlet weak var friendsNotificationHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var friendRequestViewTitleLabel: UILabel!
    @IBOutlet weak var friendRequestViewSubtitleLabel: UITextViewNoPadding!
    @IBOutlet weak var sendFriendRequestButton: UIButton!
    @IBOutlet weak var acceptFriendRequestButton: UIButton!
    @IBOutlet weak var cancelFriendRequestButton: UIButton!
    @IBOutlet weak var chatIndicatorContainerView: UIView!
    @IBOutlet weak var textInputViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var gameSessionBannerHeightConstraint: NSLayoutConstraint!
    
    // MARK: Properties
    var chatroom: FRChatroom?
    var session: GameSession?
    var user: User?
    private let firebaseChat = FirebaseChat()
    private var isNotificationMinimized: Bool = true
    private var friendRequest: UserRelationship?
    private var profileQuickView: ProfileQuickViewController?
    private var fetchUsersTimer: Timer?
    private var friendNotificationWasPresented: Bool = false
    private var typingUsers = [String]() // User identifiers
    
    private var textInputFieldMinWidth: CGFloat {
        return view.bounds.width - (FloatingAudioView.activeView?.bounds.width ?? 0) - 14 // -14 for 7pt margins
    }
    
    private var textInputFieldMaxWidth: CGFloat {
        return view.bounds.width
    }

    var navigationViewShouldDisplay: Bool {
        return false
    }
    
    var floatingViewOverlayShouldDisplay: Bool {
        return profileQuickView == nil
    }
    
    var navigationBarShouldDisplay: Bool = false
    
    private let textInputView: TextInputView = {
        let nib = UINib(nibName: TextInputView.nibName, bundle: nil)
        let view = nib.instantiate(withOwner: self, options: nil).first as! TextInputView
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let chatIndicatorView: ChatIndicatorView = {
        let nib = UINib(nibName: ChatIndicatorView.nibName, bundle: nil)
        let view = nib.instantiate(withOwner: self, options: nil).first as! ChatIndicatorView
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        disableDarkMode()
        
        messagesTableView.contentInset = UIEdgeInsets(top: 15, left: 0, bottom: 75, right: 0)
        inputViewBottomConstraint?.constant = -Constants.defaultTextInputViewBottomOffset

        UIDevice.current.requestMicrophonePermission()
        
        firebaseChat.signIn()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
        
        hideKeyboardWhenBackgroundTapped()
        
        AgoraManager.shared.delegate = self
        
        // Chat input field
        textInputContainerView.addSubview(textInputView)
        textInputView.delegate = self
        textInputView.constrainToSuperview()
        toggleTextInputView(expanded: false)
        
        let keyboardObserverInputView = BABFrameObservingInputAccessoryView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 44))
        textInputView.textView.inputAccessoryView = keyboardObserverInputView
        
        keyboardObserverInputView.keyboardFrameChangedBlock = { [weak self] (_, newFrame) in
            performOnMainThread {
                guard let weakSelf = self else { return }
                
                let offset: CGFloat = UIDevice.current.hasNotch ? 30 : 0
                var value: CGFloat = weakSelf.view.frame.height - (keyboardObserverInputView.superview?.frame.minY ?? 0) - keyboardObserverInputView.frame.height - offset

                if value < Constants.defaultTextInputViewBottomOffset {
                    value = Constants.defaultTextInputViewBottomOffset
                }
                
                weakSelf.inputViewBottomConstraint?.constant = -value
                
                weakSelf.view.layoutIfNeeded()
            }
        }
        
        // Typing indicators for when users are typing
        chatIndicatorContainerView.addSubview(chatIndicatorView)
        chatIndicatorView.constrainToSuperview()
        chatIndicatorContainerView.isHidden = true
                
        friendsNotificationHeightConstraint.constant = 0
        
        messagesTableView.messageDelegate = self
        
        messagesTableView.onUserTapped = { [weak self] (user, cell) in
            self?.showProfileQuickView(forUser: user)
        }
        
        chatAvatarsCollectionView.onUserTapped = { [weak self] (user) in
            self?.showProfileQuickView(forUser: user)
        }
        
        fetchChatroomIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupWithChatroom()
        
        // Hide the joystick nav on this screen
        NavigationManager.shared.toggleJoystickNavigation(visible: false)
        
        textInputViewWidthConstraint.constant = textInputFieldMinWidth
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let chatroom = chatroom {
            firebaseChat.setTypingStatus(isTyping: false, inChatroom: chatroom)
        }
        
        // Show the back button so the user can get back here when they want to
        FloatingAudioView.activeView?.shouldShowBackButton = true
        FloatingAudioView.activeView?.onCallLeft = nil
        
        if AgoraManager.shared.activeChannel == nil {
            // Given the user is NOT in an active voice chat session, hide the audio overlay
            toggleAudioView(visible: false)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        
        if let vc = segue.destination as? ChatroomSessionBannerViewController {
            
            guard let session = session else {
                // Hide the banner
                gameSessionBannerHeightConstraint.constant = 0
                view.layoutIfNeeded()
                return
            }
            vc.session = session
            view.layoutIfNeeded()
        }
    }
    
    private func fetchChatroomIfNeeded() {
        guard let user = user else {
            setupWithChatroom()
            return
        }
        
        HUD.show(.progress)
        firebaseChat.createPrivateRoom(withUserIds: [user.identifier], completion: { [weak self] (chatroom) in
            performOnMainThread {
                HUD.hide()
                guard let chatroom = chatroom else { return }
                
                self?.chatroom = chatroom
                self?.setupWithChatroom()
                self?.toggleTextInputView(expanded: false)
            }
        })
    }
    
    private func setupWithChatroom() {
        guard let chatroom = chatroom else { return }
        
        messagesTableView.chatroom = chatroom
        firebaseChat.resetMyUnreadCount(inChatroom: chatroom)
        beginObservingUsers()
        toggleAudioView(visible: true)

        if FloatingAudioView.activeView?.chatroom?.identifier != chatroom.identifier {
            // we're in a different chatroom, show the back button
            FloatingAudioView.activeView?.shouldShowBackButton = true
        } else {
            // we're in the original chatroom, hide the back button
            FloatingAudioView.activeView?.shouldShowBackButton = false
        }
        
        // Only show the floating audio view if the profile quick view is not visible
        NavigationManager.shared.window?.toggleFloatingViewOverlay(visible: profileQuickView == nil)
        
        firebaseChat.observeChatroom(chatroom) { [weak self] (chatroom) in
            guard let weakSelf = self else { return }
            
            performOnMainThread {
                
                if let existingChatroom = weakSelf.chatroom {
                    existingChatroom.update(from: chatroom)
                } else {
                    weakSelf.chatroom = chatroom
                }
                
                weakSelf.messagesTableView.chatroom = weakSelf.chatroom
            }
        }
        
        // Observe typing users
        firebaseChat.observeTypingUsers(inChatroom: chatroom, onUpdate: { [weak self] (typingUsers) in
            guard let weakSelf = self, !weakSelf.typingUsers.elementsEqual(typingUsers) else { return }

            weakSelf.typingUsers = typingUsers
            
            performOnMainThread {
                weakSelf.chatIndicatorContainerView.isHidden = typingUsers.isEmpty
                
                DataCoordinator.shared.getProfiles(forUsersWithIds: typingUsers) { (users, error) in
                    guard error == nil else {
                        GGLog.error(error?.localizedDescription ?? "unknown error")
                        return
                    }
                    weakSelf.chatIndicatorView.users = users
                }
            }
        })
    }
    
    private func toggleAudioView(visible: Bool) {
        guard let chatroom = chatroom else { return }
        
        NavigationManager.shared.toggleActiveCallView(visible: visible, forChatroom: chatroom)

        FloatingAudioView.activeView?.onCallJoined = { [weak self] (callChatroom) in
            guard let weakSelf = self else { return }
            // Send a push notification
            weakSelf.firebaseChat.sendNotifications(toChatroom: chatroom,
                                                    ofType: .voiceChat,
                                                    withMessage: "wants to start voice")
        }
        
        FloatingAudioView.activeView?.onCallLeft = { [weak self] (callChatroom) in
            guard self != nil else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                // wait a sec...
                self?.toggleAudioView(visible: true)
            })
        }
        
        FloatingAudioView.activeView?.onUserTapped = { [weak self] (user) in
            self?.showProfileQuickView(forUser: user)
        }
    }
    
    private func beginObservingUsers() {
        fetchUsersTimer?.invalidate()
        fetchUsersTimer = nil
        
        fetchUsers()
        
        fetchUsersTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] (_) in
            self?.fetchUsers(breakCache: true)
        }
    }
    
    private func fetchUsers(breakCache: Bool = false) {
        guard let chatroom = chatroom else { return }
        
        chatroom.fetchUsers(breakCache: breakCache) { [weak self] (users) in
            performOnMainThread {
                guard let strongself = self, let users = users else { return }
                strongself.chatAvatarsCollectionView.users = users
                
                if breakCache || strongself.friendRequest == nil {
                    if !chatroom.isGroupChat, let user = users.first {
                        strongself.getFriendStatus(forUser: user.identifier)
                    } else {
                        strongself.hideFriendNotification()
                    }
                }
            }
        }
    }
    
    /// Call to expand or condense the text input view's width
    ///
    /// - Parameter expanded: true if it should expand to full screen width
    private func toggleTextInputView(expanded: Bool) {
        if expanded {
            textInputViewWidthConstraint.constant = textInputFieldMaxWidth
            textInputContainerHeightConstraint.isActive = false
        } else {
            textInputViewWidthConstraint.constant = textInputFieldMinWidth
            textInputContainerHeightConstraint.isActive = true
            messagesTableView.contentInset = UIEdgeInsets(top: 15, left: 0, bottom: 75, right: 0)
        }
    }
    
    private func goToNewMessageView() {
//        AnalyticsManager.track(event: "create_chat_tapped", withParameters: nil)
        
        let storyboard = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: NewMessageViewController.storyboardIdentifier) as! NewMessageViewController
        
        chatroom?.fetchUsers(breakCache: false, completion: { [weak vc] (users) in
            performOnMainThread {
                guard let vc = vc else { return }
                
                vc.initialUsersToPopulate = users ?? []

                vc.onChatroomCreation = { (newMessageVC, chatroom) in
                    newMessageVC.dismissSelf(animated: true, completion: {
                        // Navigate to the new private chatroom
                        let viewController = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: ChatViewController.storyboardIdentifier) as! ChatViewController
                        viewController.chatroom = chatroom
                        NavigationManager.shared.push(viewController)
                    })
                }
                
                NavigationManager.shared.present(vc)
            }
        })
    }
    
    private func getFriendStatus(forUser userId: String) {
        // Ignore LFG sessions
        guard let chatroom = chatroom, chatroom.session == nil else { return }
        
        DataCoordinator.shared.getFriendStatus(forUser: userId, completion: { [weak self] (friendRequest, error) in
            guard let strongself = self else { return }
            
            guard error == nil else {
                GGLog.error("\(String(describing: error))")
                return
            }
            
            guard let friendRequest = friendRequest else { return }
            
            performOnMainThread {
                strongself.friendRequest = friendRequest
                
                switch friendRequest.status {
                case .none:
                    strongself.friendRequestViewTitleLabel.text = "you aren't friends yet"
                    strongself.friendRequestViewSubtitleLabel.text = "you can message each other"
                    strongself.sendFriendRequestButton.isHidden = false
                    strongself.cancelFriendRequestButton.isHidden = true
                    strongself.acceptFriendRequestButton.isHidden = true
                    
                    if !strongself.friendNotificationWasPresented {
                        strongself.expandFriendNotification()
                    }
                    
                case .pending:
                    
                    chatroom.fetchUsers() { (users) in
                        guard let users = users else { return }
                        
                        let username = users.first?.ign ?? ""
                        
                        if friendRequest.wasSentToMe {
                            strongself.friendRequestViewTitleLabel.text = "\(username) sent you a friend request"
                            strongself.friendRequestViewSubtitleLabel.text = "when you become friends, you will receive online notifications."
                            strongself.sendFriendRequestButton.isHidden = true
                            strongself.cancelFriendRequestButton.isHidden = true
                            strongself.acceptFriendRequestButton.isHidden = false
                        } else {
                            strongself.friendRequestViewTitleLabel.text = "you sent \(username) a friend request"
                            strongself.sendFriendRequestButton.isHidden = true
                            strongself.cancelFriendRequestButton.isHidden = false
                            strongself.acceptFriendRequestButton.isHidden = true
                        }
                        
                        if !strongself.friendNotificationWasPresented {
                            strongself.expandFriendNotification()
                        }
                    }
                    
                case .accepted:
                    strongself.hideFriendNotification()
                    
                case .blocked:
                    break
                }
            }
        })
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
            inputViewBottomConstraint?.constant = -Constants.defaultTextInputViewBottomOffset
            toggleTextInputView(expanded: false)
            messagesTableView.contentInset = UIEdgeInsets(top: 15, left: 0, bottom: 75, right: 0)

        } else {
            // Keyboard will show
            toggleTextInputView(expanded: true)
            messagesTableView.contentInset = UIEdgeInsets(top: 15, left: 0, bottom: 15, right: 0)
            
            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0),
                           options: animationCurve,
                           animations: { self.view.layoutIfNeeded() },
                           completion: { (_) in
                            self.messagesTableView.scrollToBottom()
            })
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        SDImageCache.shared().clearMemory()
    }
    
    private func toggleFriendNotificationView() {
        isNotificationMinimized ? expandFriendNotification() : minimizeFriendNotification()
    }
    
    private func hideFriendNotification() {
        dividerView.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            self.friendsNotificationHeightConstraint.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    
    private func minimizeFriendNotification() {
        guard isNotificationMinimized == false else { return }
        
        isNotificationMinimized = true
        dividerView.isHidden = true
        
        UIView.animate(withDuration: 0.3) {
            self.friendsNotificationHeightConstraint.constant = 55
            self.view.layoutIfNeeded()
        }
    }
    
    private func expandFriendNotification() {
        guard isNotificationMinimized == true else { return }

        friendNotificationWasPresented = true
        isNotificationMinimized = false
        dividerView.isHidden = true

        UIView.animate(withDuration: 0.3) {
            self.friendsNotificationHeightConstraint.constant = 170
            self.view.layoutIfNeeded()
        }
    }
    
    /// Call to enable or disable the user's microphone
    ///
    /// - Parameter enabled: true if the mic should be enabled
    private func enableMicrophone(_ enabled: Bool) {
        guard let chatroom = chatroom, (AgoraManager.shared.activeChannel == nil || AgoraManager.shared.activeChannel == chatroom.identifier) else { return }
        
        if enabled {
            textInputView.textView.placeholder = "your mic is on. say something"
            
            // Join the voice channel if needed
            AgoraManager.shared.joinChannel(withId: chatroom.identifier)

            // Voice is off. Turn it on.
            AgoraManager.shared.unmuteRecording()

        } else {
            // Voice is on. Turn it off.
            AgoraManager.shared.muteRecording()
            textInputView.textView.placeholder = "type or turn the mic on"
        }
        
        view.layoutIfNeeded()
    }
    
    private func showProfileQuickView(forUser user: User) {
        let storyboard = UIStoryboard(name: AppConstants.Storyboards.profile, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: ProfileQuickViewController.storyboardIdentifier) as! ProfileQuickViewController
        profileQuickView = vc
        vc.user = user
        
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
            
            // show the floating audio overlay
            NavigationManager.shared.window?.toggleFloatingViewOverlay(visible: true)
        }
        
        AnalyticsManager.track(event: .quickViewOpened, withParameters: nil)

        vc.willMove(toParent: self)
        addChild(vc)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(vc.view)
        vc.view.constrainToSuperview()
        vc.didMove(toParent: self)
        vc.animateIn()
    }
    
    // MARK: - Interface Actions
        
    @IBAction func infoButtonPressed(_ sender: UIButton) {
        AnalyticsManager.track(event: .chatInfoButtonPressed, withParameters: nil)
        
        let viewController = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: ManageChatViewController.storyboardIdentifier) as! ManageChatViewController
        viewController.chatroom = self.chatroom
        viewController.showEditButton = session == nil // Only allow editing if this is NOT a Game Session chat
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        dismissSelf()
    }
 
    @IBAction func minimizeNotificationButtonPressed(_ sender: UIButton) {
        toggleFriendNotificationView()
    }
    
    @IBAction func notificationViewTapped(_ sender: Any) {
        expandFriendNotification()
    }
    
    @IBAction func notificationButtonPressed(_ sender: UIButton) {
        toggleFriendNotificationView()
    }
    
    @IBAction func sendFriendRequestButtonPressed(_ sender: UIButton) {
        guard chatroom?.isGroupChat == false else { return }
        
        chatroom?.fetchUsers(completion: { [weak self] (users) in
            guard let strongself = self else { return }

            guard let user = users?.first else { return }
            
            HUD.show(.progress)
            DataCoordinator.shared.addFriend(withUserId: user.identifier) { (error, _) in
                
                performOnMainThread {
                    guard error == nil else {
                        HUD.flash(.error)
                        GGLog.error("Error: \(String(describing: error))")
                        strongself.presentGenericErrorAlert()
                        return
                    }
                    
                    HUD.flash(.success)
                    strongself.getFriendStatus(forUser: user.identifier)
                }
            }
        })
    }
    
    @IBAction func cancelFriendRequestButtonPressed(_ sender: UIButton) {
        guard let request = friendRequest, let friend = request.receiver else { return }
        
        HUD.show(.progress)
        DataCoordinator.shared.cancelFriendRequest(toUser: friend) { [weak self] (error) in
            guard let strongself = self else { return }
            
            performOnMainThread {
                guard error == nil else {
                    HUD.flash(.error)
                    GGLog.error("Error: \(String(describing: error))")
                    strongself.presentGenericErrorAlert()
                    return
                }
                
                HUD.flash(.success)
                strongself.hideFriendNotification()
            }
        }
    }
    
    @IBAction func acceptFriendRequestButtonPressed(_ sender: UIButton) {
        guard let request = friendRequest, let friender = request.creator else { return }
        
        HUD.show(.progress)
        DataCoordinator.shared.acceptFriendRequest(fromUser: friender) { [weak self] (error) in
            guard let strongself = self else { return }
            
            performOnMainThread {
                guard error == nil else {
                    HUD.flash(.error)
                    GGLog.error("Error: \(String(describing: error))")
                    strongself.presentGenericErrorAlert()
                    return
                }
                
                HUD.flash(.success)
                strongself.hideFriendNotification()
            }
        }
    }
    
    @IBAction func micReturnButtonPressed(_ sender: UIButton) {
        // Return the audio view to its original position
        NavigationManager.shared.window?.floatingViewOverlay.snapFloatingView(toSocket: .bottomRight)
    }
}

extension ChatViewController: TextInputViewDelegate {
    
    func textInputView(textInputView: TextInputView, textDidChange text: String) {
        
        guard let chatroom = chatroom else { return }
        
        // Set the typing status for this user to true if the text is not empty
        firebaseChat.setTypingStatus(isTyping: !text.isEmpty, inChatroom: chatroom)
        
        // Minimize any open friend notification when the user begins typing.
        minimizeFriendNotification()
    }
    
    func textInputView(textInputView: TextInputView, heightDidChange height: CGFloat) {
        // NOP
    }
    
    func textInputView(textInputView: TextInputView, sendButtonTapped sendButton: UIButton, gif: Gif?) {
        guard let chatroom = chatroom, (!textInputView.text.isEmpty || gif != nil) else { return }
        
        let messageType: FRMessageType = gif == nil ? .message : .media
        firebaseChat.sendMessage(ofType: messageType, text: textInputView.text, gif: gif, toChatroom: chatroom)
        
        SoundManager.shared.playSound(.messageSent)
        
        // Reset typing status for this user
        firebaseChat.setTypingStatus(isTyping: false, inChatroom: chatroom)
        view.layoutIfNeeded()
    }
    
    func textInputView(textInputView: TextInputView, giphyButtonTapped giphyButton: UIButton) {
        
        AnalyticsManager.track(event: .giphyIconTapped)
        
        let storyboard = UIStoryboard(name: AppConstants.Storyboards.giphy, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: GiphyViewController.storyboardIdentifier) as! GiphyViewController
        
        vc.onGifSelected = { [weak self, weak vc] (gif) in
            self?.textInputView.setMediaURL(gif.url, withSize: gif.size ?? .zero)

            vc?.dismissSelf(completion: {
                self?.textInputView.textView.becomeFirstResponder()
            })
        }
        
        vc.onBackButtonPressed = { [weak self, weak vc] in
            vc?.dismissSelf(completion: {
                self?.textInputView.textView.becomeFirstResponder()
            })
        }
        
        NavigationManager.shared.present(vc)
    }
}

extension ChatViewController: MessagesTableViewDelegate {
    
    func messagesTableView(tableView: MessagesTableView, didReceiveMessages messages: [FRMessage]) {
        guard let chatroom = chatroom else { return }
        // Reset the unread count since we're currently looking at these messages now...
        firebaseChat.resetMyUnreadCount(inChatroom: chatroom)

        if let lastMessage = messages.last,
                lastMessage.type == .sentFriendRequest ||
                lastMessage.type == .friendRequestAccepted ||
                lastMessage.type == .cancelledFriendRequest {
            
            fetchUsers(breakCache: true)
        }
    }
    
    func messagesTableView(tableView: MessagesTableView, didTap message: FRMessage) {
        guard let chatroom = chatroom else { return }
        
        if message.type == .createdParty, let game = message.game ?? chatroom.game {
            // Go to tags chat with selected tags from the message or chatroom
            
            AnalyticsManager.track(event: .tappedChatMessageTags, withParameters: [
                "user": DataCoordinator.shared.signedInUser?.identifier ?? "",
                "tags": message.tags.marqueeText,
                "game": game.title
            ])
            

            let lobbyVC = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: GameLobbyContainerViewController.storyboardIdentifier) as! GameLobbyContainerViewController
            lobbyVC.shouldRestoreBookmarkedTags = false
            lobbyVC.loadViewIfNeeded()
            lobbyVC.game = game
            lobbyVC.tagsChatViewController?.selectedTags = message.tags.filter({ $0.size == 0 })  // IGNORE ALL SIZE TAGS
    
            let nav = GGNavigationViewController(rootViewController: lobbyVC)
            nav.hidesBottomBarWhenPushed = true
            nav.isNavigationBarHidden = true
            nav.modalTransitionStyle = .crossDissolve

            NavigationManager.shared.present(nav, animated: true)
        }
    }
}

extension ChatViewController: AgoraManagerDelegate {
    
    func agoraManager(manager: AgoraManager, userDidJoinCall uuid: UInt) {
        // NOP
    }
    
    func agoraManager(manager: AgoraManager, userDidLeaveCall uuid: UInt) {
        guard uuid == DataCoordinator.shared.signedInUser?.uid else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { [weak self] in
            guard let weakSelf = self, weakSelf.isVisible else { return }
            // wait a sec...
            weakSelf.toggleAudioView(visible: true)
        })
    }
    
    func agoraManager(manager: AgoraManager, activeSpeakersDidChange uuids: [UInt]) {
        guard chatroom?.identifier == manager.activeChannel else { return }
        chatAvatarsCollectionView.animateActiveSpeakers(speakers: uuids)
    }
}

extension ChatViewController: FloatingViewOverlaySocketHandler {
    var bottomLeftSocketInset: CGFloat? { return 50.0 }
    var bottomRightSocketInset: CGFloat? { return 5.0 }
    
    var sockets: [FloatingViewSocket] {
        return [.bottomRight, .bottomLeft, .midLeft, .midRight]
    }
}
