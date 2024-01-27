//
//  ProfileGamesCollectionView.swift
//  GameGether
//
//  Created by James Ajhar on 5/30/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class ProfileGamesCollectionView: KeyboardCollectionView {

    // MARK: Properties
    
    private(set) var games = [Game]()
    
    private var gamesInCommon = [Game]()
    private var gamesNotInCommon = [Game]()
    private var followedTags = [TagsGroup]()

    var user: User?
    
    var onEditGamePressed: ((Game) -> Void)? {
        didSet { reloadData() }
    }
    
    var onGameIconPressed: ((Game) -> Void)? {
        didSet { reloadData() }
    }
    
    var onTagGroupSelected: ((Game, TagsGroup) -> Void)? {
        didSet { reloadData() }
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
        
        let layout = collectionViewLayout as? UICollectionViewFlowLayout
        layout?.estimatedItemSize = CGSize(width: bounds.width, height: 80)
        layout?.headerReferenceSize = CGSize(width: bounds.width, height: 80)
        
        register(AddGameCollectionViewCell.self, forCellWithReuseIdentifier: AddGameCollectionViewCell.reuseIdentifier)
        register(ProfileGamesCollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "\(ProfileGamesCollectionReusableView.self)")
        register(UINib(nibName: "\(ProfileGameCollectionViewCell.self)", bundle: nil), forCellWithReuseIdentifier: ProfileGameCollectionViewCell.reuseIdentifier)
    }
    
    private func superDuperReload() {
        collectionViewLayout.prepare()
        collectionViewLayout.invalidateLayout()
        performBatchUpdates({
            // NOP - Resize EVERYTHING
        }, completion: { (_) in
            self.setNeedsLayout()
            self.layoutIfNeeded()
        })
    }
    
    func reloadDataSource() {
        guard let user = user else { return }
        
        // Fetch games for the signed in user
        DataCoordinator.shared.getFavoriteGames { [weak self] (games, error) in
            guard error == nil, let weakSelf = self else {
                GGLog.error("Error: \(String(describing: error))")
                return
            }
            
            DataCoordinator.shared.getFollowedTags { [weak self] (followedTags, error) in
                if let tags = followedTags {
                    self?.followedTags = tags
                }

                performOnMainThread {
                    
                    if user.isSignedInUser {
                        weakSelf.games = games
                        weakSelf.gamesInCommon = games
                    } else {
                        // Only show games in common
                        weakSelf.games = games
                        weakSelf.gamesInCommon.removeAll()
                        weakSelf.gamesNotInCommon.removeAll()

                        for game in user.games {
                            if games.contains(where: { game.identifier == $0.identifier }) {
                                // found a game in common
                                weakSelf.gamesInCommon.append(game)
                            } else {
                                weakSelf.gamesNotInCommon.append(game)
                            }
                        }
                    }
                    
                    weakSelf.reloadData()
                    
                    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { (_) in
                        weakSelf.superDuperReload()
                    })
                }
            }
        }
    }
}

extension ProfileGamesCollectionView: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return gamesNotInCommon.count > 0 ? 2 : 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            // games in common
            let count = gamesInCommon.count
            
//            if user?.isSignedInUser == true {
//                count += 1 // +1 for add game cell
//            }
            
            return count
            
        case 1:
            // games not in common
            return gamesNotInCommon.count
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "\(ProfileGamesCollectionReusableView.self)", for: indexPath) as! ProfileGamesCollectionReusableView

        switch indexPath.section {
        case 0:
            view.titleLabel.text = user?.isSignedInUser == true ? "Your Games" : "Games & Gamertag"
        case 1:
            view.titleLabel.text = "\(user?.ign ?? "") also plays"
        default:
            break
        }
        
        return view
    }
    
    private func game(forIndex indexPath: IndexPath) -> Game? {
        switch indexPath.section {
        case 0:
            guard indexPath.item < gamesInCommon.count else { return nil }
            return gamesInCommon[indexPath.item]
        case 1:
            guard indexPath.item < gamesNotInCommon.count else { return nil }
            return gamesNotInCommon[indexPath.item]
        default:
            return nil
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if user?.isSignedInUser == true, indexPath.item >= gamesInCommon.count {
            // Add game cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddGameCollectionViewCell.reuseIdentifier, for: indexPath) as! AddGameCollectionViewCell
            return cell
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfileGameCollectionViewCell.reuseIdentifier, for: indexPath) as! ProfileGameCollectionViewCell
        
        if let user = user, let game = game(forIndex: indexPath) {
            cell.configure(withGame: game, andUser: user, tagsToCompare: followedTags)
        }
        
        cell.onGameIconPressed = onGameIconPressed
        cell.onEditPressed = onEditGamePressed
        cell.onTagGroupSelected = onTagGroupSelected

        return cell
    }
    
}
