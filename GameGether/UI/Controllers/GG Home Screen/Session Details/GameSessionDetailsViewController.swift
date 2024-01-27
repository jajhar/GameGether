//
//  GameSessionDetailsViewController.swift
//  GameGether
//
//  Created by James Ajhar on 11/5/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit
import PKHUD

class GameSessionDetailsViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var sessionImageView: UIImageView!
    @IBOutlet weak var gameIconImageView: UIImageView!
    @IBOutlet weak var tagsCollectionView: TagsDisplayCollectionView!
    
    @IBOutlet weak var goToLobbyButton: UIButton! {
        didSet {
            goToLobbyButton.titleLabel?.font = AppConstants.Fonts.robotoMedium(17).font
            goToLobbyButton.setTitleColor(UIColor(hexString: "#3399FF"), for: .normal)
        }
    }
    
    @IBOutlet weak var closeButton: UIButton! {
        didSet {
            closeButton.titleLabel?.font = AppConstants.Fonts.robotoRegular(17).font
            closeButton.setTitleColor(.black, for: .normal)
        }
    }
    
    @IBOutlet weak var usersTableView: UITableView! {
        didSet {
            usersTableView.dataSource = self
            usersTableView.delegate = self
            usersTableView.register(UINib(nibName: "\(UserTableViewCell.self)", bundle: nil), forCellReuseIdentifier: UserTableViewCell.reuseIdentifier)
        }
    }
    
    @IBOutlet weak var sessionDescriptionLabel: UILabel! {
        didSet {
            sessionDescriptionLabel.font = AppConstants.Fonts.robotoMedium(14).font
        }
    }
    
    // MARK: - Properties
    public var onClosePressed: (() -> Void)?
    public var onGoToLobbyPressed: ((GameSession) -> Void)?
    public var session: GameSession?
    public var onSessionJoined: ((GameSession) -> Void)?
    public var onSessionLeft: ((GameSession) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addDropShadow(color: .black, opacity: 0.3, offset: CGSize(width: 1, height: 1), radius: 6)

        if let session = session {
            configureView(withSession: session)
        }
    }
    
    private func configureView(withSession session: GameSession) {

        sessionImageView.sd_setImage(with: session.game?.tagThemeImageURL ?? session.createdBy?.profileImageURL, completed: nil)

        tagsCollectionView.tags = session.tags
        gameIconImageView.sd_setImage(with: session.game?.iconImageURL, completed: nil)
        
        sessionDescriptionLabel.text = session.description
        usersTableView.reloadData()
    }
        
    private func joinGameSession(_ session: GameSession) {
        guard let user = DataCoordinator.shared.signedInUser else {
            // onboarding, go to create account screen
            let viewController = UIStoryboard(name: AppConstants.Storyboards.onboarding, bundle: nil).instantiateViewController(withIdentifier: RegisterUserViewController.storyboardIdentifier)
            let nav = GGNavigationViewController(rootViewController: viewController)
            NavigationManager.shared.present(nav)
            return
        }
        
        guard !session.isJoined else {
            // already in session
            onGoToLobbyPressed?(session)
            return
        }
        
        if session.sessionType?.type != .request, session.begins <= Date.now {
            // Session has already started, go directly to lobby
            let alert = UIAlertController(title: "Session in progress",
                                          message: "It looks like this session has already started. Would you like us to take you there now?",
                                          preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "take me there!", style: .default, handler: { [weak self] (_) in
                self?.onGoToLobbyPressed?(session)
            }))
            
            alert.addAction(UIAlertAction(title: "not right now", style: .destructive, handler: nil))
            alert.show()

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
                
                AnalyticsManager.track(event: .sessionJoined, withParameters: nil)

                session.updateJoinedState(isJoined: true)
                session.addAttendee(user)
                self?.configureView(withSession: session)
                
                if let chatroomId = chatroomId {
                    // If there is a chatroom associated with this session, go to it now.
                    
                    FirebaseChat().fetchChatroom(chatroomId) { (chatroom) in
                        guard let chatroom = chatroom else { return }
                            
                        performOnMainThread {let viewController = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: ChatViewController.storyboardIdentifier) as! ChatViewController
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
                
                self?.onSessionJoined?(session)
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
                
                AnalyticsManager.track(event: .sessionLeft, withParameters: nil)

                session.updateJoinedState(isJoined: false)
                session.removeAttendee(user)
                self?.configureView(withSession: session)
                
                GGHUDView.show(withText: "session left",
                               textColor: .white,
                               backgroundColor: UIColor(hexString: "#BE2F2F").withAlphaComponent(0.9))
                
                self?.onSessionLeft?(session)
            }
        }
    }

    private func showProfileQuickView(forUser user: User) {
        let storyboard = UIStoryboard(name: AppConstants.Storyboards.profile, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: ProfileQuickViewController.storyboardIdentifier) as! ProfileQuickViewController
        vc.user = user
                
        vc.onBackgroundTapped = { (viewController) in
            viewController.animateOut {
                viewController.view.removeFromSuperview()
                viewController.removeFromParent()
                AnalyticsManager.track(event: .quickViewClosed, withParameters: nil)
            }
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

    // MARK: - Interface Actions
    
    @IBAction func closeButtonPressed(_ sender: UIButton) {
        AnalyticsManager.track(event: .sessionDetailCloseTapped, withParameters: ["session": session?.identifier ?? ""])
        onClosePressed?()
    }
    
    @IBAction func goToLobbyButtonPressed(_ sender: UIButton) {
        guard let session = session else { return }
        AnalyticsManager.track(event: .sessionLeft, withParameters: ["session": session.identifier])
        
        joinGameSession(session)
    }
    
    @IBAction func joinButtonPressed(_ sender: UIButton) {
        guard let session = session else { return }
        
        if session.isJoined {
            leaveGameSession(session)
        } else {
            
            presentPushNotificationAlertIfNeeded { [weak self] in
                self?.joinGameSession(session)
            }
        }
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
}

extension GameSessionDetailsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return session?.attendees.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UserTableViewCell.reuseIdentifier, for: indexPath) as! UserTableViewCell
       
        let user = session?.attendees[indexPath.row]
        
        if user?.identifier == session?.createdBy?.identifier {
            cell.availabilityPrefixText = "host - "
        }
             
        cell.user = user

        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let session = session else { return nil }
        
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = AppConstants.Fonts.robotoRegular(13).font
        label.textColor = UIColor(hexString: "#989898")
        view.addSubview(label)
        label.constrainToCenterVertical()
        label.constrainTo(edge: .left)?.constant = 12
        
        label.text = "\(session.userCount) player\(session.userCount > 1 ? "s" : "") \(session.userCount > 1 ? "have" : "has") joined"
        
        view.constrainHeight(40)
        
        return view
    }
 
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        guard let session = session else { return }
        showProfileQuickView(forUser: session.attendees[indexPath.row])
    }
}
