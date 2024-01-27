//
//  SessionTypeSelectorViewController.swift
//  GameGether
//
//  Created by James Ajhar on 10/1/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class SessionTypeSelectorViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var tableView: SessionTypesTableView!
    
    // MARK: - Properties
    var game: Game? {
        didSet {
            guard isViewLoaded else { return }
            tableView.game = game
        }
    }
    
    private(set) var selectedType: GameSessionType? {
        didSet {
            if let type = selectedType {
                onTypeSelected?(type)
            }
        }
    }
    
    var onTypeSelected: ((GameSessionType) -> Void)? {
        didSet {
            guard isViewLoaded else { return }
            
            tableView.onTypeSelected = { [weak self] (type) in
                self?.selectedType = type
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.game = game
        
        tableView.onTypeSelected = { [weak self] (type) in
            self?.selectedType = type
        }
    }
    
    public func selectType(withAssociatedTag tag: Tag) {
        tableView.associatedTagToSelect = tag
    }
    
    public func selectType(_ type: GameSessionTypeIdentifier) {
        tableView.typeToSelect = type
    }
}
