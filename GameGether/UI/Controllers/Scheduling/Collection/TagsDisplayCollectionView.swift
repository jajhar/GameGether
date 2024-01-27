//
//  TagsDisplayCollectionView.swift
//  GameGether
//
//  Created by James Ajhar on 9/17/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class TagsDisplayCollectionView: UICollectionView {

    // MARK: - Properties
    
    var tags = [Tag]() {
        didSet {
            tags.sortByType()
            reloadData()
        }
    }
    
    var cellHeight: CGFloat = 26 {
        didSet { reloadData() }
    }
    
    var cellPadding: CGFloat = 3 {
        didSet { reloadData() }
    }
    
    var cellFont: UIFont = AppConstants.Fonts.robotoBold(13).font {
        didSet { reloadData() }
    }
    
    var onReload: (() -> Void)?
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    internal func commonInit() {
        
        let newLayout = GGCollectionViewLeftAlignFlowLayout()
        newLayout.scrollDirection = .vertical
        newLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        setCollectionViewLayout(newLayout, animated: false)

        dataSource = self
        delegate = self
        
        register(UINib(nibName: GameTagCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: GameTagCollectionViewCell.reuseIdentifier)
    }
    
    override func reloadData() {
        super.reloadData()
        // Allow the collection to maintain its proper content size so we can resize it to fit its contents
        invalidateIntrinsicContentSize()
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] (_) in
            // Give it a min to recalculate the contentsize
            self?.onReload?()
        }
    }
}

extension TagsDisplayCollectionView: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GameTagCollectionViewCell.reuseIdentifier, for: indexPath) as! GameTagCollectionViewCell
        cell.gameTag = tags[indexPath.item]
        cell.tagLabel.font = cellFont
        cell.maxHeight = cellHeight
        cell.allowsSelection = false
        cell.wrapperView.backgroundColor = .black
        cell.tagLabel.textColor = .white
        cell.themeColor = .black
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return cellPadding
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return cellPadding
    }
}
