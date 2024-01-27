//
//  ScheduleSessionInfoViewController.swift
//  GameGether
//
//  Created by James Ajhar on 9/12/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class ScheduleSessionInfoViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var dateLabel: UILabel! {
        didSet {
            dateLabel.text = date.schedulingFormattedString(includeTime: true)
        }
    }
    
    @IBOutlet weak var descriptionStackView: UIStackView!
    @IBOutlet weak var descriptionLogo: UIImageView!
    
    @IBOutlet weak var descriptionLabel: UILabel! {
        didSet {
            descriptionLabel.font = AppConstants.Fonts.robotoRegular(14).font
            descriptionLabel.numberOfLines = 2
        }
    }
    
    // MARK: - Properties
    
    var date: Date = Date() {
        didSet {
            dateLabel.text = date.schedulingFormattedString(includeTime: true)
        }
    }
    
    var descriptionText: String? {
        didSet {
            configureForSessionType()
        }
    }
    
    var sessionType: GameSessionType? {
        didSet {
            configureForSessionType()
        }
    }
    
    var onRequestTextTapped: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    private func configureForSessionType() {
        guard let type = sessionType?.type else { return }
        
        descriptionLogo.isHidden = type == .request
        
        switch type {
        case .gameMode:
            descriptionLabel.text = "\(sessionType?.title ?? "") Open Session"
        case .request:
            
            if let text = descriptionText {
                descriptionLabel.text = text
            } else {
                let string = NSMutableAttributedString(string: "+ type in your request (see examples)")
                string.addColor(color: UIColor(hexString: "#BDBDBD"), toText: "+ type in your request")
                string.addColor(color: UIColor(hexString: "#3399FF"), toText: "(see examples)")
                descriptionLabel.attributedText = string
            }
        }
        
        view.layoutIfNeeded()
    }
    
    // MARK: - Interface Actions

    @IBAction func requestButtonPressed(_ sender: Any) {
        guard sessionType?.type == .request else { return }
        onRequestTextTapped?()
    }
}
