//
//  LobbyWalkthroughViewController.swift
//  GameGether
//
//  Created by James Ajhar on 3/2/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class LobbyWalkthroughViewController: UIViewController {

    struct Constants {
        static let titleLabelBottomConstraintDefault: CGFloat = 12
        static let selectedTagsCollectionHeight: CGFloat = 35
        static let startPartyContainerHeight: CGFloat = 64
    }
    
    // MARK: - Outlets
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.textColor = UIColor(hexString: "#4F4F4F")
            titleLabel.font = AppConstants.Fonts.robotoRegular(15).font
        }
    }
    
    @IBOutlet weak var subtitleLabel: UILabel! {
        didSet {
            subtitleLabel.textColor = UIColor(hexString: "#4F4F4F")
            subtitleLabel.font = AppConstants.Fonts.robotoRegular(15).font
        }
    }
    
    @IBOutlet weak var selectedTagsCollectionView: TagsHeaderCollectionView! {
        didSet {
            selectedTagsCollectionView.leftInset = 15
            selectedTagsCollectionView.rightInset = 15
        }
    }
    
    @IBOutlet weak var unselectedTagsCollectionView: TagsHeaderCollectionView! {
        didSet {
            unselectedTagsCollectionView.leftInset = 15
            unselectedTagsCollectionView.rightInset = 15
        }
    }
    
    @IBOutlet weak var titleLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var selectedTagsCollectionHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var findLobbyButton: UIButton! {
        didSet {
            findLobbyButton.titleLabel?.font = AppConstants.Fonts.robotoBold(14).font
            findLobbyButton.setTitleColor(.white, for: .normal)
            findLobbyButton.addDropShadow(color: .black, opacity: 0.3, offset: CGSize(width: 1, height: 1), radius: 2)
        }
    }
    
    @IBOutlet weak var backgroundView: UIView! {
        didSet {
            // Dismiss when background is tapped
            let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped(sender:)))
            tap.cancelsTouchesInView = false
            backgroundView.addGestureRecognizer(tap)
        }
    }
    
    // MARK: - Properties
    var game: Game?
    var onFindLobbyPressed: (([Tag]) -> Void)?
    var onBackgroundTapped: (() -> Void)?
    var onCloseButtonPressed: (() -> Void)?

    private(set) var selectedTags = [Tag]()

    private var isSizeTagSelected: Bool {
        return selectedTags.sizeTags().count > 0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    private func setupView() {
        // Selected tags collection
        selectedTagsCollectionView.tagsHeaderDelegate = self
        selectedTagsCollectionView.select(tags: selectedTags)
        
        // Unselected tags collection
        unselectedTagsCollectionView.tagsHeaderDelegate = self
        unselectedTagsCollectionView.showSelectedTags = false
        unselectedTagsCollectionView.game = game
        unselectedTagsCollectionView.select(tags: selectedTags)

        updateView()
        
        view.layoutIfNeeded()
    }
    
    private func updateView() {
        titleLabel.text = selectedTags.count > 0 ? "you selected a lobby for" : "let's find you a lobby"
        
        toggleSelectedTagsView(visible: selectedTags.count > 0)
        
        if !selectedTags.isGameModeTagSelected {
            subtitleLabel.text = "select game mode"
            unselectedTagsCollectionView.filter = .gameMode
        }
//        else if !isSizeTagSelected {
//            subtitleLabel.text = "select team size"
//            unselectedTagsCollectionView.filter = .teamSize
//            
//        }
        else {
            subtitleLabel.text = "select preference (optional)"
            unselectedTagsCollectionView.filter = nil
        }
        
        unselectedTagsCollectionView.layoutDirection = .rightToLeft

        toggleFindLobbyButton(visible: selectedTags.count > 0 && (selectedTags.isGameModeTagSelected))
    }
    
    // MARK: - Interface Actions
    
    @IBAction func findLobbyButtonPressed(_ sender: UIButton) {
        AnalyticsManager.track(event: .lobbyWalkthroughGoToLobbyPressed)
        onFindLobbyPressed?(selectedTags)
    }
    
    @objc func backgroundTapped(sender: UITapGestureRecognizer) {
        onBackgroundTapped?()
    }
    
    @IBAction func closeButtonPressed(_ sender: Any) {
        onCloseButtonPressed?()
    }
    
    // MARK: - Internal
    
    private func toggleSelectedTagsView(visible: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.selectedTagsCollectionHeightConstraint.constant = visible ? Constants.selectedTagsCollectionHeight : 0
            self.titleLabelBottomConstraint.constant = visible ? Constants.titleLabelBottomConstraintDefault : 0
            self.view.layoutIfNeeded()
        }
    }
    
    private func toggleFindLobbyButton(visible: Bool) {
        findLobbyButton.isHidden = !visible
    }
}

extension LobbyWalkthroughViewController: TagsHeaderCollectionViewDelegate {
   
    func tagsHeaderCollectionView(collectionView: TagsHeaderCollectionView, canSelectTag tag: Tag, atIndexPath indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tagsHeaderCollectionView(collectionView: TagsHeaderCollectionView, selectedTagsDidChange selectedTags: [Tag]) {
        if collectionView == unselectedTagsCollectionView {
            var sortedTags = selectedTags
            sortedTags.sortByPriority()
            selectedTagsCollectionView.select(tags: sortedTags)
            
        } else if collectionView == selectedTagsCollectionView {
            unselectedTagsCollectionView.select(tags: selectedTags)
            self.selectedTags = selectedTags
        }
        
        updateView()
    }
}
