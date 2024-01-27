//
//  LobbiesCollectionView.swift
//  GameGether
//
//  Created by James Ajhar on 9/8/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

class LobbiesCollectionView: UICollectionView {

    struct Constants {
        static let sectionInsets = UIEdgeInsets(top: 12, left: 9, bottom: 14, right: 9)
        static let bottomSectionInsets = UIEdgeInsets(top: 12, left: 9, bottom: 100, right: 9)
    }
    
    // MARK: Properties
    
    var game: Game? {
        didSet {
            reloadDataSource()
        }
    }
    
    var onTagsSelected: (([Tag]) -> Void)?
    var onEmptyStateCellSelected: (() -> Void)?

    private var bookmarkedTags = [Tag]()
    private(set) var followedTags = [TagsGroup]() {
        didSet {
            performOnMainThread { self.reloadData() }
        }
    }
    private(set) var activeTags = [TagsGroup]() {
        didSet {
            performOnMainThread { self.reloadData() }
        }
    }

    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    internal func commonInit() {
        dataSource = self
        delegate = self
        
        register(UINib(nibName: LobbyCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: LobbyCollectionViewCell.reuseIdentifier)
        register(UINib(nibName: LobbyEmptyStateCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: LobbyEmptyStateCollectionViewCell.reuseIdentifier)
        register(UINib(nibName: GameTagsCollectionReusableView.nibName, bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "\(GameTagsCollectionReusableView.self)")
        register(GameTagReusableSectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "\(GameTagReusableSectionHeaderView.self)")
    }
    
    func reloadDataSource() {
        guard let game = game else { return }

        DataCoordinator.shared.getActiveTags(forGame: game.identifier) { [weak self] (activeTags, error) in
            guard error == nil, let activeTags = activeTags, let strongself = self else {
                GGLog.error("Error: \(String(describing: error))")
                return
            }
            
            performOnMainThread {
                strongself.activeTags = activeTags
            }
        }
        
        DataCoordinator.shared.getFollowedTags { [weak self] (followedTags, error) in
            guard error == nil, let followedTags = followedTags, let strongself = self else {
                GGLog.error("Error: \(String(describing: error))")
                return
            }
            
            let filteredTags = followedTags.filter({ $0.gameId == game.identifier })
            
            DataCoordinator.shared.getBookmarkedTags(forGame: game.identifier, completion: { (bookmarkedTags, error) in
                
                performOnMainThread {
                    strongself.bookmarkedTags = bookmarkedTags ?? []
                    strongself.followedTags = filteredTags
                }
            })
        }
    }
}

extension LobbiesCollectionView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return followedTags.count > 0 ? 1 : 2 // display both the general lobby and the empty state cell if the user isn't following any tags
        case 1:
            return followedTags.count
        case 2:
            return activeTags.count
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if indexPath.section == 0  {
            let view = dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "\(GameTagsCollectionReusableView.self)", for: indexPath) as! GameTagsCollectionReusableView
            view.game = game
            return view
        }
        
        let view = dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "\(GameTagReusableSectionHeaderView.self)", for: indexPath) as! GameTagReusableSectionHeaderView
        
        switch indexPath.section {
        case 1:
            view.titleLabel.text = followedTags.count > 0 ? "Starred Lobbies" : nil
        case 2:
            view.titleLabel.text = activeTags.count > 0 ? "Online Now" : nil
        default:
            break
        }
        
        return view
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.section == 0 {
            
            if indexPath.item == 0 {
                // General Lobby
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LobbyCollectionViewCell.reuseIdentifier, for: indexPath) as! LobbyCollectionViewCell
                let generalLobbyTagGroup = TagsGroupObject(identifier: "general_lobby", gameId: game?.identifier ?? "")
                cell.tagGroup = generalLobbyTagGroup
                cell.tagLabel.text = "General Lobby"
                
                if let game = game, UserDefaults.standard.value(forKey: AppConstants.UserDefaults.generalLobbyTagBookmark(for: game)) as? Bool == true {
                    // if the general lobby is bookmarked, select it.
                    cell.setSelected(true)
                }
                
                return cell
                
            } else {
                // Empty state cell
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LobbyEmptyStateCollectionViewCell.reuseIdentifier, for: indexPath) as! LobbyEmptyStateCollectionViewCell
                return cell
            }

        } else if indexPath.section == 1 {
            // Starred Lobbies
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LobbyCollectionViewCell.reuseIdentifier, for: indexPath) as! LobbyCollectionViewCell
            let tagGroup = followedTags[indexPath.item]
            
            cell.tagGroup = tagGroup
            
            if tagGroup.tags.isEqual(to: bookmarkedTags) {
                // if this tag is currently bookmarked, select it.
                cell.setSelected(true)
            }
            
            return cell
            
        } else if indexPath.section == 2 {
            // Online Now
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LobbyCollectionViewCell.reuseIdentifier, for: indexPath) as! LobbyCollectionViewCell
            let tagGroup = activeTags[indexPath.item]
            
            cell.tagGroup = tagGroup
            
            if tagGroup.tags.isEqual(to: bookmarkedTags) {
                // if this tag is currently bookmarked, select it.
                cell.setSelected(true)
            }
            
            
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        if section == 0 {
            return CGSize(width: bounds.width, height: 260)
        } else {
            return CGSize(width: bounds.width, height: 18)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        if section == numberOfSections(in: collectionView) - 1 {
            // Last section gets more bottom space
            return Constants.bottomSectionInsets
        }
        
        return Constants.sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            
            if indexPath.item == 0 {
                // General lobby selected (no tags)
                onTagsSelected?([])
            } else {
                onEmptyStateCellSelected?()
            }
            
        } else if indexPath.section == 1 {
            // Selected a followed tag
            let selectedTags = followedTags[indexPath.item]
            onTagsSelected?(selectedTags.tags)

        } else if indexPath.section == 2 {
            // Selected an active tag
            let selectedTags = activeTags[indexPath.item]
            onTagsSelected?(selectedTags.tags)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: bounds.width - Constants.sectionInsets.left - Constants.sectionInsets.right, height: 46)
    }
}
