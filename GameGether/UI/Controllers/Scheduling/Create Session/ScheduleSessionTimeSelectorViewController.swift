//
//  ScheduleSessionTimeSelectorViewController.swift
//  GameGether
//
//  Created by James Ajhar on 9/12/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class ScheduleSessionTimeSelectorViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var swipeInfoLabel: UILabel!
    @IBOutlet weak var darkenedBackgroundView: UIView!
    @IBOutlet weak var darkenedBackgroundBottomView: UIView!
    
    @IBOutlet weak var joinButton: UIButton! {
        didSet {
            joinButton.titleLabel?.font = AppConstants.Fonts.robotoMedium(14).font
        }
    }
    
    @IBOutlet weak var selectedTimeLabel: UILabel! {
        didSet {
            selectedTimeLabel.font = AppConstants.Fonts.robotoMedium(14).font
            selectedTimeLabel.textColor = .white
        }
    }
    
    @IBOutlet weak var dateSelectorCollectionView: HorizontalTimeSelectorView! {
        didSet {
            dateSelectorCollectionView.onSelectedDateDidChange = { [weak self] (date) in
                guard let weakSelf = self else { return }
                
                weakSelf.selectedDate = date.date
                
                let formatter = DateFormatter()
                formatter.amSymbol = "am"
                formatter.pmSymbol = "pm"
                
                if date.date.minutes > 0 {
                    formatter.dateFormat = "h:mma"
                } else {
                    formatter.dateFormat = "ha"
                }
                
                weakSelf.selectedTimeLabel.backgroundColor = date.isBlockOutDate ? UIColor(hexString: "#CD3333") : UIColor(hexString: "#2AB541")
                weakSelf.selectedTimeLabel.text = formatter.string(from: date.date)
                
                let existingSession = weakSelf.existingSessions.sessions(onDate: date.date).first
                weakSelf.onSelectedDateDidChange?(date.date, existingSession)
                weakSelf.attendingUsersView.users = existingSession?.attendees ?? []
                weakSelf.swipeInfoLabel.isHidden = weakSelf.dateSelectorCollectionView.userDidScroll
                weakSelf.joinButton.isHidden = existingSession == nil || existingSession?.isJoined == true
            }
        }
    }
    
    @IBOutlet weak var attendingUsersView: HorizontalAvatarsView! {
        didSet {
            attendingUsersView.maxVisibleUsers = 6
        }
    }
    
    // MARK: - Properties
    
    private var viewDidAppear = false
    
    private(set) var selectedDate: Date = Date.now
    
    var existingSessions = [GameSession]() {
        didSet {
            dateSelectorCollectionView.blockoutDates = blockoutDates
        }
    }

    var blockoutDates: [Date] {
        return existingSessions.compactMap({
            guard $0.isJoined else { return nil }
            return $0.begins
        })
    }
    
    var onSelectedDateDidChange: ((Date, GameSession?) -> Void)?
    var onJoinSessionPressed: ((GameSession) -> Void)?
  
    var initialDate: Date = Date.now
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !viewDidAppear {
            dateSelectorCollectionView.initialDate = initialDate
            viewDidAppear = true
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        dateSelectorCollectionView.collectionViewLayout.invalidateLayout()
    }
    
    public func selectDate(_ date: Date, animated: Bool = true) {
        dateSelectorCollectionView.selectDate(nearestTo: date, animated: animated)
    }
    
    public func toggleDarkenedBackground(visible: Bool) {
        let newAlpha: CGFloat = visible ? 1 : 0
        UIView.animate(withDuration: 0.3) {
            self.darkenedBackgroundView.alpha = newAlpha
            self.darkenedBackgroundBottomView.alpha = newAlpha
        }
    }
    
    // MARK: - Interface Actions
    
    @IBAction func joinPlayersPressed(_ sender: Any) {
        guard let session = existingSessions.sessions(onDate: selectedDate).first else { return }
        onJoinSessionPressed?(session)
    }
}
