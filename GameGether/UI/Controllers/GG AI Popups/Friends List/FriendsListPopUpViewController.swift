//
//  FriendsListPopUpViewController.swift
//  GameGether
//
//  Created by James Ajhar on 3/20/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class FriendsListPopUpViewController: UIViewController, ShowsNavigationOverlay {

    // MARK: - Outlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var newMessageButton: UIButton!
    @IBOutlet weak var addFriendButton: UIButton!
    @IBOutlet weak var containerView: UIView!

    // MARK: - Properties
    
    public var onNewMessageButtonPressed: ((UIButton) -> Void)?
    public var onAddFriendButtonPressed: ((UIButton) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        styleUI()
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.layoutIfNeeded()
        resize()
    }
    
    private func styleUI() {
        titleLabel.textColor = UIColor(hexString: "#4F4F4F")
        titleLabel.font = AppConstants.Fonts.robotoRegular(15).font
        
        newMessageButton.titleLabel?.font = AppConstants.Fonts.robotoRegular(14).font
        newMessageButton.setTitleColor(UIColor(hexString: "#57A2E1"), for: .normal)
        
        addFriendButton.titleLabel?.font = AppConstants.Fonts.robotoRegular(14).font
        addFriendButton.setTitleColor(UIColor(hexString: "#57A2E1"), for: .normal)

        view.addDropShadow(color: .black, opacity: 0.5, radius: 2)
    }
    
    private func setupView() {
        view.layoutIfNeeded()
        resize()
    }
    
    private func resize() {
        preferredContentSize = containerView.bounds.size
    }
    
    // MARK: - Interface Actions
    
    @IBAction func newMessageButtonPressed(_ sender: UIButton) {
        onNewMessageButtonPressed?(sender)
    }
    
    @IBAction func addFriendButtonPressed(_ sender: UIButton) {
        onAddFriendButtonPressed?(sender)
    }
}
