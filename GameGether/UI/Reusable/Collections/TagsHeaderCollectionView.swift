//
//  TagsCollectionView.swift
//  GameGether
//
//  Created by James Ajhar on 9/13/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

protocol TagsHeaderCollectionViewDelegate: class {
    func tagsHeaderCollectionView(collectionView: TagsHeaderCollectionView, canSelectTag tag: Tag, atIndexPath indexPath: IndexPath) -> Bool
    func tagsHeaderCollectionView(collectionView: TagsHeaderCollectionView, selectedTagsDidChange selectedTags: [Tag])
    func tagsHeaderCollectionView(collectionView: TagsHeaderCollectionView, didSelectTagsGroup tagsGroup: TagsGroup)
}

// Optional
extension TagsHeaderCollectionViewDelegate {
    func tagsHeaderCollectionView(collectionView: TagsHeaderCollectionView, didSelectTagsGroup tagsGroup: TagsGroup) { /* Optional */ }
    
    func tagsHeaderCollectionView(collectionView: TagsHeaderCollectionView, canSelectTag tag: Tag, atIndexPath indexPath: IndexPath) -> Bool {
        return true
    }
}

class TagsHeaderCollectionView: UICollectionView {
    
    enum TagsCollectionViewCellType {
        case tag
        case tagsGroup
    }
    
    enum LayoutDirection {
        case topToBottom
        case leftToRight
        case rightToLeft
    }
    
    // MARK: Properties
    
    private(set) var tags = [TagType: [Tag]]()
    private(set) var tagGroups = [TagsGroup]()

    var game: Game? {
        didSet {
            reloadDataSource()
        }
    }
    
    weak var tagsHeaderDelegate: TagsHeaderCollectionViewDelegate?
    
    /// True if selected tags should be shown within the collection. False if the selected section should be hidden from view.
    var showSelectedTags: Bool = true {
        didSet {
            reloadData()
        }
    }
    
    /// True if size tags should show in the list
    var showSizeTags: Bool = false {
        didSet {
            reloadData()
        }
    }

    var leftInset: CGFloat = 8
    var rightInset: CGFloat = 8
    var sectionSpacing: CGFloat = 8

    var onReload: (() -> Void)?

    private(set) var selectedTags = [Tag]() {
        didSet {
            selectedTags.sortByType()
            reloadData()

            if self.selectedTags.hashedValue != oldValue.hashedValue {
                // Something changed, reload
                tagsHeaderDelegate?.tagsHeaderCollectionView(collectionView: self, selectedTagsDidChange: selectedTags)
            }
        }
    }
    
    /// When set, will only show tags with of this type. When nil, shows everything.
    var filter: TagType? {
        didSet {
            reloadData()
        }
    }
    
    /// Should tag cells align to the left or to the right?
    var layoutDirection: LayoutDirection = .leftToRight {
        didSet {
            // If nothing changed...do nothing...
            guard oldValue != layoutDirection else { return }
            updateLayout()
        }
    }
    
    var cellType: TagsCollectionViewCellType = .tag {
        didSet {
            // If nothing changed...do nothing...
            reloadData()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        commonInit()
    }
    
    internal func updateLayout() {
        switch layoutDirection {
        case .topToBottom:
            let newLayout = GGCollectionViewLeftAlignFlowLayout()
            newLayout.scrollDirection = .vertical
            newLayout.estimatedItemSize = CGSize(width: 100, height: 30)
            setCollectionViewLayout(newLayout, animated: false)
        case .leftToRight:
            let newLayout = UICollectionViewFlowLayout()
            newLayout.scrollDirection = .horizontal
            newLayout.estimatedItemSize = CGSize(width: 100, height: 30)
            setCollectionViewLayout(newLayout, animated: false)
        case .rightToLeft:
            let newLayout = RTLCollectionViewFlowLayout()
            newLayout.scrollDirection = .horizontal
            newLayout.estimatedItemSize = CGSize(width: 100, height: 30)
            setCollectionViewLayout(newLayout, animated: false)
        }
        reloadData()
    }
    
    internal func commonInit() {
        dataSource = self
        delegate = self
        
        register(UINib(nibName: GameTagCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: GameTagCollectionViewCell.reuseIdentifier)
        
        for type in TagType.allTypes {
            tags[type] = []
        }
        
        updateLayout()
    }
    
    override func reloadData() {
        super.reloadData()
        // Allow the collection to maintain its proper content size so we can resize it to fit its contents
        invalidateIntrinsicContentSize()
                
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] (_) in
            self?.onReload?()
        }
    }
    
    func reloadDataSource(_ completion: (() -> Void)? = nil) {
        guard let game = game else {
            completion?()
            return
        }
        
        DataCoordinator.shared.getTags(forGame: game.identifier) { [weak self] (remoteTags, error) in
            guard let weakSelf = self else { return }
            guard error == nil, let remoteTags = remoteTags else {
                GGLog.error("Error: \(String(describing: error))")
                completion?()
                return
            }
            
            performOnMainThread {
                var sortedTags = remoteTags
                sortedTags.sortByType()
                weakSelf.setup(withTags: sortedTags)
                completion?()
            }
        }
    }
    
    func setup(withTags tags: [Tag]) {
        // Start fresh
        for type in TagType.allTypes {
            self.tags[type] = []
        }
        self.tagGroups.removeAll()
        
        cellType = .tag
        
        for tag in tags {
            if !showSizeTags, tag.size != 0 {
                continue
            }
            
            self.tags[tag.type]?.append(tag)
            self.tags[tag.type]?.sortByPriority()
            
            if layoutDirection == .rightToLeft {
                self.tags[tag.type]?.reverse()
            }
        }
        reloadData()
    }
    
    func setup(withTagGroups tagGroups: [TagsGroup]) {
        // Start fresh
        for type in TagType.allTypes {
            self.tags[type] = []
        }
        cellType = .tagsGroup
        self.tagGroups = tagGroups
        reloadData()
    }
    
    func selectTag(atIndexPath indexPath: IndexPath) {
        
        var selectedTag: Tag?
        
        if indexPath.section == 0 {
            selectedTag = selectedTags[indexPath.item]
        } else if let type = TagType(rawValue: indexPath.section - 1) {
            
            if var nestedTags = selectedTags.last?.nestedTags, !nestedTags.isEmpty, nestedTags.first?.type == type {
                nestedTags.sortByPriority()
                selectedTag = nestedTags[indexPath.item]
                
            } else {
                selectedTag = tags[type]?[indexPath.item]
            }
        }

        guard let tag = selectedTag,
            tagsHeaderDelegate == nil || tagsHeaderDelegate?.tagsHeaderCollectionView(collectionView: self,
                                                                                      canSelectTag: tag,
                                                                                      atIndexPath: indexPath) == true else {
            return
        }
        
        if indexPath.section == 0 {
            // de-select a tag
            selectedTags.remove(at: indexPath.item)
            
        } else {
            // Selected an unselected tag
            selectedTags.append(tag)
        }
    
        // Provide haptic feedback
        UISelectionFeedbackGenerator().selectionChanged()
        
        reloadData()
        scrollLeft()
        
        layoutIfNeeded()
    }
    
    func scrollLeft() {
        UIView.animate(withDuration: 0.3) {
            self.contentOffset.x = 0
        }
    }
    
    func select(tags: [Tag]) {
        
        var tagsToSelect = [Tag]()
        
        var allTags = [Tag]()

        for group in tagGroups {
            allTags.append(contentsOf: group.tags)
        }
        
        for (_, dictionaryTags) in self.tags {
            allTags.append(contentsOf: dictionaryTags)
        }
        
        allTags.forEach({ (tag) in
            if tags.contains(where: { $0.identifier == tag.identifier }) {
                tagsToSelect.append(tag)
            }
        })
        
        selectedTags = tagsToSelect
    }
}

extension TagsHeaderCollectionView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        switch cellType {
        case .tag:
            return TagType.totalTypes + 1 // +1 for selected tags section
        case .tagsGroup:
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch cellType {
        case .tag:
            if section == 0, showSelectedTags {
                return selectedTags.count
            }
            
            // Subtract 1 to offset section 0 being used for selected tags
            guard let type = TagType(rawValue: section - 1), let tagsForSection = tags[type] else { return 0 }
            
            if let nestedTags = selectedTags.last?.nestedTags, !nestedTags.isEmpty, nestedTags.first?.type == type {
                return nestedTags.count
            }
            
            if let filter = filter, type != filter {
                return 0
            }
            
            if selectedTags.contains(where: { $0.type == type }) {
                // Hide sections where a tag is selected
                return 0
            }
            
            return tagsForSection.count

        case .tagsGroup:
            return tagGroups.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GameTagCollectionViewCell.reuseIdentifier, for: indexPath) as! GameTagCollectionViewCell

        switch cellType {
        case .tag:
            if indexPath.section == 0 {
                // Selected tags section
                cell.gameTag = selectedTags[indexPath.item]
                cell.setSelected(true)
                cell.layoutIfNeeded()
                return cell
            }
            
            if var nestedTags = selectedTags.last?.nestedTags, !nestedTags.isEmpty {
                nestedTags.sortByPriority()
                cell.gameTag = nestedTags[indexPath.item]
            
            } else {
                guard let type = TagType(rawValue: indexPath.section - 1), let tag = tags[type]?[indexPath.item] else { return cell }
                
                cell.gameTag = tag
            }
            
        case .tagsGroup:
            cell.tagGroup = tagGroups[indexPath.item]
        }
        
        cell.setSelected(false)
        cell.layoutIfNeeded()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch cellType {
        case .tag:
            selectTag(atIndexPath: indexPath)
        case .tagsGroup:
            tagsHeaderDelegate?.tagsHeaderCollectionView(collectionView: self, didSelectTagsGroup: tagGroups[indexPath.item])
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
                
        guard numberOfItems(inSection: section) > 0 else { return .zero }

        switch cellType {
        case .tag:
            if section == 0 {
                // Selected tags section
                return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: 0)
            }

        case .tagsGroup:
            return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: 0)
        }
        
        if section == TagType.totalTypes - 1 {
            // last section in unselected tags
            return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)
        }
        
        return UIEdgeInsets(top: 0, left: section > 1 ? sectionSpacing : leftInset, bottom: 0, right: rightInset)
    }
}
