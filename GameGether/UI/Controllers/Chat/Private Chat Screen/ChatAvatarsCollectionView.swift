//
//  ChatAvatarsCollectionView.swift
//  GameGether
//
//  Created by James Ajhar on 8/8/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

class ChatAvatarsCollectionView: UICollectionView {
    
    var users: [User] = [User]() {
        didSet {
            performOnMainThread {
                self.reloadData()
            }
        }
    }
    
    var onUserTapped: ((User) -> Void)?
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    internal func commonInit() {
        delegate = self
        dataSource = self
        register(ChatAvatarCollectionViewCell.self, forCellWithReuseIdentifier: ChatAvatarCollectionViewCell.reuseIdentifier)
    }
    
    func animateActiveSpeakers(speakers: [UInt]) {
        let activeSpeakers = users.filter({ speakers.contains($0.uid) })
        
        for cell in visibleCells {
            guard let cell = cell as? ChatAvatarCollectionViewCell,
                activeSpeakers.contains(where: { $0.identifier == cell.user?.identifier }) else { continue }
            // This user is currently speaking. Animate them.
            cell.animateSpeaker()
        }
    }
}

extension ChatAvatarsCollectionView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return users.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChatAvatarCollectionViewCell.reuseIdentifier, for: indexPath) as! ChatAvatarCollectionViewCell
        cell.user = users[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? ChatAvatarCollectionViewCell, let user = cell.user else {
            return
        }
        
        onUserTapped?(user)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        // Make sure that the number of items is worth the computing effort.
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout,
            let dataSourceCount = collectionView.dataSource?.collectionView(collectionView, numberOfItemsInSection: section),
            dataSourceCount > 0 else {
                return .zero
        }
        
        let cellCount = CGFloat(dataSourceCount)
        let itemSpacing = flowLayout.minimumInteritemSpacing
        let cellWidth = flowLayout.itemSize.width + itemSpacing
        var insets = flowLayout.sectionInset
        
        // Make sure to remove the last item spacing or it will
        // miscalculate the actual total width.
        let totalCellWidth = (cellWidth * cellCount) - itemSpacing
        let contentWidth = collectionView.frame.size.width - collectionView.contentInset.left - collectionView.contentInset.right
        
        // If the number of cells that exist take up less room than the
        // collection view width, then center the content with the appropriate insets.
        // Otherwise return the default layout inset.
        guard totalCellWidth < contentWidth else {
            return insets
        }
        
        // Calculate the right amount of padding to center the cells.
        let padding = (contentWidth - totalCellWidth) / 2.0
        insets.left = padding
        insets.right = padding
        return insets
    }
}
