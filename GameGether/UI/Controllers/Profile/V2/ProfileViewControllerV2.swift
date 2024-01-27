//
//  ProfileViewControllerV2.swift
//  GameGether
//
//  Created by James Ajhar on 5/28/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit
import PKHUD
import AVFoundation
import AVKit
import MobileCoreServices
import SafariServices
import EasyTipView
import MessageUI

class ProfileViewControllerV2: UIViewController, ShowsNavigationOverlay {
    
    struct ProfileConstants {
        static let editHeaderHeight: CGFloat = UIDevice.current.hasNotch ? 90 : 68
        static let minHeaderHeight: CGFloat = 55.0
    }
    
    enum ImagePickingMode {
        case profilePicture
        case profileMedia(Int)
    }
    
    enum ProfileMode {
        case viewing
        case editing
    }
    
    // MARK: - Outlets
    @IBOutlet weak var topNavView: UIView!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    // Profile top nav (shows when scrolling down)
    @IBOutlet weak var profileTopNavInfo: UIView! {
        didSet {
            profileTopNavInfo.alpha = 0
        }
    }
    
    @IBOutlet weak var profileTopNavImageView: AvatarInitialsImageView!
    @IBOutlet weak var profileTopNavIGNLabel: UILabel!
    @IBOutlet weak var profileTopNavStatusImageView: UserStatusImageView!
    
    // Editing mode header view
    @IBOutlet weak var editHeaderView: UIView!
    @IBOutlet weak var editHeaderHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var editHeaderTitleLabel: UILabel!
    @IBOutlet weak var editHeaderDoneButton: UIButton!
    @IBOutlet weak var editHeaderCancelButton: UIButton!
    
    @IBOutlet weak var collectionView: ProfileGamesCollectionView! {
        didSet {
            collectionView.delegate = self
            collectionView.keyboardDelegate = self
            
            collectionView.onGameIconPressed = { [weak self] (game) in
                guard let weakSelf = self else { return }
                
                // Ignore these touch events if we are not in viewing mode
                guard weakSelf.currentMode == .viewing else { return }
                
                AnalyticsManager.track(event: .profileGameIconTapped, withParameters: ["game": game.title])
                
                if weakSelf.user?.isSignedInUser == true {
                    // Present game screen
//                    let lobbyVC = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: GameLobbyContainerViewController.storyboardIdentifier) as! GameLobbyContainerViewController
//                    lobbyVC.loadViewIfNeeded()
//                    lobbyVC.game = game
//
//                    let nav = GGNavigationViewController(rootViewController: lobbyVC)
//                    nav.hidesBottomBarWhenPushed = true
//                    nav.isNavigationBarHidden = true
//                    nav.modalTransitionStyle = .crossDissolve
//
//                    NavigationManager.shared.present(nav)
//
                } else {
                    weakSelf.showSendMessageDialog(forGame: game)
                }
            }
            
            collectionView.onEditGamePressed = { [weak self] (game) in
                guard let weakSelf = self else { return }
                weakSelf.presentUpdateGamerTagAlert(forGame: game)
            }
            
            collectionView.onTagGroupSelected = { [weak self] (game, tagGroup) in
                guard let weakSelf = self else { return }
                weakSelf.showSendMessageDialog(forGame: game, withTagsGroup: tagGroup)
            }
        }
    }
    
    // MARK: - Properties
    
    // Info Header View
    lazy var profileInfoHeaderView: ProfileInfoHeaderView = {
        let view = UINib(nibName: "\(ProfileInfoHeaderView.self)", bundle: nil).instantiate(withOwner: self, options: nil).first! as! ProfileInfoHeaderView
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    fileprivate var profileInfoHeaderViewTopConstraint: NSLayoutConstraint!
    
    // Media Header View
    lazy var profileMediaView: ProfileMediaContainerView = {
        let view = UINib(nibName: "\(ProfileMediaContainerView.self)", bundle: nil).instantiate(withOwner: self, options: nil).first! as! ProfileMediaContainerView
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    fileprivate var profileMediaViewTopConstraint: NSLayoutConstraint!
    fileprivate var profileMediaViewHeightConstraint: NSLayoutConstraint!
    
    // Misc
    fileprivate var sendMessageTextField: UITextField?
    private let firebaseChat = FirebaseChat()
    private let imagePicker = UIImagePickerController()
    private var imagePickingMode: ImagePickingMode = .profilePicture
    private var socialAlertDialogTextField: UITextField?
    private var viewDidAppear: Bool = false
    
    private var currentMode: ProfileMode = .viewing {
        didSet {
            switch currentMode {
            case .viewing:
                profileInfoHeaderView.currentMode = .viewing
                profileMediaView.currentMode = .viewing
            case .editing:
                profileInfoHeaderView.currentMode = .editing
                profileMediaView.currentMode = .editing
            }
            
            toggleEditHeader(visible: currentMode == .editing)
            layoutHeaders(forScrollView: collectionView)
            
            view.setNeedsLayout()
            view.layoutIfNeeded()
            collectionView.scrollToTop()
        }
    }
    
    var mediaHeaderDefaultHeight: CGFloat {
        // 1:1 ration with screen width
        return view.bounds.width
    }
    
    var user: User? {
        didSet {
            guard isViewLoaded else { return }
            setupWithUser()
        }
    }
    
    var navigationViewShouldDisplay: Bool {
        // Only show the joystick navigation view we are NOT in edit mode
        return currentMode == .viewing
    }
    
    // MARK: - UI Life-cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        styleUI()
        
        hideKeyboardWhenBackgroundTapped()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: UIResponder.keyboardDidShowNotification, object: nil)

        firebaseChat.signIn()
        
        // Configure image picker
        imagePicker.delegate = self
        imagePicker.videoMaximumDuration = 30
        imagePicker.videoQuality = .type640x480
        
        // Hide the back button if this is a root controller
        backButton.isHidden = navigationController?.viewControllers.count == 1

        view.addSubview(profileInfoHeaderView)
        profileInfoHeaderView.constrainTo(edges: .left, .right)
        profileInfoHeaderViewTopConstraint = profileInfoHeaderView.constrain(attribute: .top, toItem: view, attribute: .top)
        
        view.addSubview(profileMediaView)
        profileMediaView.constrainTo(edges: .left, .right)
        profileMediaViewHeightConstraint = profileMediaView.constrainHeight(mediaHeaderDefaultHeight)
        profileMediaViewTopConstraint = profileMediaView.constrain(attribute: .top, toItem: view, attribute: .top)
        
        profileMediaView.onVideoTapped = { [weak self] (playerView) in
            guard let url = playerView.url else { return }

            let player = AVPlayer(url: url)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            
            // Hide any active call views if necessary so they don't overlap the player
            NavigationManager.shared.window?.toggleFloatingViewOverlay(visible: false)
            
            self?.present(playerViewController, animated: true) {
                playerViewController.player?.play()
            }
        }
        
        profileInfoHeaderView.onPlayWithPressed = { [weak self] (_) in
            AnalyticsManager.track(event: .profileAskToPlayTapped)
            self?.presentActionSheet()
        }
        
        profileInfoHeaderView.onEditPressed = { [weak self] (index) in
            self?.collectionView.scrollToTop()
            self?.currentMode = .editing
            AnalyticsManager.track(event: .profileEditButtonTapped)
        }
        
        profileInfoHeaderView.onSettingsPressed = { [weak self] (sender) in
            self?.settingsButtonPressed(sender)
        }
        
        profileInfoHeaderView.onEditProfilePicPressed = { [weak self] (_) in
            self?.imagePickingMode = .profilePicture
            self?.showImagePickerSelectionOptions()
            AnalyticsManager.track(event: .profileEditProfilePicTapped)
        }
        
        profileInfoHeaderView.onAddFriendPressed = { [weak self] (_) in
            AnalyticsManager.track(event: .profileAddFriendTapped)
            self?.addAsFriend()
        }
        
        profileInfoHeaderView.onSocialLinkTapped = { [weak self] (socialLink) in
            guard let weakSelf = self else { return }
            
            if weakSelf.currentMode == .editing {
                // Allow the user to edit this link
                weakSelf.showSocialLinkAlertDialog(forSocialLink: socialLink)
                return
            }
            
            AnalyticsManager.track(event: .profileSocialIconTapped, withParameters: ["link": socialLink.type.rawValue])

            // Attempt to present the link using Safari
            guard let url = socialLink.url else { return }
            let vc = SFSafariViewController(url: url)
            NavigationManager.shared.present(vc)
        }
        
        profileMediaView.onEditPressed = { [weak self] (_, indexOfMedia) in
            guard let weakSelf = self, let user = weakSelf.user else { return }
            
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            guard user.profileMedia.filter({ $0.index == indexOfMedia }).first != nil else {
                // No previous media at this index, go straight to picker
                weakSelf.imagePickingMode = .profileMedia(indexOfMedia)
                
                weakSelf.presentImagePicker(imagePicker: weakSelf.imagePicker,
                                            sourceType: .photoLibrary,
                                            mediaTypes: [kUTTypeImage as String, kUTTypeMovie as String])
                return
            }
            
            alert.addAction(UIAlertAction(title: "delete", style: .destructive, handler: { (_) in
                
                AnalyticsManager.track(event: .profileDeleteMediaTapped)
                
                // Remove the media at this index and update the user's profile
                let profileMedia = user.profileMedia.filter({ $0.index != indexOfMedia })
                
                DataCoordinator.shared.updateProfileMedia(media: profileMedia, completion: { [weak self] (updatedUser, error) in
                    performOnMainThread {
                        guard let weakSelf = self, error == nil else {
                            GGLog.error("Update User Failed: \(String(describing: error?.localizedDescription))")
                            HUD.flash(.error, delay: 1.0)
                            return
                        }
                        
                        weakSelf.getLatestProfile()
                        weakSelf.profileMediaView.currentPage = 0
                        HUD.flash(.success)
                    }
                })
            }))
            
            alert.addAction(UIAlertAction(title: "change", style: .default, handler: { (_) in
                
                AnalyticsManager.track(event: .profileChangeMediaTapped)

                weakSelf.imagePickingMode = .profileMedia(indexOfMedia)
                
                weakSelf.presentImagePicker(imagePicker: weakSelf.imagePicker,
                                            sourceType: .photoLibrary,
                                            mediaTypes: [kUTTypeImage as String, kUTTypeMovie as String])
            }))
            
            alert.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (_) in
                AnalyticsManager.track(event: .profileCancelEditMediaTapped)
            }))
            
            alert.show()
        }
        
        // Make sure the nav buttons and edit header are always on top
        view.bringSubviewToFront(topNavView)
        view.bringSubviewToFront(editHeaderView)

        if user == nil {
            // default to signed in user if necessary
            user = DataCoordinator.shared.signedInUser
        } else {
            setupWithUser()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
     
        profileMediaView.pausePlayer()
        NavigationManager.shared.navigationOverlay?.onAIButtonTapped = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        getLatestProfile()

        layoutHeaders(forScrollView: collectionView)
        
        profileMediaView.resumePlayer()
        
        // Undo the hiding the active call view (in case a full screen avplayer was presented)
        // See .onVideoTapped in viewDidLoad for details
        NavigationManager.shared.window?.toggleFloatingViewOverlay(visible: true)
        
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
        
        collectionView.reloadDataSource()
        
        if !viewDidAppear {
            viewDidAppear = true
            view.setNeedsLayout()
            view.layoutIfNeeded()
            collectionView.scrollToTop()
        }
        
        showTooltipIfNeeded()
    }
    
    private func styleUI() {
        editHeaderTitleLabel.font = AppConstants.Fonts.robotoBold(16).font
        editHeaderDoneButton.titleLabel?.font = AppConstants.Fonts.robotoBold(16).font
        editHeaderCancelButton.titleLabel?.font = AppConstants.Fonts.robotoBold(16).font
        profileTopNavIGNLabel.font = AppConstants.Fonts.robotoMedium(15).font
    }
    
    private func setupWithUser() {
        guard let user = user else { return }
        profileInfoHeaderView.user = user
        profileMediaView.user = user
        collectionView.user = user
        collectionView.reloadDataSource()
        
        profileTopNavIGNLabel.text = user.ign
        profileTopNavImageView.configure(withUser: user, andFont: AppConstants.Fonts.robotoRegular(16).font)
        
        user.observeStatus { [weak self] (status, _) in
            self?.profileTopNavStatusImageView.status = status
        }
        
        settingsButton.isHidden = user.isSignedInUser
    }
    
    private func showTooltipIfNeeded() {
        
        guard !DataCoordinator.shared.isUserSignedIn(),
            !UserDefaults.standard.bool(forKey: AppConstants.UserDefaults.Onboarding.profileSwipeTooltipShown) else {
                return
        }
        
        UserDefaults.standard.set(true, forKey: AppConstants.UserDefaults.Onboarding.profileSwipeTooltipShown)
        UserDefaults.standard.synchronize()

        var prefs = EasyTipView.gamegetherPreferences
        prefs.positioning.contentVInset = 10
        let swipeTooltip = EasyTipView.tooltip(withText: "swipe me up to navigate!", preferences: prefs)

        swipeTooltip.dismissOnTap()
        
        if let joystick = NavigationManager.shared.navigationOverlay?.joyStickView.handleImageView {
            swipeTooltip.show(forView: joystick, withinSuperview: NavigationManager.shared.navigationOverlay)
        }
        
        Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { (_) in
           swipeTooltip.dismiss()
        }
        
        view.layoutIfNeeded()
        
        swipeTooltip.animate()
    }
    
    private func getLatestProfile() {
        guard let user = user else { return }
        
        DataCoordinator.shared.getProfile(forUser: user.identifier, allowCache: false) { [weak self] (updatedUserProfile, error) in
            guard let strongself = self, error == nil else {
                GGLog.error("Error: \(String(describing: error))")
                return
            }
            
            strongself.user = updatedUserProfile
        }
    }
    
    private func layoutHeaders(forScrollView scrollView: UIScrollView) {
        let scrollViewYOffset = scrollView.contentOffset.y + scrollView.contentInset.top
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        
        // Profile Media Header
        let mediaViewYOffset = scrollViewYOffset > profileMediaView.bounds.height - statusBarHeight - ProfileConstants.minHeaderHeight ? profileMediaView.bounds.height - statusBarHeight - ProfileConstants.minHeaderHeight : scrollViewYOffset
        
        // Stretch the imageview when scrolling up past 0 (into the negative offset range)
        profileMediaViewHeightConstraint.constant = scrollViewYOffset < 0 ? mediaHeaderDefaultHeight + -(scrollViewYOffset) : mediaHeaderDefaultHeight
        profileMediaViewTopConstraint.constant = scrollViewYOffset < 0 ? editHeaderView.bounds.height : -(mediaViewYOffset - editHeaderView.bounds.height)

        // Profile Info Header
        let offset: CGFloat = mediaHeaderDefaultHeight - 144
        let infoViewYOffset = scrollViewYOffset > profileInfoHeaderView.bounds.height + offset ? profileInfoHeaderView.bounds.height + offset : scrollViewYOffset
        profileInfoHeaderViewTopConstraint.constant = -(infoViewYOffset - mediaHeaderDefaultHeight - editHeaderView.bounds.height)
        
        // blur the media header after a certain threshold is reached
        profileMediaView.adjustBlurEffect(alpha: scrollViewYOffset / mediaHeaderDefaultHeight)
        
        // fade in/out the profile info in the top nav bar
        if scrollViewYOffset > mediaHeaderDefaultHeight {
            profileTopNavInfo.alpha = (scrollViewYOffset - mediaHeaderDefaultHeight) / (profileInfoHeaderView.bounds.height)
        } else {
            profileTopNavInfo.alpha = 0
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        let headerHeights = profileInfoHeaderView.bounds.height + mediaHeaderDefaultHeight + editHeaderView.bounds.height - statusBarHeight
        
        if collectionView.contentInset.top != headerHeights {
            // Height changed, update the inset
            let difference = collectionView.contentInset.top - headerHeights
            let bottomInset = collectionView.contentInset.bottom == 0 ? 100 : collectionView.contentInset.bottom
            collectionView.contentInset = UIEdgeInsets(top: headerHeights, left: 0, bottom: bottomInset, right: 0)
            collectionView.setContentOffset(CGPoint(x: 0, y: collectionView.contentOffset.y + difference), animated: false)
        }
    }
    
    // MARK: - Interface Actions
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        dismissSelf()
    }
    
    @IBAction func cancelEditingButtonPressed(_ sender: UIButton) {
        currentMode = .viewing
        profileInfoHeaderView.user = user // reset the user to restore original state of the view
    }
    
    @IBAction func doneEditingButtonPressed(_ sender: UIButton) {
        currentMode = .viewing
        
        HUD.show(.progress)

        DataCoordinator.shared.updateHighlights(tagline: profileInfoHeaderView.subtitleTextField.text ?? "",
                                                about: profileInfoHeaderView.aboutTextView.text ?? "")
        { [weak self] (_, error) in
            
            guard let weakSelf = self else { return }

            performOnMainThread {
                HUD.hide()
                
                guard error == nil else {
                    GGLog.error(error?.localizedDescription ?? "Unknown error occurred")
                    weakSelf.presentGenericErrorAlert()
                    return
                }
                
                weakSelf.getLatestProfile()
            }
        }
    }
    
    @IBAction func settingsButtonPressed(_ sender: UIButton) {
        if user?.isSignedInUser == true {
            let viewController = UIStoryboard(name: AppConstants.Storyboards.profile, bundle: nil).instantiateViewController(withIdentifier: ProfileSettingsViewController.storyboardIdentifier)
            NavigationManager.shared.push(viewController)
        } else {
            presentActionSheet(showReportActions: true)
        }
    }
    
    // MARK: - Helpers

    private func toggleEditHeader(visible: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.editHeaderHeightConstraint.constant = visible ? ProfileConstants.editHeaderHeight : 0
            self.view.layoutIfNeeded()
        }
        
        // Show the joystick navigation while NOT in edit mode
        NavigationManager.shared.toggleJoystickNavigation(visible: !visible)
    }

    private func presentActionSheet(showReportActions: Bool = false) {
        guard let user = user else { return }
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if showReportActions {
            actionSheet.addAction(UIAlertAction(title: "report", style: .destructive, handler: { (action) in
                self.reportUser()
            }))
            
            if user.relationship?.status == .blocked {
                actionSheet.addAction(UIAlertAction(title: "unblock", style: .destructive, handler: { (action) in
                    self.unblockUser()
                }))
            } else {
                actionSheet.addAction(UIAlertAction(title: "block", style: .destructive, handler: { (action) in
                    self.blockUser()
                }))
            }
        }
        
        let friendStatus = user.relationship?.status ?? .none

        if friendStatus != .blocked {
            // Don't show these options when a user has been blocked
            actionSheet.addAction(UIAlertAction(title: "create a group", style: .default, handler: { (action) in
                self.createAGroup()
            }))
            
            actionSheet.addAction(UIAlertAction(title: "send message", style: .default, handler: { (action) in
                self.sendMessageButtonPressed()
            }))
        }
        
        func addFriendAction(title: String, style: UIAlertAction.Style = .default) {
            actionSheet.addAction(UIAlertAction(title: title, style: style, handler: { (action) in
                self.addAsFriend()
            }))
        }
        
        switch friendStatus {
        case .none:
            addFriendAction(title: "send a friend request")
        case .pending:
            if user.relationship?.wasSentToMe == true {
                addFriendAction(title: "send a friend request")
            } else {
                addFriendAction(title: "cancel friend request", style: .destructive)
            }
        case .accepted:
            addFriendAction(title: "unfriend", style: .destructive)
        case .blocked:
            break
        }
        
        actionSheet.addAction(UIAlertAction(title: "cancel", style: .cancel))
        
        actionSheet.show()
    }
    
    private func reportUser() {
        guard let user = user, let signedInUser = DataCoordinator.shared.signedInUser else { return }
        
        AnalyticsManager.track(event: .reportUserButtonPressed, withParameters: ["user": user.identifier])
        
        guard MFMailComposeViewController.canSendMail() else {
            presentGenericAlert(title: "Failed to send email", message: "We were unable to access your email client.")
            return
        }
        
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = self
        mail.setToRecipients(["support@gamegether.com"])
        mail.setSubject("GG Report")
        mail.setMessageBody("Report by \(signedInUser.ign) (\(signedInUser.identifier)) for user: \(user.ign) (\(user.identifier))\n\nPlease be as descriptive as possible. If you are able to, please upload screenshots of the incident.", isHTML: false)
        present(mail, animated: true)
    }
    
    private func blockUser() {
        guard let user = user else { return }
        
        AnalyticsManager.track(event: .blockUserButtonPressed, withParameters: ["user": user.identifier])

        let alert = UIAlertController(title: "Block?",
                                      message: "\(user.ign) will no longer be able to interact and see your activity on GameGether.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "yes", style: .destructive, handler: { (_) in
            
            AnalyticsManager.track(event: .blockUserYesPressed, withParameters: ["user": user.identifier])

            DataCoordinator.shared.blockUser(user.identifier) { [weak self] (error) in
                
                performOnMainThread {
                    if let error = error {
                        self?.presentGenericErrorAlert(message: error.localizedDescription)
                        return
                    }
                    GGHUDView.show(withText: "\(user.ign) has been blocked",
                                   textColor: .white,
                                   backgroundColor: UIColor(hexString: "#1B6BBC"),
                                   duration: 3)
                }
            }
        }))
        
        alert.addAction(UIAlertAction(title: "no", style: .cancel, handler: { (_) in
            AnalyticsManager.track(event: .blockUserNoPressed, withParameters: ["user": user.identifier])
        }))
        
        alert.show()
    }
    
    private func unblockUser() {
        guard let user = user else { return }

        AnalyticsManager.track(event: .unblockUserButtonPressed, withParameters: ["user": user.identifier])

        let alert = UIAlertController(title: "Unblock?",
                                      message: "\(user.ign) will be able to interact and see your activity on GameGether.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "yes", style: .destructive, handler: { (_) in
            
            AnalyticsManager.track(event: .unblockUserYesPressed, withParameters: ["user": user.identifier])
            
            DataCoordinator.shared.unblockUser(user.identifier) { [weak self] (error) in
                
                performOnMainThread {
                    if let error = error {
                        self?.presentGenericErrorAlert(message: error.localizedDescription)
                        return
                    }
                    GGHUDView.show(withText: "\(user.ign) has been unblocked",
                                   textColor: .white,
                                   backgroundColor: UIColor(hexString: "#1B6BBC"),
                                   duration: 3)
                }
            }
        }))
        
        alert.addAction(UIAlertAction(title: "no", style: .cancel, handler: { (_) in
            AnalyticsManager.track(event: .unblockUserNoPressed, withParameters: ["user": user.identifier])
        }))
        
        alert.show()
    }
    
    private func showImagePickerSelectionOptions() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        actionSheet.addAction(UIAlertAction(title: "take photo", style: .default, handler: { (action) in
            self.presentImagePicker(imagePicker: self.imagePicker, sourceType: .camera)
        }))

        actionSheet.addAction(UIAlertAction(title: "camera roll", style: .default, handler: { (action) in
            self.presentImagePicker(imagePicker: self.imagePicker, sourceType: .photoLibrary)
        }))

        actionSheet.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action) in
            actionSheet.dismiss(animated: true, completion: nil)
        }))

        present(actionSheet, animated: true, completion: nil)
    }
    
    private func createAGroup() {
        guard let user = user else { return }
        
        let storyboard = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: NewMessageViewController.storyboardIdentifier) as! NewMessageViewController
        vc.initialUsersToPopulate = [user]
        
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

    private func sendMessageButtonPressed() {
        guard let user = user else { return }
        
        let alertController = UIAlertController(title: "send a message", message: "start a chat to play with this gamer", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.textAlignment = .center
            textField.placeholder = "cool profile, let's play!"
            self.sendMessageTextField = textField
        }
        
        let sendAction = UIAlertAction(title: "send", style: .default) { _ in
            HUD.show(.progress)
            
            self.firebaseChat.createPrivateRoom(withUserIds: [user.identifier]) { [weak self] (chatroom) in
                guard let weakSelf = self else { return }
                
                performOnMainThread {
                    guard let chatroom = chatroom else {
                        performOnMainThread {
                            HUD.flash(.error)
                        }
                        return
                    }
                    
                    // Send the message to the chatroom
                    let messageText = weakSelf.sendMessageTextField?.text?.isEmpty == false ? weakSelf.sendMessageTextField?.text : "cool profile, let’s play!"
                    weakSelf.firebaseChat.sendMessage(text: messageText, toChatroom: chatroom)
                    
                    HUD.hide()
                    let viewController = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: ChatViewController.storyboardIdentifier) as! ChatViewController
                    viewController.chatroom = chatroom
                    weakSelf.navigationController?.pushViewController(viewController, animated: true)
                }
            }
        }
        alertController.addAction(sendAction)
        
        let cancelAction = UIAlertAction(title: "cancel", style: .destructive) { _ in
            // NOP
        }
        alertController.addAction(cancelAction)
        
        alertController.show()
    }
    
    func addAsFriend() {
        guard let user = user else { return }
        
        let status = user.relationship?.status ?? .none
        
        switch status {
        case .none:
            // Send friend request
            sendFriendRequest()
        case .pending:
            
            if user.relationship?.wasSentToMe == true {
                // Accept friend request
                sendFriendRequest()
            } else {
                // Cancel friend request
                cancelFriendRequest()
            }
            
        case .accepted:
            // Unfriend
            let alert = UIAlertController(title: "Wait!", message: "Are you sure you want to unfriend this user?", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "yes", style: .destructive, handler: { (action) in
                self.cancelFriendRequest(notifyUser: false)
            }))
            
            alert.addAction(UIAlertAction(title: "no", style: .cancel))
            alert.show()
            
        case .blocked:
            unblockUser()
        }
    }
    
    private func sendFriendRequest() {
        guard let user = user else { return }
        
        let alertController = UIAlertController(title: "send a friend request", message: "personalize your msg, it’s better =)", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.textAlignment = .center
            textField.placeholder = "hey, let’s be friends on gg!"
            self.sendMessageTextField = textField
        }
        
        let sendAction = UIAlertAction(title: "send", style: .default) { _ in
            
            HUD.show(.progress)
            
            DataCoordinator.shared.addFriend(withUserId: user.identifier) { [weak self] (error, chatroom) in
                performOnMainThread {
                    
                    HUD.hide()
                    
                    guard let weakSelf = self else { return }
                    
                    guard error == nil else {
                        weakSelf.presentGenericErrorAlert()
                        return
                    }
                    
                    if let chatroom = chatroom, let msgText = weakSelf.sendMessageTextField?.text, !msgText.isEmpty {
                        // Send the message to the chatroom
                        weakSelf.firebaseChat.sendMessage(text: msgText, toChatroom: chatroom)
                    }

                    HUD.flash(.label("friend request sent"), delay: 0.5)
                    weakSelf.getLatestProfile()
                }
            }
        }
        alertController.addAction(sendAction)
        
        let cancelAction = UIAlertAction(title: "cancel", style: .destructive) { _ in
            // NOP
        }
        alertController.addAction(cancelAction)
        
        alertController.show()
    }
    
    private func cancelFriendRequest(notifyUser: Bool = true) {
        guard let user = user else { return }
        
        HUD.show(.progress)
        DataCoordinator.shared.cancelFriendRequest(toUser: user.identifier) { [weak self] (error) in
            guard let strongself = self else { return }
            
            performOnMainThread {
                guard error == nil else {
                    HUD.flash(.error)
                    GGLog.error("Error: \(String(describing: error))")
                    strongself.presentGenericErrorAlert()
                    return
                }
                
                HUD.flash(.success)
                strongself.getLatestProfile()
            }
        }
    }
    
    private func showSendMessageDialog(forGame game: Game, withTagsGroup tagsGroup: TagsGroup? = nil) {
        guard let user = user else { return }
        
        guard !user.isSignedInUser else {
            
            NavigationManager.shared.navigationOverlay?.setSelectedTab(.home)
            
            if let tags = tagsGroup?.tags {
                NavigationManager.shared.tabBarController?.homeViewController.selectTags(tags)
            }
            
            return
        }
        
        
        let alertController = UIAlertController(title: "Send a message", message: "Start a chat to play with this gamer", preferredStyle: .alert)
        
        let tagText = tagsGroup?.tags.compactMap({ $0.title }).joined(separator: " ") ?? ""
        let defaultMessage = "Hey, I also play \(game.title) \(tagText)!"
        
        alertController.addTextField { textField in
            textField.textAlignment = .center
            textField.placeholder = defaultMessage
            self.sendMessageTextField = textField
        }
        
        let sendAction = UIAlertAction(title: "send", style: .default) { _ in
            HUD.show(.progress)
            
            AnalyticsManager.track(event: .profileSendMessageTapped,
                                   withParameters: ["gameId": game.title, "tags": tagsGroup?.tags.compactMap({ $0.title }) ?? []])
            
            self.firebaseChat.createPrivateRoom(withUserIds: [user.identifier]) { [weak self] (chatroom) in
                guard let weakSelf = self else { return }
                
                performOnMainThread {
                    guard let chatroom = chatroom else {
                        performOnMainThread {
                            HUD.flash(.error)
                        }
                        return
                    }
                    
                    // Send the message to the chatroom
                    let messageText = weakSelf.sendMessageTextField?.text?.isEmpty == false ? weakSelf.sendMessageTextField?.text : defaultMessage
                    weakSelf.firebaseChat.sendMessage(text: messageText, toChatroom: chatroom)
                    
                    HUD.hide()
                    let viewController = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: ChatViewController.storyboardIdentifier) as! ChatViewController
                    viewController.chatroom = chatroom
                    weakSelf.navigationController?.pushViewController(viewController, animated: true)
                }
            }
        }
        alertController.addAction(sendAction)
        
        let cancelAction = UIAlertAction(title: "cancel", style: .destructive) { _ in
            AnalyticsManager.track(event: .profileCancelSendMessageTapped,
                                   withParameters: ["gameId": game.title, "tags": tagsGroup?.tags.compactMap({ $0.title }) ?? []])
        }
        alertController.addAction(cancelAction)
        
        alertController.show()
    }
}

extension ProfileViewControllerV2: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        layoutHeaders(forScrollView: scrollView)
    }
}

extension ProfileViewControllerV2: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension ProfileViewControllerV2: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 15.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.bounds.width, height: 60)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.bounds.width, height: 43)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if collectionView.cellForItem(at: indexPath) is AddGameCollectionViewCell {
            // Go to add game screen
            let vc = UIStoryboard(name: AppConstants.Storyboards.onboarding, bundle: nil).instantiateViewController(withIdentifier: SelectGameViewController.storyboardIdentifier) as! SelectGameViewController
            NavigationManager.shared.present(vc)
            return
        }
    }
}

extension ProfileViewControllerV2: KeyboardScrollViewDelegate {

    // MARK: Keyboard Notifications
    
    
    func keyboardScrollViewDidAdjustInsets(scrollView: UIScrollView) {
        guard isVisible else { return }

        performOnMainThread {
            self.scrollToFirstResponder()
        }
    }

    @objc func keyboardWillDisappear() {
        guard isVisible else { return }

//        performOnMainThread {
//            self.layoutHeaders(forScrollView: self.collectionView)
//            self.collectionView.scrollToTop()
//        }
    }

    @objc func keyboardWillAppear() {
        guard isVisible else { return }

//        performOnMainThread {
//            self.scrollToFirstResponder()
//        }
    }
    
    private func scrollToFirstResponder() {
        guard let firstResponder = view.firstResponder else { return }
        // Scroll to the first responder if possible
        let responderFrame = CGRect(x: firstResponder.frame.minX,
                                    y: firstResponder.frame.minY,
                                    width: firstResponder.frame.width,
                                    height: firstResponder.frame.height) // add some buffer height so the keyboard scrolls more of the frame into view

        let frame = firstResponder.convert(responderFrame, to: collectionView)
//        collectionView.scrollRectToVisible(frame, animated: true)
        
//        let statusBarHeight = UIApplication.shared.statusBarFrame.height
//        let headerHeights = profileInfoHeaderView.bounds.height + mediaHeaderDefaultHeight + editHeaderView.bounds.height - statusBarHeight
//        let adjustedYOffset = frame.minY - ProfileConstants.minHeaderHeight - ProfileConstants.editHeaderHeight
        
        collectionView.setContentOffset(CGPoint(x: 0, y: frame.minY  - 350), animated: true)
    }
}

// MARK: UIImagePickerControllerDelegate

extension ProfileViewControllerV2: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        var fileData: Data?
        var contentType: S3ContentType = .image
        
        if let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.editedImage)] as? UIImage {
            
            let imageScale: CGFloat
            
            switch imagePickingMode {
            case .profilePicture:
                imageScale = 300
            case .profileMedia(_):
                imageScale = 600
            }
            
            let imageToUpload = UIImage.imageWithImage(sourceImage: image, scaledToWidth: imageScale)
            
            guard let imageData = imageToUpload.jpegRepresentation() else {
                GGLog.error("Failed to convert image to jpeg representation.")
                HUD.flash(.error, delay: 1.0)
                return
            }
            
            fileData = imageData
            contentType = .image
        }
        
        if let videoURL = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.mediaURL)] as? URL, let videoData = try? Data(contentsOf: videoURL) {
            fileData = videoData
            contentType = .video
        }

        guard let dataToUpload = fileData else {
            GGLog.error("Failed to upload: fileData is nil")
            HUD.flash(.error, delay: 1.0)
            return
        }

        HUD.show(.progress)

        DataCoordinator.shared.s3Uploader.upload(data: dataToUpload,
                                                 contentType: contentType,
                                                 progress:
            { [weak self] (task, progress) in
                guard let _ = self else { return }
                GGLog.debug("Upload Progress: \(progress)")

        }) { [weak self] (url, error) in
            performOnMainThread {
                guard let weakSelf = self, error == nil, let url = url else {
                    GGLog.error("Upload Failed: \(String(describing: error?.localizedDescription))")
                    HUD.flash(.error, delay: 1.0)
                    return
                }

                switch weakSelf.imagePickingMode {
                case .profilePicture:
                    weakSelf.updateProfileImage(url: url)
                case .profileMedia(let index):
                    let mediaType: MediaType = contentType == .video ? .video : .image
                    weakSelf.updateProfileMedia(url: url, ofMediaType: mediaType, atIndex: index)
                }
            }
        }

        picker.dismiss(animated: true, completion: nil)
    }

    private func updateProfileImage(url: URL) {
        DataCoordinator.shared.updateProfileImage(withImageURL: url.absoluteString, completion: { [weak self] (updatedUser, error) in
            performOnMainThread {
                guard let weakSelf = self, error == nil else {
                    GGLog.error("Update User Failed: \(String(describing: error?.localizedDescription))")
                    HUD.flash(.error, delay: 1.0)
                    return
                }

                weakSelf.getLatestProfile()
                HUD.flash(.success)
            }
        })
    }
    
    private func updateProfileMedia(url: URL, ofMediaType mediaType: MediaType, atIndex index: Int) {
        guard let user = user else { return }
        
        let indexToReplace = index > user.profileMedia.count ? user.profileMedia.count : index
        
        var profileMedia = user.profileMedia.filter({ $0.index != indexToReplace })
        profileMedia.append(ProfileMedia(type: mediaType, url: url, index: indexToReplace))
        
        DataCoordinator.shared.updateProfileMedia(media: profileMedia, completion: { [weak self] (updatedUser, error) in
            performOnMainThread {
                guard let weakSelf = self, error == nil else {
                    GGLog.error("Update User Failed: \(String(describing: error?.localizedDescription))")
                    HUD.flash(.error, delay: 1.0)
                    return
                }
                
                weakSelf.getLatestProfile()
                weakSelf.profileMediaView.currentPage = indexToReplace // Scroll to the latest uploaded media
                HUD.flash(.success)
            }
        })
    }
}

extension ProfileViewControllerV2 {
    
    // MARK: - Social Link Alerts
    
    private func showSocialLinkAlertDialog(forSocialLink socialLink: SocialLink) {
        guard let user = user else { return }
        
        let title: String
        let message: String
        let placeholder: String

        switch socialLink.type {
        case .youtube:
            title = "enter your complete YouTube url"
            message = ""
            placeholder = "https://youtube.com/"
        default:
            title = "enter your username"
            message = "\(socialLink.type.domain)username"
            placeholder = "enter your username for this account"
        }
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.text = socialLink.username
            textField.textAlignment = .center
            textField.placeholder = placeholder
            self.socialAlertDialogTextField = textField
        }
        
        let saveAction = UIAlertAction(title: "save", style: .default) { _ in
            
            HUD.show(.progress)
            
            guard let username = self.socialAlertDialogTextField?.text else {
                HUD.flash(.error)
                return
            }
            
            let updatedSocialLink = SocialLink(type: socialLink.type, username: username)

            guard let url = updatedSocialLink.url, UIApplication.shared.canOpenURL(url) else {
                HUD.hide()
                GGLog.error("Social link URL is invalid")
                self.presentGenericErrorAlert(message: "This URL is invalid. Please check the link and try again.")
                return
            }

            DataCoordinator.shared.updateSocialLinks(socialLinks: user.socialLinks + [updatedSocialLink], completion: { [weak self] (_, error) in
                guard let weakSelf = self else { return }
                
                performOnMainThread {
                    HUD.hide()
                    
                    guard error == nil else {
                        HUD.flash(.error)
                        GGLog.error("Error: \(String(describing: error))")
                        weakSelf.presentGenericErrorAlert()
                        return
                    }
                    
                    HUD.flash(.success)
                    weakSelf.getLatestProfile()
                }
            })
        }
        alertController.addAction(saveAction)
        
        let cancelAction = UIAlertAction(title: "cancel", style: .destructive) { _ in
            // NOP
        }
        alertController.addAction(cancelAction)
        alertController.show()
    }
}

extension ProfileViewControllerV2: UITextFieldDelegate {
    
    private func presentUpdateGamerTagAlert(forGame game: Game) {
        
        let alertController = GamerTagAlertController(withgame: game,
                                                      title: "update your \(game.title) gamertag",
            onSaveAction: { (ign) in
                AnalyticsManager.track(event: .profileSaveGamerTagPressed)
                
                // Make a mutable copy
                let game = game
                
                game.gamerTag = ign
                
                HUD.show(.progress)
                
                DataCoordinator.shared.updateGamerTag(gamerTag: ign, forGame: game) { [weak self] (_, error) in
                    guard let weakSelf = self else { return }
                    
                    performOnMainThread {
                        HUD.hide()
                        
                        guard error == nil else {
                            weakSelf.presentGenericErrorAlert()
                            return
                        }
                        
                        weakSelf.getLatestProfile()
                    }
                }

        }, onRemoveAction: { (_) in
            AnalyticsManager.track(event: .profileRemoveGamerTagPressed)
            
            HUD.show(.progress)
            
            DataCoordinator.shared.getFavoriteGames({ [weak self]  (favoriteGames, error) in
                guard let weakSelf = self else { return }
                
                let games = favoriteGames.filter({ $0.identifier != game.identifier })
                
                DataCoordinator.shared.setFavoriteGames(games: games, completion: { (error) in
                    
                    performOnMainThread {
                        HUD.hide()
                        
                        guard error == nil else {
                            weakSelf.presentGenericErrorAlert()
                            return
                        }
                        
                        weakSelf.getLatestProfile()
                    }
                })
            })
        })
        
        alertController.show()
    }
    
    private func updateSelectedGames(games: [Game]) {
        guard games.count > 0 else { return }
        
        HUD.show(.progress)
        
        DataCoordinator.shared.setFavoriteGames(games: games) { [weak self] (error) in
            guard let strongself = self else { return }
            
            performOnMainThread {
                HUD.hide()
                
                guard error == nil else {
                    strongself.presentGenericErrorAlert()
                    return
                }
                
                strongself.getLatestProfile()
                
                HUD.show(.success)
            }
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}

extension ProfileViewControllerV2: MFMailComposeViewControllerDelegate {

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismissSelf()
    }
}
