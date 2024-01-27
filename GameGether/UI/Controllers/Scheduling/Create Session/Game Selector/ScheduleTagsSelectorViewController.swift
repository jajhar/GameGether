//
//  ScheduleTagsSelectorViewController.swift
//  GameGether
//
//  Created by James Ajhar on 9/13/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class ScheduleTagsSelectorViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var tagsCollectionView: TagsHeaderCollectionView! {
        didSet {
            tagsCollectionView.tagsHeaderDelegate = self
        }
    }
    
    @IBOutlet weak var selectGameLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    
    // MARK: - Properties
    var game: Game? {
        didSet {
            guard isViewLoaded else { return }
            setupWithGame()
        }
    }
    
    var selectedTags = [Tag]() {
        didSet {
            guard isViewLoaded else { return }
            setupWithGame()
        }
    }
    
    var onNextButtonPressed: ((Game, [Tag]) -> Void)?
    var onCancelButtonPressed: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupWithGame()
    }
    
    private func setupWithGame() {
        tagsCollectionView.game = game
        
        tagsCollectionView.reloadDataSource { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.tagsCollectionView.select(tags: weakSelf.selectedTags)
        }
        
        selectGameLabel.isHidden = game != nil
        nextButton.isEnabled = game != nil && !selectedTags.isEmpty
        
        if !selectedTags.isGameModeTagSelected {
            tagsCollectionView.filter = .gameMode
        } else {
            tagsCollectionView.filter = nil
        }
    }
    
    // MARK: - Interface Actions
    
    @IBAction func nextButtonPressed(_ sender: UIButton) {
        guard let game = game, !tagsCollectionView.selectedTags.isEmpty else { return }
        onNextButtonPressed?(game, tagsCollectionView.selectedTags)
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        onCancelButtonPressed?()
    }
}

extension ScheduleTagsSelectorViewController: TagsHeaderCollectionViewDelegate {
    
    func tagsHeaderCollectionView(collectionView: TagsHeaderCollectionView, selectedTagsDidChange selectedTags: [Tag]) {
        
        if !selectedTags.isEmpty, !selectedTags.isGameModeTagSelected {
            // Force the user to select a game mode
            collectionView.select(tags: [])
            return
        }

        self.selectedTags = selectedTags
        collectionView.filter = selectedTags.isGameModeTagSelected ? nil : .gameMode
    }
}
