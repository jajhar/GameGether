//
//  ScheduleSessionViewController.swift
//  GameGether
//
//  Created by James Ajhar on 9/8/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit
import PKHUD

class ScheduleSessionViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var darkenedBackgroundView: UIView!
    @IBOutlet weak var sessionTypeSelectorContainerView: UIView!
    @IBOutlet weak var calendarView: GGCalendarView!
    
    // MARK: - Properties
    private var schedulingHeaderVC: ScheduleSessionHeaderViewController?
    private var infoVC: ScheduleSessionInfoViewController?
    private var timeSelectorVC: ScheduleSessionTimeSelectorViewController?
    private var actionsVC: ScheduleSessionActionsViewController?
    private var sessionTypeSelectorVC: SessionTypeSelectorViewController?
    
    private var existingSession: GameSession? {
        didSet {
            if let session = existingSession {
                schedulingHeaderVC?.game = session.game
                schedulingHeaderVC?.tags = session.tags
                infoVC?.date = session.begins
                infoVC?.descriptionText = session.description
                infoVC?.sessionType = session.sessionType
                schedulingHeaderVC?.gameTypeLabel.text = session.sessionType?.title
                
            } else {
                schedulingHeaderVC?.game = game
                schedulingHeaderVC?.tags = tags
                infoVC?.descriptionText = requestText
                infoVC?.sessionType = sessionType
                schedulingHeaderVC?.gameTypeLabel.text = sessionType?.title
            }
            
            toggleDarkenedBackground(visible: existingSession?.isJoined == true)
        }
    }
    
    private var requestText: String?
    private var maxPartySize: UInt?

    var sessionType: GameSessionType? {
        return sessionTypeSelectorVC?.selectedType
    }
    
    var game: Game?
    var tags: [Tag]?
    var initialDate: Date = Date.now
    var initialSessionType: GameSessionTypeIdentifier?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        fetchExistingSessions()
                
        if let gameModeTag = tags?.gameModeTag() {
            sessionTypeSelectorVC?.selectType(withAssociatedTag: gameModeTag)
        } else if let type = initialSessionType {
            sessionTypeSelectorVC?.selectType(type)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if game == nil || tags == nil || tags?.isEmpty == true {
            presentGameSelectorView()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let vc = segue.destination as? ScheduleSessionHeaderViewController {
            vc.game = game
            vc.tags = tags
            schedulingHeaderVC = vc
            
            schedulingHeaderVC?.onGameIconTapped = { [weak self] in
                guard let weakSelf = self else { return }
                AnalyticsManager.track(event: .scheduleSessionGameIconTapped)
                weakSelf.presentGameSelectorView()
            }
            
            schedulingHeaderVC?.onTypeSelectorTapped = { [weak self] in
                guard let weakSelf = self else { return }
                weakSelf.presentSessionTypeSelectorView()
            }
            
        } else if let vc = segue.destination as? ScheduleSessionInfoViewController {
            
            vc.onRequestTextTapped = { [weak self] in
                let storyboard = UIStoryboard(name: AppConstants.Storyboards.scheduling, bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: RequestSessionTextInputViewController.storyboardIdentifier) as! RequestSessionTextInputViewController
                vc.initialText = self?.requestText
                vc.game = self?.game
                vc.selectedTags = self?.tags ?? []

                vc.onTextSubmitted = { [weak self] (text, partySize) in
                    self?.requestText = text
                    self?.maxPartySize = partySize
                    self?.infoVC?.descriptionText = text
                    vc.dismissSelf()
                }
                
                NavigationManager.shared.present(vc)
            }
            
            infoVC = vc
            
        } else if let vc = segue.destination as? ScheduleSessionTimeSelectorViewController {
            timeSelectorVC = vc
            
            vc.initialDate = initialDate
            
            timeSelectorVC?.onJoinSessionPressed = { [weak self] (session) in
                guard let weakSelf = self else { return }
                AnalyticsManager.track(event: .scheduleSessionJoinButtonTapped)
                
                weakSelf.presentPushNotificationAlertIfNeeded {
                    weakSelf.joinGameSession(session)
                }
            }
            
            timeSelectorVC?.onSelectedDateDidChange = { [weak self] (date, existingSession) in
                guard let weakSelf = self else { return }
                
                weakSelf.infoVC?.date = date
                weakSelf.calendarView.selectDate(date)
                weakSelf.existingSession = existingSession

                if let session = existingSession {
                    
                    if session.isJoined {
                        // Found a conflicting session that this user has joined.
                        weakSelf.actionsVC?.ctaButtonState = .cancel
                    } else if session.game?.identifier == weakSelf.game?.identifier {
                        // Found a conflicting session that this user can join
                        weakSelf.actionsVC?.ctaButtonState = .join
                    } else {
                        weakSelf.actionsVC?.ctaButtonState = .create
                    }
                    
                } else {
                    weakSelf.actionsVC?.ctaButtonState = .create
                }
                
                weakSelf.actionsVC?.updateTomorrowButton(withDate: date.addDays(1) ?? date)
            }
            
        } else if let vc = segue.destination as? ScheduleSessionActionsViewController {
            actionsVC = vc

            actionsVC?.onCalendarPressed = { [weak self] in
                guard let weakSelf = self else { return }
                AnalyticsManager.track(event: .scheduleSessionCalendarTapped)
                weakSelf.toggleCalendar(visible: true)
            }
            
            actionsVC?.onCTAButtonPressed = { [weak self] (buttonState) in
                guard let weakSelf = self else { return }
                
                weakSelf.presentPushNotificationAlertIfNeeded {
                    switch buttonState {
                    case .create:
                        AnalyticsManager.track(event: .scheduleSessionCreateTapped)
                        weakSelf.createGameSession()
                    case .join:
                        if let session = weakSelf.existingSession {
                            AnalyticsManager.track(event: .scheduleSessionJoinButtonTapped)
                            weakSelf.joinGameSession(session)
                        }
                    case .cancel:
                        AnalyticsManager.track(event: .scheduleSessionCancelTapped)

                        GGHUDView.show(withText: "Hold to cancel",
                                       textColor: .white,
                                       backgroundColor: UIColor(hexString: "#1C6EB9"),
                                       duration: 1)
                    }
                }
            }
            
            actionsVC?.onCTAButtonHeld = { [weak self] (buttonState) in
                guard let weakSelf = self, buttonState == .cancel, let session = weakSelf.existingSession else { return }
                weakSelf.leaveGameSession(session)
            }

            actionsVC?.onTomorrowPressed = { [weak self] in
                guard let weakSelf = self else { return }
                let curDate = weakSelf.timeSelectorVC?.dateSelectorCollectionView.selectedDate.date ?? Date.now
                let tomorrow = curDate.addDays(1) ?? curDate
                self?.timeSelectorVC?.selectDate(tomorrow)
            }
            
        } else if let vc = segue.destination as? SessionTypeSelectorViewController {
            vc.game = game

            vc.onTypeSelected = { [weak self] (type) in
                self?.schedulingHeaderVC?.setSessionType(type)
                self?.infoVC?.sessionType = type
                self?.swapGameModeTagIfNeeded(forSessionType: type)
                
                UIView.animate(withDuration: 0.3) {
                    self?.sessionTypeSelectorContainerView.alpha = 0
                }
                
                // refresh all existing sessions given the new type
                self?.fetchExistingSessions()
            }

            sessionTypeSelectorVC = vc
        }
    }

    private func toggleCalendar(visible: Bool) {
        let alpha: CGFloat = visible ? 1 : 0
        
        if visible {
            calendarView.onDateSelected = { [weak self] (date) in
                AnalyticsManager.track(event: .scheduleSessionCalendarDateSelected, withParameters: [
                    "date": date.schedulingFormattedString(shorthandWeekday: true, includeTime: true)
                    ])
                
                self?.toggleCalendar(visible: false)
                self?.timeSelectorVC?.selectDate(date, animated: false)
            }
        } else {
            calendarView.onDateSelected = nil
        }
        
        UIView.animate(withDuration: 0.3) {
            self.calendarView.alpha = alpha
        }
    }
    
    private func presentGameSelectorView() {
        let storyboard = UIStoryboard(name: AppConstants.Storyboards.scheduling, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: ScheduleSessionGameTagsModalViewController.storyboardIdentifier) as! ScheduleSessionGameTagsModalViewController
        vc.selectedGame = game
        vc.selectedTags = tags ?? []
        
        vc.onGameSelected = { [weak self] (game, tags) in
            guard let weakSelf = self else { return }
            
            AnalyticsManager.track(event: .scheduleSessionGameSelected, withParameters: [
                "game": game.title,
                "tags": tags.compactMap({ $0.jsonValue })
                ])
            
            weakSelf.game = game
            weakSelf.tags = tags
            
            if let gameModeTag = tags.gameModeTag() {
                weakSelf.sessionTypeSelectorVC?.selectType(withAssociatedTag: gameModeTag)
            }
            
            weakSelf.schedulingHeaderVC?.game = game
            weakSelf.schedulingHeaderVC?.tags = tags
            weakSelf.fetchExistingSessions()
            weakSelf.sessionTypeSelectorVC?.game = game
            vc.dismissSelf()
        }

        vc.onCancelPressed = { [weak self] in
            guard let weakSelf = self else { return }

            AnalyticsManager.track(event: .scheduleSessionSelectGameCancelTapped)
            
            guard weakSelf.game != nil, let tags = weakSelf.tags, !tags.isEmpty else {
                // dismiss everything
                vc.dismissSelf(animated: false, completion: {
                    weakSelf.dismissSelf()
                })
                return
            }
            vc.dismissSelf()
        }
        
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        NavigationManager.shared.present(vc)
    }
    
    private func presentSessionTypeSelectorView() {
        sessionTypeSelectorContainerView.isHidden = false
        sessionTypeSelectorContainerView.alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.sessionTypeSelectorContainerView.alpha = 1
        }
    }
    
    private func swapGameModeTagIfNeeded(forSessionType sessionType: GameSessionType) {
        guard var tags = tags, let gameModeTag = sessionType.associatedTags.filter({ $0.type == .gameMode }).first else { return}
        tags.removeAll(where: { $0.type == .gameMode })
        tags.append(gameModeTag)
        tags.sortByType()
        self.tags = tags
        schedulingHeaderVC?.tags = tags
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
    
    private func createGameSession() {
        
        guard let game = game, let tags = tags, !tags.isEmpty else {
            presentGameSelectorView()
            return
        }
        
        guard let startTime = timeSelectorVC?.dateSelectorCollectionView.selectedDate, !startTime.isBlockOutDate else { return }
        
        guard let sessionType = self.sessionType else { return }
        
        if sessionType.type == .request && (requestText == nil || requestText?.isEmpty == true) {
            // Missing info for this session
            presentGenericAlert(title: "Wait!", message: "We need some more info before we can create your request. Please fill in the missing info.")
            return
        }
        
        HUD.show(.progress)
        
        // Disable the UI while this request goes through
        view.isUserInteractionEnabled = false
        
        DataCoordinator.shared.scheduleGameSession(ofType: sessionType,
                                                   forGame: game.identifier,
                                                   withTags: tags,
                                                   startTime: startTime.date,
                                                   maxSize: maxPartySize,
                                                   sessionDescription: requestText ?? "")
        { [weak self] (newSession, chatroomId, error) in
            guard let weakSelf = self else { return }
            
            performOnMainThread {
                HUD.hide()

                if let error = error {
                    weakSelf.view.isUserInteractionEnabled = true
                    GGLog.error(error.localizedDescription)
                    weakSelf.presentGenericErrorAlert()
                    return
                }
                
                GGHUDView.show(withText: "Session Scheduled!",
                               subText: "You’ll receive a 5 min\nreminder before it starts!",
                               textColor: .white,
                               backgroundColor: UIColor(hexString: "#1C6EB9"),
                               duration: 3)
                { () in
                    weakSelf.dismissSelf()
                }
            }
        }
    }
    
    private func joinGameSession(_ session: GameSession) {
        
        AnalyticsManager.track(event: .sessionJoined, withParameters: ["session": session.identifier])

        HUD.show(.progress)
        
        // Disable the UI while this request goes through
        view.isUserInteractionEnabled = false

        DataCoordinator.shared.joinGameSession(session, completion: { [weak self] (_, error) in
            guard let weakSelf = self else { return }

            performOnMainThread {
                HUD.hide()
                
                if let error = error {
                    GGLog.error(error.localizedDescription)
                    weakSelf.view.isUserInteractionEnabled = true
                    weakSelf.presentGenericErrorAlert(message: error.localizedDescription)
                    return
                }

                GGHUDView.show(withText: "Session Scheduled!",
                               subText: "you’ll receive a 5 min\nreminder before it starts!",
                               textColor: .white,
                               backgroundColor: UIColor(hexString: "#1C6EB9"),
                               duration: 3)
                { () in
                    weakSelf.dismissSelf()
                }
            }
        })
    }

    private func leaveGameSession(_ session: GameSession) {
        
        HUD.show(.progress)
        
        DataCoordinator.shared.leaveGameSession(session, completion: { [weak self] (error) in
            guard let weakSelf = self else { return }
            
            performOnMainThread {
                HUD.hide()
                
                if let error = error {
                    GGLog.error(error.localizedDescription)
                    weakSelf.presentGenericErrorAlert()
                    return
                }
                
                weakSelf.fetchExistingSessions()
            }
        })
    }

    private func fetchExistingSessions() {
        guard let game = game, let sessionType = sessionType else { return }
                
        HUD.show(.progress)
        
        // start fresh
        timeSelectorVC?.existingSessions.removeAll()
        
        let group = DispatchGroup()

        if sessionType.type != GameSessionTypeIdentifier.request {
            // DO NOT FETCH SESSIONS OF TYPE REQUEST (REQUEST type sessions can overlap)
            
            group.enter()
            // Get available game sessions for this game
            DataCoordinator.shared.getGameSessions(forGame: game.identifier,
                                                   withTags: tags,
                                                   ofType: sessionType) { [weak self] (sessions, error) in
                guard let weakSelf = self else { return }
                if let error = error {
                    GGLog.error(error.localizedDescription)
                    group.leave()
                    return
                }
                
                performOnMainThread {
                    weakSelf.timeSelectorVC?.existingSessions.append(contentsOf: sessions)
                    group.leave()
                }
            }
        }
    
        group.enter()
        // Get ALL game sessions I am attending, regardless of game
        DataCoordinator.shared.getGameSessionsAttending() { [weak self] (sessions, error) in
            guard let weakSelf = self else { return }
            if let error = error {
                GGLog.error(error.localizedDescription)
                group.leave()
                return
            }
            
            performOnMainThread {
                weakSelf.timeSelectorVC?.existingSessions.append(contentsOf: sessions)
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            HUD.hide()
        }
    }
    
    private func toggleDarkenedBackground(visible: Bool) {
        let newAlpha: CGFloat = visible ? 1 : 0
        UIView.animate(withDuration: 0.3) {
            self.darkenedBackgroundView.alpha = newAlpha
        }
        
        timeSelectorVC?.toggleDarkenedBackground(visible: visible)
        actionsVC?.toggleDarkenedBackground(visible: visible)
    }
    
    // MARK: - Interface Actions
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        AnalyticsManager.track(event: .scheduleSessionBackButtonTapped)
        dismissSelf()
    }
}
