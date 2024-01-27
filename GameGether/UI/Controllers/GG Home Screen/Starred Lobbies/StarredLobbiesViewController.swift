//
//  StarredLobbiesViewController.swift
//  GameGether
//
//  Created by James Ajhar on 7/10/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit
import FLAnimatedImage

class StarredLobbiesViewController: UIViewController, ShowsNavigationOverlay {

    struct Constants {
        static let sectionInsets = UIEdgeInsets(top: 12, left: 9, bottom: 17, right: 9)
        static let contentInsets = UIEdgeInsets(top: 17, left: 0, bottom: 100, right: 0)
    }
    
    @IBOutlet weak var emptyStateView: UIView!
    @IBOutlet weak var animatedEmptyStateImageView: FLAnimatedImageView! {
        didSet {
            if let path = Bundle.main.url(forResource: "Starring-a-Tag", withExtension: "gif"), let data = try? Data(contentsOf: path) {
                animatedEmptyStateImageView.animatedImage = FLAnimatedImage(animatedGIFData: data)
            }
        }
    }

    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.contentInset = Constants.contentInsets
            
            collectionView.register(UINib(nibName: LobbyCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: LobbyCollectionViewCell.reuseIdentifier)
            collectionView.register(UINib(nibName: LobbyEmptyStateCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: LobbyEmptyStateCollectionViewCell.reuseIdentifier)
            collectionView.register(GameTagReusableSectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "\(GameTagReusableSectionHeaderView.self)")
        }
    }
    
    // MARK: - Properties
    private(set) var favoritedLobbies = [String: [TagsGroup]]()
    private(set) var favoriteGames = [Game]()
    
    var onTagsSelected: ((Game, [Tag]) -> Void)?
    
    var joystickImage: NavigationJoystickViewImage {
        return .custom(#imageLiteral(resourceName: "GG_AI_Selected"))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        reloadDataSource()
    }

    func reloadDataSource() {
        
        DataCoordinator.shared.getFavoriteGames { [weak self] (favoriteGames, error) in
            guard let weakSelf = self else { return }
            
            guard error == nil else {
                GGLog.error("Error: \(String(describing: error))")
                return
            }
            
            weakSelf.favoriteGames = favoriteGames
            
            DataCoordinator.shared.getFollowedTags {  (followedTags, error) in
                
                guard error == nil, let followedTags = followedTags else {
                    GGLog.error("Error: \(String(describing: error))")
                    return
                }
                
                performOnMainThread {
                    for tagGroup in followedTags {
                        guard favoriteGames.contains(where: { $0.identifier == tagGroup.gameId }) else { continue }
                        
                        if weakSelf.favoritedLobbies[tagGroup.gameId] == nil {
                            weakSelf.favoritedLobbies[tagGroup.gameId] = []
                        }
                        weakSelf.favoritedLobbies[tagGroup.gameId]?.append(tagGroup)
                    }
                    
                    self?.emptyStateView.isHidden = !weakSelf.favoritedLobbies.keys.isEmpty
                    
                    weakSelf.collectionView.reloadData()
                }
            }
        }
    }
    
    // MARK: - Interface Actions
    
    @IBAction func addFriendButtonpressed(_ sender: Any) {
        AnalyticsManager.track(event: .addFriendPressed, withParameters: nil)
        
        let storyboard = UIStoryboard(name: AppConstants.Storyboards.friends, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: AddFriendsViewController.storyboardIdentifier)
        NavigationManager.shared.present(vc)
    }
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        dismissSelf()
    }
}

extension StarredLobbiesViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return favoritedLobbies.keys.count > 0 ? favoritedLobbies.keys.count : 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let keys = Array(favoritedLobbies.keys).sorted() // sort so the order is always the same
        guard section < keys.count else {
            return 1 // 1 for empty state
        }
        
        return favoritedLobbies[keys[section]]?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        let keys = Array(favoritedLobbies.keys).sorted() // sort so the order is always the same
        guard indexPath.section < keys.count else {
            return UICollectionReusableView(frame: .zero)
        }

        let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "\(GameTagReusableSectionHeaderView.self)", for: indexPath) as! GameTagReusableSectionHeaderView
        
        let key = keys[indexPath.section]
        let game = favoriteGames.filter({ $0.identifier == key }).first

        view.titleLabel.text = game?.title ?? ""
        view.titleLabel.textColor = UIColor(hexString: game?.headerColor ?? "")

        return view
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let keys = Array(favoritedLobbies.keys).sorted() // sort so the order is always the same
        guard indexPath.section < keys.count else {
            // Empty state cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LobbyEmptyStateCollectionViewCell.reuseIdentifier, for: indexPath) as! LobbyEmptyStateCollectionViewCell
            cell.titleLabel.text = "your starred tags will appear here"
            return cell
        }

         // Starred Lobbies
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LobbyCollectionViewCell.reuseIdentifier, for: indexPath) as! LobbyCollectionViewCell
        let key = keys[indexPath.section]
        
        cell.tagGroup = favoritedLobbies[key]?[indexPath.item]

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let keys = Array(favoritedLobbies.keys)
        guard section < keys.count else {
            return .zero
        }
        
        return CGSize(width: collectionView.bounds.width, height: 18)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return Constants.sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let keys = Array(favoritedLobbies.keys).sorted() // sort so the order is always the same
        guard indexPath.section < keys.count else {
            return
        }
        
        let key = keys[indexPath.section]
        
        guard let tagGroup = favoritedLobbies[key]?[indexPath.item],
            let game = favoriteGames.filter({ tagGroup.gameId == $0.identifier }).first else {
            return
        }
                
        onTagsSelected?(game, tagGroup.tags)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width - Constants.sectionInsets.left - Constants.sectionInsets.right, height: 46)
    }
}
