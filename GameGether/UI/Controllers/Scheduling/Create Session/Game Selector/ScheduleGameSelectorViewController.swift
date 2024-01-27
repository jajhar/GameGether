//
//  ScheduleGameSelectorViewController.swift
//  GameGether
//
//  Created by James Ajhar on 9/13/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class ScheduleGameSelectorViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var gamesCollectionView: GameNavCollectionView! {
        didSet {
            gamesCollectionView.layoutDirection = .horizontal
            gamesCollectionView.showAddNewGameIcon = false
            gamesCollectionView.insets = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
            gamesCollectionView.showSelector = true
            
            gamesCollectionView.onGameSelected = { [weak self] (game) in
                self?.selectedGame = game
            }
        }
    }
    
    // MARK: - Properties
    var onGameSelected: ((Game) -> Void)?

    var selectedGame: Game? {
        didSet {
            guard isViewLoaded else { return }
            gamesCollectionView.selectedGame = selectedGame
            
            if let game = selectedGame {
                onGameSelected?(game)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        gamesCollectionView.selectedGame = selectedGame
    }
}
