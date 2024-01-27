//
//  PartiesAIPopupViewController.swift
//  GameGether
//
//  Created by James Ajhar on 3/12/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class PartiesAIPopupViewController: UIViewController, ShowsNavigationOverlay {
    
    // MARK: - Outlets
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var selectOptionLabel: UILabel!
    @IBOutlet weak var unjoinedPartiesTableView: PartyTableView!
    @IBOutlet weak var unjoinedPartiesTableHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var joinedPartyTableView: PartyTableView!
    @IBOutlet weak var unjoinedPartiesContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var joinedPartyContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var joinedPartyContainerBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var startPartyButton: UIButton!
    @IBOutlet weak var startPartyButtonBottomConstraint: NSLayoutConstraint!
    
    // MARK: - Properties
    var onStartPartyPressed: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        styleUI()
        setupView()
        
        // For this tableview, only show parties the logged in user has joined.
        joinedPartyTableView.filter = .joined
        
        // For this tableview, only show parties the logged in user has not joined.
        unjoinedPartiesTableView.filter = .unjoined
        unjoinedPartiesTableView.maxVisibleRows = 4
        
        startPartyButtonBottomConstraint.isActive = false
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
        
        startPartyButton.titleLabel?.font = AppConstants.Fonts.robotoRegular(14).font
        startPartyButton.setTitleColor(UIColor(hexString: "#57A2E1"), for: .normal)
        
        selectOptionLabel.textColor = UIColor(hexString: "#4F4F4F")
        selectOptionLabel.font = AppConstants.Fonts.robotoRegular(15).font
        
        view.addDropShadow(color: .black, opacity: 0.5, radius: 2)
    }
    
    private func setupView() {
        joinedPartyContainerHeightConstraint.constant = 0
        unjoinedPartiesTableHeightConstraint.constant = 0
        view.layoutIfNeeded()
        resize()
    }
    
    public func resize() {
        resizePartyTableViews()
        preferredContentSize = containerView.bounds.size
    }
    
    // MARK: - Interface
    
    func observe(game: Game, withTags tags: [Tag]) {
        unjoinedPartiesTableView.observeGame(game, withTags: tags)
        joinedPartyTableView.observeGame(game, withTags: tags)
    }
    
    @IBAction func startPartyButtonPressed(_ sender: Any) {
        onStartPartyPressed?()
    }
    
    private func resizePartyTableViews() {
        // Resize the parties table
        let unjoinedContentHeight = unjoinedPartiesTableView.contentHeight
        let topContainerHeight = unjoinedContentHeight == 0 ? 0 : unjoinedContentHeight + 55
        let joinedContentHeight: CGFloat = joinedPartyTableView.parties.count > 0 ? 120 : 0

        joinedPartyContainerBottomConstraint.isActive = joinedPartyTableView.parties.count > 0
        startPartyButtonBottomConstraint.isActive = joinedPartyTableView.parties.count == 0

        UIView.animate(withDuration: 0.3) {
            self.unjoinedPartiesTableHeightConstraint.constant = unjoinedContentHeight
            self.joinedPartyContainerHeightConstraint.constant = joinedContentHeight
            self.unjoinedPartiesContainerHeightConstraint.constant = topContainerHeight
            self.view.layoutIfNeeded()
        }
    }
}
