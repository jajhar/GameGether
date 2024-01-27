//
//  ScheduleSessionGameTagsModalViewController.swift
//  GameGether
//
//  Created by James Ajhar on 9/13/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class ScheduleSessionGameTagsModalViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var backgroundView: UIView!
    
    // MARK: - Properties
    private(set) var gameSelectorVC: ScheduleGameSelectorViewController?
    private(set) var tagsSelectorVC: ScheduleTagsSelectorViewController?
    
    var selectedGame: Game?
    var selectedTags = [Tag]()
    var onGameSelected: ((Game, [Tag]) -> Void)?
    var onCancelPressed: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

//        let backgroundTap = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
//        backgroundView.addGestureRecognizer(backgroundTap)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let vc = segue.destination as? ScheduleGameSelectorViewController {
            vc.selectedGame = selectedGame
            
            vc.onGameSelected = { [weak self] (selectedGame) in
                guard selectedGame.identifier != self?.selectedGame?.identifier else { return }
                
                self?.tagsSelectorVC?.game = selectedGame
                self?.tagsSelectorVC?.selectedTags = []
                self?.selectedTags = []
                self?.selectedGame = selectedGame
            }
            
            gameSelectorVC = vc
            
        } else if let vc = segue.destination as? ScheduleTagsSelectorViewController {
            vc.game = selectedGame
            vc.selectedTags = selectedTags
            tagsSelectorVC = vc
            
            vc.onNextButtonPressed = { [weak self] (game, tags) in
                self?.onGameSelected?(game, tags)
            }
            
            vc.onCancelButtonPressed = { [weak self] in
                self?.onCancelPressed?()
            }
        }
    }
    
    // MARK: - Interface Actions
    
//    @objc func backgroundTapped() {
//        dismissSelf()
//    }
}
