//
//  GameNavCollectionView.swift
//  GameGether
//
//  Created by James Ajhar on 2/7/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit
import ALGReversedFlowLayout
import ViewAnimator

class AlignBottomCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attrs = super.layoutAttributesForElements(in: rect)
        var attrsCopy = [UICollectionViewLayoutAttributes]()
        for  element in attrs! {
            let elementCopy = element.copy() as! UICollectionViewLayoutAttributes
            if (elementCopy.representedElementCategory == .cell) {
                elementCopy.frame.origin.y = elementCopy.frame.origin.y * 2.0
            }
            
            attrsCopy.append(elementCopy)
        }
        
        return attrsCopy
    }
}

class GameNavCollectionView: UICollectionView {
    
    // MARK: Properties
    
    enum GameNavLayoutDirection {
        case horizontal
        case vertical
    }
    
    struct Constants {
        static let insets = UIEdgeInsets(top: 0, left: 20, bottom: 20, right: 20)
        static let cellSpacing: CGFloat = 30.0
    }
    
    private(set) var favoriteGames = [Game]()
    
    var selectedGame: Game? {
        didSet {
            reloadData()
        }
    }
    
    var showAddNewGameIcon: Bool = true
    var onGameSelected: ((Game) -> Void)?
    var onAddNewGameSelected: (() -> Void)?
    var onBackgroundTapped: (() -> Void)?
    
    var layoutDirection: GameNavLayoutDirection = .vertical {
        didSet {
            switch layoutDirection {
            case .vertical:
                collectionViewLayout = ALGReversedFlowLayout()
                collectionViewLayout.invalidateLayout()
                reloadData()
            case .horizontal:
                let layout = UICollectionViewFlowLayout()
                layout.scrollDirection = .horizontal
                collectionViewLayout = layout
                collectionViewLayout.invalidateLayout()
                reloadData()
            }
        }
    }
    
    var cellSpacing: CGFloat = Constants.cellSpacing
    var insets: UIEdgeInsets = Constants.insets
    
    var cellWidth: CGFloat {
        return bounds.width * 0.159
    }
    
    var showSelector: Bool = false
    
    var contentHeight: CGFloat {
        let rows: CGFloat = ceil(CGFloat(favoriteGames.count) / 4)
        let height = (rows * cellWidth) + ((rows - 1) * cellSpacing) + insets.bottom + insets.top
        return height
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
        register(GameNavCollectionViewCell.self, forCellWithReuseIdentifier: GameNavCollectionViewCell.reuseIdentifier)
        
        dataSource = self
        delegate = self
        
        layoutDirection = .vertical

        reloadFavoriteGamesDataSource()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped(sender:)))
        tap.cancelsTouchesInView = false
        let backgroundView = UIView(frame: .zero)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.backgroundColor = .clear
        backgroundView.isUserInteractionEnabled = true
        backgroundView.addGestureRecognizer(tap)
        self.backgroundView = backgroundView
    }
    
    func animate() {
        let zoomAnimation = AnimationType.zoom(scale: 0.2)
        UIView.animate(views: visibleCells,
                       animations: [zoomAnimation],
                       duration: 0.5)
    }
    
    func animateCellAtPoint(_ point: CGPoint) {
        for cell in visibleCells {
            
            if cell.frame.contains(point) {
                UIView.animate(withDuration: 0.3) {
                    cell.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                }
                
            } else {
                UIView.animate(withDuration: 0.3) {
                    cell.transform = .identity
                }
            }
        }
    }
    
    @objc func backgroundTapped(sender: UITapGestureRecognizer) {
        onBackgroundTapped?()
    }
    
    /// Call to select a cell at a given point
    ///
    /// - Parameter point: The point of the cell to select
    /// - Returns: the selected indexPath at this point (if it exists)
    @discardableResult
    func selectCellAtPoint(_ point: CGPoint) -> IndexPath? {
        guard let indexPath = indexPathForItem(at: point) else { return nil }
        collectionView(self, didSelectItemAt: indexPath)
        return indexPath
    }
    
    func reloadFavoriteGamesDataSource(_ completion: (([Game], Error?) -> Void)? = nil) {
        
        // store these so we can start "fresh" and animate the cells in.
        
        if !DataCoordinator.shared.isUserSignedIn() {
            getAllGames(completion)
        } else {
            getFavoriteGames(completion)
        }
    }
    
    private func getAllGames(_ completion: (([Game], Error?) -> Void)? = nil) {
        
        let currentGames = favoriteGames
        favoriteGames.removeAll()
        reloadData()

        DataCoordinator.shared.getGames { [weak self] (games, error) in
            
            guard error == nil, let strongself = self else {
                print("Error: \(String(describing: error))")
                
                performOnMainThread {
                    // If something went wrong, use the last known saved games
                    self?.favoriteGames = currentGames
                    self?.reloadData()
                    completion?(games, error)
                }
                return
            }
            
            strongself.favoriteGames = games
            
            strongself.favoriteGames = games.sorted(by: {
                $0.title < $1.title
            })
            
            performOnMainThread {
                strongself.reloadData()
                completion?(games, error)
            }
        }

    }
    
    private func getFavoriteGames(_ completion: (([Game], Error?) -> Void)? = nil) {
        
        let currentGames = favoriteGames
        favoriteGames.removeAll()
        reloadData()

        DataCoordinator.shared.getFavoriteGames { [weak self] (games, error) in
            guard error == nil, let strongself = self else {
                print("Error: \(String(describing: error))")
                
                performOnMainThread {
                    // If something went wrong, use the last known saved games
                    self?.favoriteGames = currentGames
                    self?.reloadData()
                    completion?(games, error)
                }
                return
            }
            
            strongself.favoriteGames = games
            
            strongself.favoriteGames = games.sorted(by: {
                $0.title < $1.title
            })
            
            performOnMainThread {
                strongself.reloadData()
                completion?(games, error)
            }
        }
    }
}

extension GameNavCollectionView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count = favoriteGames.count
        
        if DataCoordinator.shared.isUserSignedIn(), showAddNewGameIcon {
            count += 1 // +1 for add game cell
        }
        
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GameNavCollectionViewCell.reuseIdentifier, for: indexPath) as! GameNavCollectionViewCell

        if showAddNewGameIcon,
            indexPath.item == 0,
            DataCoordinator.shared.isUserSignedIn() {
            // Create a game cell
            cell.imageView.image = #imageLiteral(resourceName: "AddGameRound")
        } else {
            
            let item = DataCoordinator.shared.isUserSignedIn() ? indexPath.item - (showAddNewGameIcon ? 1 : 0) : indexPath.item
            let game = favoriteGames[item]
    
            if showSelector {
                cell.setSelected(game.identifier == selectedGame?.identifier)
            }
            
            cell.game = game
        }

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if showAddNewGameIcon,
            indexPath.item == 0,
            DataCoordinator.shared.isUserSignedIn() {
            selectedGame = nil
            
            // Add New Favorite Game
            onAddNewGameSelected?()
            
        } else {
            let item = DataCoordinator.shared.isUserSignedIn() ? indexPath.item - (showAddNewGameIcon ? 1 : 0) : indexPath.item
            let game = favoriteGames[item]
            selectedGame = game
            onGameSelected?(game)
        }
        
        reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: cellWidth, height: cellWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return insets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return cellSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return cellSpacing
    }
}
