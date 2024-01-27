//
//  UserProfilePopUpViewController.swift
//  GameGether
//
//  Created by James Ajhar on 3/25/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class UserProfilePopUpViewController: UIViewController, ShowsNavigationOverlay {
    
    // MARK: - Outlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var addFriendButton: UIButton!
    @IBOutlet weak var containerView: UIView!
    
    // MARK: - Properties
    
    public var onSendMessagePressed: ((UIButton) -> Void)?
    public var onAddFriendPressed: ((UIButton) -> Void)?
    public var user: User?
    
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
        
        messageButton.titleLabel?.font = AppConstants.Fonts.robotoRegular(14).font
        messageButton.setTitleColor(UIColor(hexString: "#57A2E1"), for: .normal)
        
        addFriendButton.titleLabel?.font = AppConstants.Fonts.robotoRegular(14).font
        addFriendButton.setTitleColor(UIColor(hexString: "#57A2E1"), for: .normal)
        
        containerView.addDropShadow(color: .black, opacity: 0.5, radius: 2)
    }
    
    private func setupView() {
        view.layoutIfNeeded()
        
        if let user = user {
            updateFriendStatus(status: user.relationship?.status ?? .none)
        }
        resize()
    }
    
    private func resize() {
        preferredContentSize = containerView.bounds.size
    }
    
    func updateFriendStatus(status: FriendStatus) {
        switch status {
        case .none:
            addFriendButton.setTitle("send a friend request", for: .normal)
        case .pending:
            addFriendButton.setTitle("cancel friend request", for: .normal)
        case .accepted:
            addFriendButton.setTitle("unfriend", for: .normal)
        case .blocked:
            break
        }
    }
    
    // MARK: - Interface Actions
    
    @IBAction func sendMessageButtonPressed(_ sender: UIButton) {
        onSendMessagePressed?(sender)
    }
    
    @IBAction func addFriendButtonPressed(_ sender: UIButton) {
        onAddFriendPressed?(sender)
    }
}
