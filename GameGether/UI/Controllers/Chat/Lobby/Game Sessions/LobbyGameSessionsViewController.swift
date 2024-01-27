//
//  LobbyGameSessionsViewController.swift
//  GameGether
//
//  Created by James Ajhar on 9/9/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class LobbyGameSessionsViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var calendarView: GGCalendarView! {
        didSet {
            calendarView.onDateSelected = { [weak self] (date) in
                let formatter = DateFormatter()
                formatter.dateFormat = "EEE, MMM d"
                let dateString = formatter.string(from: date)

                self?.dateSliderHeaderBar.moreButtonTitle = dateString
                self?.reloadSessions(minStartTime: date)
                self?.calendarView.isHidden = true
            }
        }
    }
    
    @IBOutlet weak var createSessionButton: UIButton! {
        didSet {
            createSessionButton.titleLabel?.font = AppConstants.Fonts.robotoMedium(16).font
            createSessionButton.tintColor = UIColor(hexString: "#57A2E1")
        }
    }
    
    @IBOutlet weak var dateSliderHeaderBar: DateSliderHeaderBar!
    
    @IBOutlet weak var dateHeaderLabel: UILabel! {
        didSet {
            dateHeaderLabel.font = AppConstants.Fonts.robotoMedium(17).font
        }
    }
    
    @IBOutlet weak var sessionsCollectionView: GameSessionsCollectionView! {
        didSet {
            
            sessionsCollectionView.filter = .allSessions
            
            sessionsCollectionView.onCreateSessionCellTapped = { [weak self] (date) in
                AnalyticsManager.track(event: .sessionEmptyStateTapped,
                                       withParameters: ["date": date.schedulingFormattedString(shorthandWeekday: true, includeTime: false)])
                
                self?.goToCreateSession(withInitialDate: date)
            }
            
            sessionsCollectionView.onSessionSelected = { [weak self] (session) in
                self?.onSessionSelected?(session)
            }
                        
            sessionsCollectionView.onSectionChanged = { [weak self] (title, _) in
                guard let weakSelf = self else { return }
                weakSelf.dateHeaderLabel.text = title
            }
        }
    }
    
    // MARK: - Properties
    var game: Game?
    
    var tags: [Tag]? {
        didSet {
            reloadSessions(minStartTime: minStartTime)
        }
    }
    
    var onSessionSelected: ((GameSession) -> Void)?

    private(set) var minStartTime: Date?
    private(set) var maxStartTime: Date?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateSliderHeaderBar.onTodayPressed = { [weak self] in
            self?.calendarView.isHidden = true
            self?.dateSliderHeaderBar.moreButtonTitle = "more"
            self?.calendarView.deselectAllDates()
            self?.reloadSessions(minStartTime: nil, maxStartTime: Date.today.endOfDay)
        }
        
        dateSliderHeaderBar.onTomorrowPressed = { [weak self] in
            self?.calendarView.isHidden = true
            self?.dateSliderHeaderBar.moreButtonTitle = "more"
            self?.calendarView.deselectAllDates()
            self?.reloadSessions(minStartTime: Date.tomorrow?.startOfDay, maxStartTime: Date.tomorrow?.endOfDay)
        }

        dateSliderHeaderBar.onMorePressed = { [weak self] in
            self?.calendarView.isHidden = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reloadSessions(minStartTime: minStartTime, maxStartTime: maxStartTime)
    }
    
    func reloadSessions(minStartTime: Date? = nil, maxStartTime: Date? = nil) {
        guard let game = game else { return }
        
        self.minStartTime = minStartTime
        self.maxStartTime = maxStartTime
        
        sessionsCollectionView.reloadDataSource(withGame: game, andTags: tags, minStartTime: minStartTime, maxStartTime: maxStartTime)
        sessionsCollectionView.scrollToTop()
    }
    
    private func goToCreateSession(withInitialDate initialDate: Date = Date.now) {
        guard DataCoordinator.shared.isUserSignedIn() else {
            // onboarding, go to create account screen
            let viewController = UIStoryboard(name: AppConstants.Storyboards.onboarding, bundle: nil).instantiateViewController(withIdentifier: RegisterUserViewController.storyboardIdentifier)
            let nav = GGNavigationViewController(rootViewController: viewController)
            NavigationManager.shared.present(nav)
            return
        }
        
        let storyboard = UIStoryboard(name: AppConstants.Storyboards.scheduling, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: ScheduleSessionViewController.storyboardIdentifier) as! ScheduleSessionViewController
        vc.game = game
        vc.tags = tags
        vc.initialDate = initialDate
        NavigationManager.shared.present(vc)
    }

    // MARK: - Interface Actions
    
    @IBAction func createSessionPressed(_ sender: Any? = nil) {
        goToCreateSession()
    }
}
