//
//  GamesCollectionView.swift
//  GameGether
//
//  Created by James Ajhar on 9/6/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

class GamesCollectionView: UICollectionView {

    // MARK: Properties
    private(set) var games = [Game]() {
        didSet {
            filteredGames = games
        }
    }
    
    private var filteredGames = [Game]() {
        didSet { reloadData() }
    }
    
    var selectedGames = [Game]() {
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
        register(GameSelectionCollectionViewCell.self, forCellWithReuseIdentifier: GameSelectionCollectionViewCell.reuseIdentifier)
        reloadDataSource()
    }
    
    func reloadDataSource(_ completion: (([Game], Error?) -> Void)? = nil) {
        DataCoordinator.shared.getGames { [weak self] (games, error) in
           
            performOnMainThread {
                defer { completion?(games, error) }
                
                guard error == nil else {
                    GGLog.error("Error: \(String(describing: error))")
                    return
                }
            
                self?.games = games
                self?.collectionViewLayout.invalidateLayout()
                self?.reloadData()
            }
        }
    }
    
    func filter(byGenre genre: Genre?) {
        guard let genre = genre else {
            // Remove filter
            filteredGames = games
            return
        }
        
        filteredGames = games.filter({ $0.genres.contains(where: { $0.identifier == genre.identifier }) })
    }
}

extension GamesCollectionView: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredGames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GameSelectionCollectionViewCell.reuseIdentifier, for: indexPath) as! GameSelectionCollectionViewCell
        let game = filteredGames[indexPath.item]
        cell.game = game
        cell.setSelected(selected: selectedGames.contains(where: { $0.identifier == game.identifier }))
        return cell
    }
}
