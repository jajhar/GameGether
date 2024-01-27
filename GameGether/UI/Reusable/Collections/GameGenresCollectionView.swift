//
//  GameGenresCollectionView.swift
//  GameGether
//
//  Created by James Ajhar on 8/29/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class GameGenresCollectionView: UICollectionView {

    // MARK: - Properties
    var genres = [Genre]() {
        didSet { reloadData() }
    }
    
    var onGenreSelected: ((Genre) -> Void)?
    var onGenreDeselected: ((Genre) -> Void)?

    private(set) var selectedGenre: Genre? {
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
        delegate = self
        
        let newLayout = UICollectionViewFlowLayout()
        newLayout.scrollDirection = .horizontal
        newLayout.estimatedItemSize = CGSize(width: 100, height: 30)
        setCollectionViewLayout(newLayout, animated: false)

        register(UINib(nibName: GameTagCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: GameTagCollectionViewCell.reuseIdentifier)
    }
}

extension GameGenresCollectionView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return genres.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GameTagCollectionViewCell.reuseIdentifier, for: indexPath) as! GameTagCollectionViewCell
        
        let genre = genres[indexPath.item]
        cell.tagLabel.text = genre.title
        cell.setSelected(genre.identifier == selectedGenre?.identifier)
        cell.layoutIfNeeded()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let genre = genres[indexPath.item]
        
        if genre.identifier == selectedGenre?.identifier {
            // deselect
            selectedGenre = nil
            onGenreDeselected?(genre)
        } else {
            selectedGenre = genre
            onGenreSelected?(genre)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
    }
}

