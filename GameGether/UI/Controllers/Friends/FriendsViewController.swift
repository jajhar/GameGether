//
//  FriendsViewController.swift
//  GameGether
//
//  Created by James Ajhar on 8/6/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

class FriendsViewController: UIViewController {

    // MARK: Outlets
    @IBOutlet weak var friendsTableView: FriendsTableView!
    @IBOutlet weak var emptyStateView: UIView!
    
    @IBOutlet weak var inviteFriendsButton: UIButton! {
        didSet {
            inviteFriendsButton.addDropShadow(color: .black, opacity: 0.11, offset: CGSize(width: 1, height: 2), radius: 2.0)
        }
    }
    
    // MARK: Properties
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
 
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        friendsTableView.reloadDataSource { [weak self] (users, _) in
            self?.emptyStateView.isHidden = users.count > 0
        }
    }
    
    // MARK: - Interface Actions
    
    @IBAction func inviteFriendsButtonTapped(_ sender: Any) {
        AnalyticsManager.track(event: .addFriendPressed, withParameters: nil)
        let storyboard = UIStoryboard(name: AppConstants.Storyboards.friends, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: AddFriendsViewController.storyboardIdentifier)
        NavigationManager.shared.present(vc)
    }
}
