//
//  GameTagCollectionViewCell.swift
//  GameGether
//
//  Created by James Ajhar on 9/8/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

class GameTagCollectionViewCell: UICollectionViewCell {

    // MARK: Outlets
    @IBOutlet weak var wrapperView: UIView!
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var wrapperViewHeightConstraint: NSLayoutConstraint!
    
    // MARK: Properties
    var gameTag: Tag? {
        didSet {
            setupWithTag()
        }
    }
    
    var tagGroup: TagsGroup? {
        didSet {
            setupWithFollowedTag()
        }
    }
    
    var maxHeight: CGFloat = 30 {
        didSet {
            wrapperViewHeightConstraint.constant = maxHeight
        }
    }
    
    var themeColor: UIColor = AppConstants.Colors.tagPillColor.color {
        didSet {
            wrapperView.layer.borderColor = themeColor.cgColor
            setSelected(isTagSelected)
        }
    }
    
    var allowsSelection: Bool = true
    
    private(set) var isTagSelected: Bool = false
    
    override func prepareForReuse() {
        super.prepareForReuse()
        tagLabel.text = ""
        setSelected(false)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        styleUI()

        wrapperView.clipsToBounds = true
        wrapperView.layer.cornerRadius = 4
        wrapperView.layer.borderColor = AppConstants.Colors.tagPillColor.color.cgColor
        wrapperView.layer.borderWidth = 1
        
        // These two lines fix an auto resizing bug...
        // https://stackoverflow.com/questions/25804588/auto-layout-in-uicollectionviewcell-not-working
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    private func styleUI() {
        tagLabel.font = AppConstants.Fonts.robotoBold(13).font
        tagLabel.textColor = AppConstants.Colors.tagPillColor.color
    }
    
    func setupWithTag() {
        guard let gameTag = gameTag else { return }
        
        tagLabel.text = gameTag.title
    }
    
    func setupWithFollowedTag() {
        guard let followedTag = tagGroup else { return }
        
        tagLabel.text = followedTag.tags.compactMap({ $0.title }).joined(separator: " ")
    }
    
    func setSelected(_ isSelected: Bool) {
        guard allowsSelection else { return }
        
        isTagSelected = isSelected
        if isSelected {
            tagLabel.textColor = .white
            wrapperView.backgroundColor = themeColor
        } else {
            tagLabel.textColor = themeColor
            wrapperView.backgroundColor = .white
        }
    }
}
