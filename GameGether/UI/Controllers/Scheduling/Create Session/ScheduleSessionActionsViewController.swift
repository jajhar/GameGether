//
//  ScheduleSessionActionsViewController.swift
//  GameGether
//
//  Created by James Ajhar on 9/12/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class ScheduleSessionActionsViewController: UIViewController {
    
    enum CTAButtonState {
        case create
        case join
        case cancel
    }
    
    // MARK: - Outlets
    @IBOutlet weak var darkenedBackgroundView: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var calendarButton: UIButton!

    @IBOutlet weak var tomorrowButton: UIButton! {
        didSet {
            tomorrowButton.titleLabel?.numberOfLines = 2
            tomorrowButton.titleLabel?.font = AppConstants.Fonts.robotoRegular(14).font
            tomorrowButton.titleLabel?.textAlignment = .center
            tomorrowButton.titleLabel?.minimumScaleFactor = 0.7
            tomorrowButton.titleLabel?.adjustsFontSizeToFitWidth = true
            tomorrowButton.titleLabel?.lineBreakMode = .byWordWrapping
            tomorrowButton.setTitleColor(UIColor(hexString: "#ACACAC"), for: .normal)
        }
    }
    
    // MARK: - Properties
    var onCalendarPressed: (() -> Void)?
    var onCTAButtonPressed: ((CTAButtonState) -> Void)?
    var onCTAButtonHeld: ((CTAButtonState) -> Void)?
    var onTomorrowPressed: (() -> Void)?
    
    var ctaButtonState: CTAButtonState = .create {
        didSet {
            switch ctaButtonState {
            case .create:
                playButton.setTitle("create", for: .normal)
                playButton.setBackgroundImage(#imageLiteral(resourceName: "CreateSessionButton"), for: .normal)
            case .join:
                playButton.setTitle("join", for: .normal)
                playButton.setBackgroundImage(#imageLiteral(resourceName: "CreateSessionButton"), for: .normal)
            case .cancel:
                playButton.setTitle("cancel", for: .normal)
                playButton.setBackgroundImage(#imageLiteral(resourceName: "CancelSessionButton"), for: .normal)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(playButtonHeld))
        longPress.minimumPressDuration = 1
        playButton.addGestureRecognizer(longPress)
    }
    
    public func toggleDarkenedBackground(visible: Bool) {
        let newAlpha: CGFloat = visible ? 1 : 0
        UIView.animate(withDuration: 0.3) {
            self.darkenedBackgroundView.alpha = newAlpha
        }
    }
    
    public func updateTomorrowButton(withDate date: Date) {
        var dateString = date.schedulingFormattedString(shorthandWeekday: true)
        dateString = dateString.replacingOccurrences(of: ", ", with: ",\n")
        tomorrowButton.setTitle(dateString, for: .normal)
    }

    // MARK: - Interface Actions
    
    @IBAction func calendarButtonPressed(_ sender: UIButton) {
        onCalendarPressed?()
    }
    
    @IBAction func playButtonPressed(_ sender: UIButton) {
        onCTAButtonPressed?(ctaButtonState)
    }
    
    @objc func playButtonHeld() {
        onCTAButtonHeld?(ctaButtonState)
    }
    
    @IBAction func tomorrowButtonPressed(_ sender: UIButton) {
        onTomorrowPressed?()
    }
}
