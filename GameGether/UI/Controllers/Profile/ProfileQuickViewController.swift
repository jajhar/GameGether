//
//  ProfileQuickViewController.swift
//  GameGether
//
//  Created by James Ajhar on 12/18/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import MarqueeLabel
import PKHUD
import MessageUI

class ProfileQuickViewController: UIViewController {

    // MARK: Outlets
    @IBOutlet weak var avatarImageView: AvatarInitialsImageView!
    @IBOutlet weak var userStatusImageView: UserStatusImageView!
    @IBOutlet weak var ignLabel: UILabel!
    @IBOutlet weak var playStyleLabel: MarqueeLabel!
    @IBOutlet weak var profileMediaContainerView: UIView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var gamerTagsContainerView: UIView!
    @IBOutlet weak var contentViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageButton: UIButton!
    
    // MARK: Properties
    var user: User?
    var onBackgroundTapped: ((ProfileQuickViewController) -> Void)?
    private let firebaseChat = FirebaseChat()
    private var sendMessageTextField: UITextField?

    lazy var profileMediaView: ProfileMediaContainerView = {
        let view = UINib(nibName: "\(ProfileMediaContainerView.self)", bundle: nil).instantiate(withOwner: self, options: nil).first! as! ProfileMediaContainerView
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        firebaseChat.signIn()
        
        addGamerTagsView()
        styleUI()
        
        profileMediaContainerView.addSubview(profileMediaView)
        profileMediaView.constrainToSuperview()
        
        profileMediaView.onVideoTapped = { (player) in
            guard let url = player.url else { return }
            let player = AVPlayer(url: url)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
    
            NavigationManager.shared.present(playerViewController, animated: true) {
                playerViewController.player?.play()
            }
        }

        let backgroundTapGesture = UITapGestureRecognizer(target: self, action: #selector(ProfileQuickViewController.backgroundTapped(recognizer:)))
        backgroundView.addGestureRecognizer(backgroundTapGesture)
        
        let ignTapGesture = UITapGestureRecognizer(target: self, action: #selector(ProfileQuickViewController.ignLabelTapped(recognizer:)))
        ignLabel.isUserInteractionEnabled = true
        ignLabel.addGestureRecognizer(ignTapGesture)

        let gamerTagsTapGesture = UITapGestureRecognizer(target: self, action: #selector(ProfileQuickViewController.gamerTagsTapped(recognizer:)))
        gamerTagsContainerView.addGestureRecognizer(gamerTagsTapGesture)

        let panner = UIPanGestureRecognizer(target: self,
                                            action: #selector(ProfileQuickViewController.panDidFire(panner:)))
        contentView.addGestureRecognizer(panner)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getLatestProfile()
        profileMediaView.resumePlayer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        profileMediaView.pausePlayer()
    }
    
    private func styleUI() {
        ignLabel.font = AppConstants.Fonts.robotoMedium(15).font
        playStyleLabel.font = AppConstants.Fonts.robotoLight(13).font
        playStyleLabel.textColor = UIColor(hexString: "#828282")
        
        profileMediaView.mediaScrollView.cornerRadius = 11
        profileMediaView.videoPlayerGravity = .resizeAspectFill
        
        // Ask to play Button
        messageButton.titleLabel?.font = AppConstants.Fonts.robotoMedium(14).font
        messageButton.cornerRadius = 15
    }
    
    private func addGamerTagsView() {
        guard let user = user else { return }
        let vc = GamerTagsPopUpViewController()
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        vc.setupWithUser(user)
        vc.showDropShadow = false
        vc.willMove(toParent: self)
        addChild(vc)
        gamerTagsContainerView.addSubview(vc.view)
        vc.view.constrainToSuperview()
        vc.didMove(toParent: self)
    }
    
    private func getLatestProfile() {
        guard let user = user else { return }
        
        DataCoordinator.shared.getProfile(forUser: user.identifier, allowCache: false) { [weak self] (updatedUserProfile, error) in
            guard let weakSelf = self, error == nil else {
                GGLog.error("Error: \(String(describing: error))")
                return
            }
            
            if let user = updatedUserProfile {
                weakSelf.setupWithUser(user: user)
            }
        }
    }

    private func setupWithUser(user: User) {
        self.user = user

        avatarImageView.configure(withUser: user, andFont: AppConstants.Fonts.robotoRegular(30).font)

        user.observeStatus { [weak self] (status, _) in
            self?.userStatusImageView.status = status
        }

        playStyleLabel.text = user.tagline
        ignLabel.text = user.ign
        
        profileMediaView.user = user
        
        // Can't start a chat with yourself
        messageButton.isHidden = user.isSignedInUser || user.relationship?.status == .blocked
        
        view.layoutIfNeeded()
    }
    
    func animateIn(completion: (() -> Void)? = nil) {
        backgroundView.alpha = 0.0
        
        contentViewBottomConstraint.constant = -(contentView.bounds.height + avatarImageView.bounds.height / 2)
        
        UIView.animate(withDuration: 0.3, animations: {
            self.backgroundView.alpha = 0.1
        }) { (_) in
            
            UIView.animate(withDuration: 0.3, animations: {
                self.contentViewBottomConstraint.constant = 0
                self.view.layoutIfNeeded()
                
            }, completion: { (_) in
                completion?()
            })
        }
    }
    
    func animateOut(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.3, animations: {
            self.contentViewBottomConstraint.constant = -(self.contentView.bounds.height + self.avatarImageView.bounds.height / 2)
            self.view.layoutIfNeeded()
        }) { (_) in
            
            UIView.animate(withDuration: 0.3, animations: {
                self.backgroundView.alpha = 0
            }, completion: { (_) in
                completion?()
            })
        }
    }

    // MARK: Pan Gesture Handling
    
    @objc func panDidFire(panner: UIPanGestureRecognizer) {
        let offset = panner.translation(in: self.view)
        contentViewBottomConstraint.constant = -offset.y > 0 ? 0 : -offset.y
        view.layoutIfNeeded()

        if panner.state == .ended || panner.state == .cancelled {
            
            if -contentViewBottomConstraint.constant > contentView.bounds.height / 8 {
                // Dismiss
                onBackgroundTapped?(self)
            } else {
                // Expand back out
                UIView.animate(withDuration: 0.3) {
                    self.contentViewBottomConstraint.constant = 0
                    self.view.layoutIfNeeded()
                }
            }
        }
    }

    // MARK: Interface Actions
    
    @objc func backgroundTapped(recognizer: UITapGestureRecognizer) {
        onBackgroundTapped?(self)
    }
    
    @objc func ignLabelTapped(recognizer: UITapGestureRecognizer) {
        AnalyticsManager.track(event: .quickViewIGNTapped, withParameters: nil)

        let viewController = UIStoryboard(name: AppConstants.Storyboards.profile, bundle: nil).instantiateViewController(withIdentifier: ProfileViewControllerV2.storyboardIdentifier) as! ProfileViewControllerV2
        viewController.user = user
        NavigationManager.shared.push(viewController)
    }
    
    @objc func gamerTagsTapped(recognizer: UITapGestureRecognizer) {
        AnalyticsManager.track(event: .quickViewGamerTagsTapped, withParameters: nil)
        
        let viewController = UIStoryboard(name: AppConstants.Storyboards.profile, bundle: nil).instantiateViewController(withIdentifier: ProfileViewControllerV2.storyboardIdentifier) as! ProfileViewControllerV2
        viewController.user = user
        NavigationManager.shared.push(viewController)
    }
    
    @IBAction func profileImageViewTapped(_ sender: UIButton) {
        guard DataCoordinator.shared.isUserSignedIn() else {
            // onboarding, go to create account screen
            let viewController = UIStoryboard(name: AppConstants.Storyboards.onboarding, bundle: nil).instantiateViewController(withIdentifier: RegisterUserViewController.storyboardIdentifier)
            let nav = GGNavigationViewController(rootViewController: viewController)
            NavigationManager.shared.present(nav)
            return
        }
        
        AnalyticsManager.track(event: .quickViewProfileImageTapped, withParameters: nil)

        let viewController = UIStoryboard(name: AppConstants.Storyboards.profile, bundle: nil).instantiateViewController(withIdentifier: ProfileViewControllerV2.storyboardIdentifier) as! ProfileViewControllerV2
        viewController.user = user
        NavigationManager.shared.push(viewController)
    }
    
    @IBAction func infoButtonPressed(_ sender: UIButton) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "report", style: .destructive, handler: { (action) in
            self.reportUser()
        }))
     
        actionSheet.addAction(UIAlertAction(title: "cancel", style: .cancel))
        
        actionSheet.show()
    }
    
    @IBAction func quickChatButtonPressed(_ sender: UIButton) {
        guard let user = user else { return }
        
        guard DataCoordinator.shared.isUserSignedIn() else {
            // onboarding, go to create account screen
            let viewController = UIStoryboard(name: AppConstants.Storyboards.onboarding, bundle: nil).instantiateViewController(withIdentifier: RegisterUserViewController.storyboardIdentifier)
            let nav = GGNavigationViewController(rootViewController: viewController)
            NavigationManager.shared.present(nav)
            return
        }
        
        AnalyticsManager.track(event: .quickViewPlayWithTapped, withParameters: nil)

        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "create a group", style: .default, handler: { (action) in
            AnalyticsManager.track(event: .quickViewPlayWithCreateGroupTapped, withParameters: nil)

            let storyboard = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: NewMessageViewController.storyboardIdentifier) as! NewMessageViewController
            vc.initialUsersToPopulate = [user]
            
            vc.onChatroomCreation = { (newMessageVC, chatroom) in
                newMessageVC.dismissSelf(animated: true, completion: {
                    // Navigate to the new private chatroom
                    let viewController = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: ChatViewController.storyboardIdentifier) as! ChatViewController
                    viewController.chatroom = chatroom
                    NavigationManager.shared.push(viewController, animated: true)
                })
            }
            
            NavigationManager.shared.push(vc)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "send a message", style: .default, handler: { (action) in
            AnalyticsManager.track(event: .quickViewPlayWithSendMessageTapped, withParameters: nil)
            self.showSendMessageDialog()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (_) in
            AnalyticsManager.track(event: .quickViewPlayWithCancelTapped, withParameters: nil)
        }))
        
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

    private func showSendMessageDialog() {
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
                    NavigationManager.shared.push(viewController)
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
}

extension ProfileQuickViewController: MFMailComposeViewControllerDelegate {

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismissSelf()
    }
}
