//
//  PartyInfoAIPopUpViewController.swift
//  GameGether
//
//  Created by James Ajhar on 3/4/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class PartyInfoAIPopUpViewController: UIViewController, ShowsNavigationOverlay {

    // MARK: - Outlets
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var partyTableView: PartyTableView!
    @IBOutlet weak var seeOpenPartiesButton: UIButton!
    
    // MARK: - Properties
    var onViewPartiesPressed: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        styleUI()
        setupView()
        
        // Only show parties that the logged in user belongs to
        partyTableView.filter = .joined
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.layoutIfNeeded()
        resize()
    }
    
    private func styleUI() {
        titleLabel.textColor = UIColor(hexString: "#4F4F4F")
        titleLabel.font = AppConstants.Fonts.robotoRegular(15).font
        
        subtitleLabel.textColor = UIColor(hexString: "#4F4F4F")
        subtitleLabel.font = AppConstants.Fonts.robotoRegular(15).font
        
        seeOpenPartiesButton.titleLabel?.font = AppConstants.Fonts.robotoRegular(14).font
        seeOpenPartiesButton.setTitleColor(UIColor(hexString: "#57A2E1"), for: .normal)
        
        view.addDropShadow(color: .black, opacity: 0.5, radius: 2)
    }
    
    private func setupView() {
        view.layoutIfNeeded()
        resize()
    }
    
    private func resize() {
        preferredContentSize = containerView.bounds.size
    }
    
    // MARK: - Interface
    
    func observe(game: Game, withTags tags: [Tag]) {
        partyTableView.observeGame(game, withTags: tags)
    }
    
    @IBAction func viewPartiesButtonPressed(_ sender: UIButton) {
        AnalyticsManager.track(event: .seeOtherPartiesTapped)
        onViewPartiesPressed?()
    }
}
