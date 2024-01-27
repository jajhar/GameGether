//
//  FloatingAudioView.swift
//  GameGether
//
//  Created by James Ajhar on 12/12/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit
import FLAnimatedImage

class FloatingAudioView: UIView {

    static weak var activeView: FloatingAudioView?

    enum CallButtonMode {
        case startCall
        case onCall
        case pickUp
        case deafened
    }
    
    struct AudioState {
        var mutedUsers = [User]()
        var micVolume: SoundButton.Volume?
        var isMicEnabled: Bool = false
    }
    
    // MARK: Outlets
    @IBOutlet weak var micButton: UIButton! {
        didSet {
            micButton.isSelected = !AgoraManager.shared.isMuted
        }
    }
    
    @IBOutlet weak var soundButton: SoundButton!
    
    @IBOutlet weak var callButton: UIButton! {
        didSet {
            callButton.titleLabel?.font = AppConstants.Fonts.robotoMedium(14).font
            callButton.setTitleColor(.white, for: .normal)
        }
    }
    @IBOutlet weak var callButtonLabel: UILabel! {
        didSet {
            callButtonLabel.font = AppConstants.Fonts.robotoMedium(14).font
            callButtonLabel.textColor = .white
        }
    }
    
    @IBOutlet weak var pauseCallButton: UIButton!
    @IBOutlet weak var hangupButton: UIButton!
    @IBOutlet weak var callControlsStackView: UIStackView!
    
    @IBOutlet weak var plusButton: SoundButton!
    @IBOutlet weak var activeUsersStackView: UIStackView!
    @IBOutlet var activeUsersStackViewHeight: NSLayoutConstraint!
    @IBOutlet weak var backToRoomButton: UIButton!
    @IBOutlet weak var toolTipImageView: UIImageView!
    @IBOutlet weak var micImageView: UIImageView!
    
    @IBOutlet weak var userImageView: AvatarInitialsImageView! {
        didSet {
            if let user = DataCoordinator.shared.signedInUser {
                userImageView.configure(withUser: user, andFont: AppConstants.Fonts.robotoRegular(16).font)
            }
            
            userImageView.cornerRadius = userImageView.bounds.width / 2
        }
    }
    
    @IBOutlet weak var animatedVoiceImageView: FLAnimatedImageView! {
        didSet {
            if let path = Bundle.main.url(forResource: "Chat-Profile-Mic-Indicator", withExtension: "gif"), let data = try? Data(contentsOf: path) {
                animatedVoiceImageView.animatedImage = FLAnimatedImage(animatedGIFData: data)
            }
        }
    }
    
    // MARK: Properties
    var chatroom: FRChatroom? {
        didSet {
            if let chatroom = chatroom {
                // Tell the audio view to observe mic enabled users in this chatroom
                setup(withChatroom: chatroom)
            }
        }
    }
    private let firebaseChat = FirebaseChat()
    private var audioUserViews = [AudioUserView]()
    private var initialVolumeSet: Bool = false
    private var micStatusTimer: Timer?
    private var voiceAnimationTimer: Timer?

    private var mutedUsers = [User]() {
        didSet {
            setupActiveUsers(activeUsers)
        }
    }
    
    private(set) var activeUsers = [User]() {
        didSet {
            setupActiveUsers(activeUsers)
        }
    }
    
    private var tooltipTimer: Timer?
    private var lastKnownAudioState: AudioState?
    private var callButtonMode: CallButtonMode = .startCall
    
    var onCallJoined: ((FRChatroom) -> Void)?
    var onCallLeft: ((FRChatroom) -> Void)?
    var onUserTapped: ((User) -> Void)?
    var shouldShowBackButton: Bool = false {
        didSet {
            toggleActiveUsersView(visible: plusButton.isSelected)
        }
    }
    
    deinit {
        // destroy all timers
        tooltipTimer?.invalidate()
        tooltipTimer = nil
        
        micStatusTimer?.invalidate()
        micStatusTimer = nil
        
        voiceAnimationTimer?.invalidate()
        voiceAnimationTimer = nil
        
        // Kill any in progress sounds
        SoundManager.shared.killSound(.incomingCall)
        SoundManager.shared.killSound(.outgoingCall)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        styleUI()
        
//        plusButton.isHidden = true

        firebaseChat.signIn()
        
        setupActiveUsers(activeUsers)
        plusButton.imageView?.contentMode = .scaleAspectFit
        activeUsersStackView.clipsToBounds = true
        
        // Unmute agora
        setMutedStatus(muted: false)

        soundButton.onTap = { [weak self] in
            if self?.lastKnownAudioState != nil {
                // we are currently in a deafened state. Undeafen everything
                self?.undeafenAudio()
            }
        }
        
        soundButton.onVolumeChanged = { [weak self] newVolume in
            guard let weakSelf = self else { return }
            
            guard weakSelf.lastKnownAudioState == nil else {
                // we are currently in a deafened state
                return
            }
            
            UserDefaults.standard.set(newVolume.rawValue, forKey: AppConstants.UserDefaults.microphoneVolumeLevel)
            UserDefaults.standard.synchronize()
            
            var tooltipImage: UIImage?
            
            switch newVolume {
            case .low:
                AgoraManager.shared.setPlaybackVolume(.low)
                tooltipImage = #imageLiteral(resourceName: "SoundTooltip-Low")
            case .medium:
                AgoraManager.shared.setPlaybackVolume(.medium)
                tooltipImage = #imageLiteral(resourceName: "SoundTooltip-Medium")
            case .mediumHigh:
                AgoraManager.shared.setPlaybackVolume(.mediumHigh)
                tooltipImage = #imageLiteral(resourceName: "SoundTooltip-MediumHigh")
            case .high:
                AgoraManager.shared.setPlaybackVolume(.high)
                tooltipImage = #imageLiteral(resourceName: "SoundTooltip-High")
            case .mute:
                AgoraManager.shared.setPlaybackVolume(.mute)
            }
            
            if weakSelf.initialVolumeSet {
                // Only show these tool tips if the user is the one responsible for the volume change
                weakSelf.toolTipImageView.image = tooltipImage
                weakSelf.toolTipImageView.alpha = 1.0

                // invalidate any previous tooltip timers
                weakSelf.tooltipTimer?.invalidate()
                weakSelf.tooltipTimer = nil
                
                weakSelf.tooltipTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false, block: { (_) in
                    UIView.animate(withDuration: 0.3, animations: {
                        weakSelf.toolTipImageView.alpha = 0.0
                    })
                })
                
                SoundManager.shared.playSound(.callVolume)
            }
            
            weakSelf.initialVolumeSet = true
        }
        
        if let micVolume = UserDefaults.standard.value(forKey: AppConstants.UserDefaults.microphoneVolumeLevel) as? String,
            let volume = SoundButton.Volume(rawValue: micVolume) {
            // restore volume state if possible
            soundButton.currentVolume = volume
        } else {
            // else default to medium volume
            soundButton.currentVolume = .medium
        }
        
        updateCallButton(mode: .startCall)
    }
    
    private func setup(withChatroom chatroom: FRChatroom) {
        
        if AgoraManager.shared.activeChannel == nil {
            // User is not in the channel so we need to use firebase to get an accurate reading on the users currently voice chatting.
            //  Agora doesn't give you this info unless you JOIN the channel first...unfortunately
            firebaseChat.observeMicEnabledStatus(forChatroom: chatroom.identifier, onStatusChanged: { [weak self] (micEnabledUsers) in
                guard AgoraManager.shared.activeChannel == nil else { return }

                guard let weakSelf = self, !AgoraManager.shared.isInVoiceChannel else { return }
                
                performOnMainThread {
                    weakSelf.toggleIncomingCallMode(active: micEnabledUsers.count > 0)
                    
                    DataCoordinator.shared.getProfiles(forUsersWithIds: micEnabledUsers) { (users, error) in
                        guard error == nil, let users = users else {
                            GGLog.error(error?.localizedDescription ?? "unknown error")
                            return
                        }
                        performOnMainThread {
                            weakSelf.activeUsers = users
                        }
                    }
                }
            })
            
        } else {
            // User is already in the voice channel.
            toggleIncomingCallMode(active: false)
            updateCallButton(mode: .onCall)
        }
        
        AgoraManager.shared.onUserJoinedRoom = { [weak self] (userId) in
            guard let weakSelf = self else { return }
            
            // Play user joined call sound
            SoundManager.shared.playSound(.callJoined)
            
            if userId != DataCoordinator.shared.signedInUser?.uid {
                SoundManager.shared.killSound(.incomingCall)
                SoundManager.shared.killSound(.outgoingCall)

                chatroom.fetchUsers(completion: { (chatroomUsers) in
                    guard let user = chatroomUsers?.filter({ $0.uid == userId }).first,
                        !weakSelf.activeUsers.contains(where: { $0.uid == user.uid }) else { return }
                    weakSelf.activeUsers.append(user)
                })
            }
        }
        
        AgoraManager.shared.onUserLeftRoom = { [weak self] (userId) in
            guard let weakSelf = self else { return }
            
            // Play user left call sound
            SoundManager.shared.playSound(.callLeft)
            
            chatroom.fetchUsers(completion: { (chatroomUsers) in
                guard let user = chatroomUsers?.filter({ $0.uid == userId }).first,
                    let index = weakSelf.activeUsers.firstIndex(where:{ $0.uid == user.uid }) else { return }
                
                // Remove this user from the active voice users
                weakSelf.activeUsers.remove(at: index)
            })
        }
    }
    
    private func toggleIncomingCallMode(active: Bool) {
        if active, callButtonMode == .pickUp { return } // No changes
        if !active, callButtonMode == .startCall { return } // No changes

        toggleActiveUsersView(visible: active)
        updateCallButton(mode: active ? .pickUp : .startCall)
        
        if active {
            // Play incoming call sound but kill any existing ones first so we don't overlap them.
            SoundManager.shared.killSound(.incomingCall)
            SoundManager.shared.playSound(.incomingCall)
        } else {
            SoundManager.shared.killSound(.incomingCall)
        }
    }
    
    private func styleUI() {
        addDropShadow(color: .black, opacity: 0.5, offset: CGSize(width: 0, height: 1), radius: 1)
    }

    private func deafenAudio() {
        guard let chatroom = chatroom else { return }
        
        // Save the last known state before applying the deafen mode
        lastKnownAudioState = AudioState(mutedUsers: mutedUsers,
                                         micVolume: soundButton.currentVolume,
                                         isMicEnabled: micButton.isSelected)
        
        chatroom.fetchUsers() { [weak self] (users) in
            guard self?.callButtonMode == .deafened else { return }
            self?.mutedUsers = users ?? []
        }

        soundButton.currentVolume = .mute
       
        // Mute the user's microphone
        setMutedStatus(muted: true)
        
        micButton.isSelected = !AgoraManager.shared.isMuted
        micImageView.image = micButton.isSelected ? #imageLiteral(resourceName: "MicOn") : #imageLiteral(resourceName: "MicMuted")
        updateCallButton(mode: .deafened)
    }
    
    private func undeafenAudio() {
        guard let lastKnownAudioState = lastKnownAudioState else { return }
        
        mutedUsers = lastKnownAudioState.mutedUsers
        soundButton.currentVolume = lastKnownAudioState.micVolume ?? .medium
       
        // Restore the last known microhpone state
        micButton.isSelected = lastKnownAudioState.isMicEnabled
        
        setMutedStatus(muted: !micButton.isSelected)
        micImageView.image = micButton.isSelected ? #imageLiteral(resourceName: "MicOn") : #imageLiteral(resourceName: "MicMuted")

        self.lastKnownAudioState = nil
        updateCallButton(mode: .onCall)
    }
    
    /// Call to leave the current chatroom
    private func leaveChatroom() {
        guard let chatroom = chatroom else { return }
        
        // Leave the chatroom
        if let activeChannel = AgoraManager.shared.activeChannel {
            AgoraManager.shared.leaveChannel(withId: activeChannel)
        }
        
//            self.plusButton.isHidden = true

        // Stop playing any outgoing call music if applicable
        SoundManager.shared.killSound(.outgoingCall)
        SoundManager.shared.playSound(.callLeft)

        AnalyticsManager.track(event: .micOff)
        
        updateCallButton(mode: !activeUsers.isEmpty ? .pickUp : .startCall)
        activeUsers.removeAll()    // will be reset by the delegate
        toggleActiveUsersView(visible: false)
        plusButton.isSelected = false
        
        sendCallNotification(micOn: false)

        NavigationManager.shared.toggleActiveCallView(visible: false, forChatroom: chatroom)
        onCallLeft?(chatroom)
    }
    
    private func setMutedStatus(muted: Bool) {
        guard let chatroom = chatroom else { return }
        
        if muted {
            AgoraManager.shared.muteRecording()
        } else {
            AgoraManager.shared.unmuteRecording()
        }
        
        firebaseChat.setMicMutedStatus(isMuted: muted, inChatroom: chatroom.identifier)
    }
    
    private func setupActiveUsers(_ users: [User]) {
        guard let chatroom = chatroom else { return }
        
        // Start fresh
        _ = activeUsersStackView.arrangedSubviews.compactMap({ $0.removeFromSuperview() })

        if users.count == 0 {
            let label = UILabel(frame: .zero)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = "no one has the mic on."
            label.numberOfLines = 0
            label.textAlignment = .center
            label.textColor = UIColor(hexString: "#ACACAC")
            label.font = AppConstants.Fonts.robotoRegular(12).font
            activeUsersStackView.addArrangedSubview(label)
        }
        
        audioUserViews.removeAll()
        
        for user in users {
            let view = createAudioView(forUser: user)
            audioUserViews.append(view)
            activeUsersStackView.addArrangedSubview(view)
        }
        
        firebaseChat.observeMicMutedStatus(inChatroom: chatroom.identifier) { [weak self] (mutedUsers) in
            guard let weakSelf = self else { return }

            performOnMainThread {
                
                for audioView in weakSelf.audioUserViews {
                    guard let userId = audioView.user?.identifier else { continue }
                    audioView.setMicEnabled(!mutedUsers.contains(userId))
                }
            }
        }
        
        setNeedsLayout() // Tells the window that this view needs to be laid out again
        layoutIfNeeded()
    }
    
    private func createAudioView(forUser user: User) -> AudioUserView {
        let container = AudioUserView(frame: .zero)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.constrainHeight(50)
        container.user = user
        
        if mutedUsers.contains(where: { $0.uid == user.uid }) {
            container.muteUser(true)
            AgoraManager.shared.muteUser(withId: user.uid)
        } else {
            AgoraManager.shared.unmuteUser(withId: user.uid)
        }

        container.onAvatarTapped = { [weak self] (user) in
            self?.onUserTapped?(user)
        }
        
        container.onMicrophoneTapped = { [weak self] (user, isMicEnabled) in
            if isMicEnabled {
                AgoraManager.shared.unmuteUser(withId: user.uid)

                if let index = self?.mutedUsers.firstIndex(where: { $0.uid == user.uid }) {
                    self?.mutedUsers.remove(at: index)
                }
                
            } else {
                AgoraManager.shared.muteUser(withId: user.uid)
                
                self?.mutedUsers.append(user)
            }
        }
        
        return container
    }
    
    public func animateActiveSpeakers(speakers: [UInt]) {
        let activeSpeakers = activeUsers.filter({ speakers.contains($0.uid) })
        
        if speakers.contains(where: { $0 == 0 }) {
            // 0 == local user (per Agora docs)
            animatedVoiceImageView.alpha = 1
            voiceAnimationTimer?.invalidate()
            voiceAnimationTimer = nil
            
            voiceAnimationTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { [weak self] (_) in
                UIView.animate(withDuration: 0.3, animations: {
                    self?.animatedVoiceImageView.alpha = 0.0
                })
            }
        }
        
        for view in audioUserViews {
            guard activeSpeakers.contains(where: { $0.identifier == view.user?.identifier }) else { continue }
            // This user is currently speaking. Animate them.
            view.animateSpeaker()
        }
    }
    
    private func updateCallButton(mode: CallButtonMode) {
        
        callButton.layer.removeAllAnimations()
        callButton.titleLabel?.layer.removeAllAnimations()
        callButtonLabel.layer.removeAllAnimations()
        callButton.setBackgroundImage(nil, for: .normal)
        callButtonLabel.isHidden = true
        callButtonMode = mode
        
        switch mode {
        case .startCall:
            callControlsStackView.isHidden = true
            callButton.isHidden = false
            callButton.setImage(#imageLiteral(resourceName: "pickupcall"), for: .normal)
            
        case .onCall:
            callButton.isHidden = true
            callControlsStackView.isHidden = false
            
        case .pickUp:
            callControlsStackView.isHidden = true
            callButton.isHidden = false
            callButton.setImage(#imageLiteral(resourceName: "pickupcall-green"), for: .normal)
            
        case .deafened:
            callButton.isHidden = false
            callControlsStackView.isHidden = true
            
            callButton.setImage(nil, for: .normal)
            callButton.setBackgroundImage(#imageLiteral(resourceName: "leavecall"), for: .normal)
            callButton.setTitle("call paused", for: .normal)
            callButtonLabel.text = "tap to resume"
            callButtonLabel.isHidden = false
            callButtonLabel.alpha = 0
            
            // Fade call button title labels in/out
            animateCallButtonTitle()
        }
    }
    
    /// Absolute garbage implementation of animated titles - OMG
    func animateCallButtonTitle() {
        guard callButtonMode == .deafened else { return }
        
        callButton.layer.removeAllAnimations()
        callButton.titleLabel?.layer.removeAllAnimations()
        callButtonLabel.layer.removeAllAnimations()

        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       options: [.allowUserInteraction],
                       animations: {
                        self.callButton.titleLabel?.alpha = 1
        }, completion: { [weak self] (finished) in
            guard finished else { return }
            
            UIView.animate(withDuration: 1.0,
                           delay: 0,
                           options: [.allowUserInteraction],
                           animations: {
                            self?.callButton.titleLabel?.alpha = 0
            }, completion: { [weak self] (finished) in
                guard finished else { return }
                
                self?.animateCallButtonTitleReverse()
            })
        })
    }
    
    func animateCallButtonTitleReverse() {
        guard callButtonMode == .deafened else { return }

        callButton.layer.removeAllAnimations()
        callButton.titleLabel?.layer.removeAllAnimations()
        callButtonLabel.layer.removeAllAnimations()

        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       options: [.allowUserInteraction],
                       animations: {
                        self.callButtonLabel.alpha = 1
        }, completion: { [weak self] (finished) in
            guard finished else { return }
            
            UIView.animate(withDuration: 1.0,
                           delay: 0,
                           options: [.allowUserInteraction],
                           animations: {
                            self?.callButtonLabel.alpha = 0
            }, completion: { [weak self] (finished) in
                guard finished else { return }
                
                self?.animateCallButtonTitle()
            })
        })
    }

    @IBAction func micButtonPressed(_ sender: UIButton) {
        
        // Provide haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()

        guard lastKnownAudioState == nil else {
            // we are currently in a deafened state. Undeafen everything
            undeafenAudio()
            return
        }
        
        guard UIDevice.current.hasMicrophonePermission else {
            NavigationManager.topMostViewController()?.presentGenericAlert(title: "Access Denied", message: "You must allow the app to access your microphone in order to use voice chat. Please go to Settings->Privacy->Microphone and allow GameGether to access your microphone.")
            return
        }
        
        setMutedStatus(muted: !AgoraManager.shared.isMuted)
        micButton.isSelected = !AgoraManager.shared.isMuted
        micImageView.image = micButton.isSelected ? #imageLiteral(resourceName: "MicOn") : #imageLiteral(resourceName: "MicMuted")
    }
    
    @IBAction func pauseCallButtonPressed(_ sender: Any) {
        deafenAudio()
    }
    
    @IBAction func hangupButtonPressed(_ sender: Any) {
        hangup()
    }
    
    @IBAction func backToRoomPressed(_ sender: UIButton) {
        guard let chatroom = chatroom else { return }
        
        AnalyticsManager.track(event: .voiceOverlayBackPressed, withParameters: nil)
        
        let viewController = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: ChatViewController.storyboardIdentifier) as! ChatViewController
        viewController.chatroom = chatroom
        NavigationManager.shared.push(viewController)
    }
    
    @IBAction func plusButtonPressed(_ sender: UIButton) {
        toggleActiveUsersView(visible: !sender.isSelected)
    }
    
    private func togglePlusButton(active: Bool) {
        plusButton.isSelected = active
        
        plusButton.layer.removeAllAnimations()
        UIView.animate(withDuration: 0.3) {
            self.plusButton.transform = active ? CGAffineTransform(rotationAngle: .pi) : .identity
        }
    }
    
    private func toggleActiveUsersView(visible: Bool) {
        
        backToRoomButton.isHidden = !shouldShowBackButton || !visible
        
        togglePlusButton(active: visible)
        
        UIView.animate(withDuration: 0.3) {
            self.activeUsersStackViewHeight.isActive = !visible
            self.setNeedsLayout()
            self.layoutIfNeeded()
            NavigationManager.shared.window?.floatingViewOverlay.snapButtonToSocket() // fixes strange layout issue when expanding and contracting this view
        }
    }
    
    private func sendCallNotification(micOn: Bool) {
        guard let chatroom = chatroom else { return }
        let messageType: FRMessageType = micOn ? .micTurnedOn : .micTurnedOff
        firebaseChat.sendMessage(ofType: messageType, toChatroom: chatroom)
    }
    
    func hangup() {
        guard AgoraManager.shared.activeChannel != nil else { return }
        undeafenAudio()
        leaveChatroom()
    }
    
    // MARK: - Interface Actions
    
    @IBAction func callButtonPressed(_ sender: UIButton) {
        guard let chatroom = chatroom else { return }
        
        if AgoraManager.shared.activeChannel != nil {
            undeafenAudio()
            
        } else {
            // Join call
            if activeUsers.isEmpty {
                // If no one else is on the call, play outgoing call sound
                SoundManager.shared.playSound(.outgoingCall)
            }
            
            AnalyticsManager.track(event: .micOn)
            
            activeUsers.removeAll()
            AgoraManager.shared.joinChannel(withId: chatroom.identifier)
            updateCallButton(mode: .onCall)
            sendCallNotification(micOn: true)
            
            onCallJoined?(chatroom)
        }
    }
}

private class AudioUserView: UIView {
    
    private var avatarButton: AvatarInitialsButton = {
        let avatar = AvatarInitialsButton(frame: .zero)
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.clipsToBounds = true
        avatar.cornerRadius = 15
        avatar.constrainWidth(30)
        avatar.constrainHeight(30)
        avatar.addTarget(self, action: #selector(avatarButtonTapped(sender:)), for: .touchUpInside)
        return avatar
    }()
    
    private var micButton: UIButton = {
        let micButton = UIButton(frame: .zero)
        micButton.translatesAutoresizingMaskIntoConstraints = false
        micButton.setImage(#imageLiteral(resourceName: "MicMuted"), for: .normal)
        micButton.setImage(#imageLiteral(resourceName: "MicOn"), for: .selected)
        micButton.isSelected = true // default is selected because mic is enabled by default for each user
        micButton.addTarget(self, action: #selector(micButtonTapped(sender:)), for: .touchUpInside)
        return micButton
    }()
    
    let chatIndicatorAnimatedImageView: FLAnimatedImageView = {
        let view = FLAnimatedImageView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = false
        view.contentMode = .scaleAspectFill
        view.alpha = 0.0
        
        if let path = Bundle.main.url(forResource: "Chat-Profile-Mic-Indicator", withExtension: "gif"), let data = try? Data(contentsOf: path) {
            view.animatedImage = FLAnimatedImage(animatedGIFData: data)
        }
        
        return view
    }()
    
    private var animationTimer: Timer?

    var user: User? {
        didSet {
            guard let user = user else { return }
            setup(withUser: user)
        }
    }
    
    var onAvatarTapped: ((User) -> Void)?
    var onMicrophoneTapped: ((User, Bool) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {

        addSubview(micButton)
        addSubview(chatIndicatorAnimatedImageView)
        addSubview(avatarButton)

        avatarButton.constrainToCenterVertical()
        avatarButton.constrainTo(edge: .left)?.constant = 24
        
        chatIndicatorAnimatedImageView.constrain(attribute: .centerX, toItem: avatarButton, attribute: .centerX)
        chatIndicatorAnimatedImageView.constrain(attribute: .centerY, toItem: avatarButton, attribute: .centerY)
        chatIndicatorAnimatedImageView.constrain(attribute: .height, toItem: avatarButton, attribute: .height, constant: 24)
        chatIndicatorAnimatedImageView.constrain(attribute: .width, toItem: avatarButton, attribute: .width, constant: 24)
        
        micButton.constrainToCenterVertical()
        micButton.constrainTo(edge: .right)?.constant = -27
        micButton.constrainTo(edges: .top, .bottom)
        
        clipsToBounds = true
    }
    
    private func setup(withUser user: User) {
        avatarButton.configure(withUser: user, andFont: AppConstants.Fonts.robotoRegular(16).font)
    }
    
    public func animateSpeaker() {
        chatIndicatorAnimatedImageView.alpha = 1.0
        animationTimer?.invalidate()
        animationTimer = nil
        animationTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { [weak self] (_) in
            UIView.animate(withDuration: 0.3, animations: {
                self?.chatIndicatorAnimatedImageView.alpha = 0.0
            })
        }
    }
    
    public func muteUser(_ muted: Bool) {
        micButton.isSelected = !muted
    }
    
    public func setMicEnabled(_ enabled: Bool) {
        if enabled {
            micButton.setImage(#imageLiteral(resourceName: "MicOn"), for: .selected)
        } else {
            micButton.setImage(#imageLiteral(resourceName: "Mic Off"), for: .selected)
        }
    }
    
    @objc func avatarButtonTapped(sender: UIButton) {
        guard let user = user else { return }
        onAvatarTapped?(user)
    }
    
    @objc func micButtonTapped(sender: UIButton) {
        guard let user = user else { return }
        sender.isSelected = !sender.isSelected
        onMicrophoneTapped?(user, sender.isSelected)
    }
}
