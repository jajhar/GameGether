//
//  SessionPartySizeSelectorViewController.swift
//  GameGether
//
//  Created by James Ajhar on 10/3/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class SessionPartySizeSelectorViewController: UIViewController {

    // MARK: - Outlets
    
    @IBOutlet weak var tableView: SessionPartySizesTableView!
    
    // MARK: - Properties
    
    var game: Game?
    
    var onSizeSelected: ((Tag) -> Void)? {
        didSet {
            guard isViewLoaded else { return }
            tableView.onSizeSelected = onSizeSelected
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.onSizeSelected = onSizeSelected
        tableView.game = game
    }
    

}

