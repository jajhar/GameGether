//
//  ProfileGameCollectionViewCell.swift
//  GameGether
//
//  Created by James Ajhar on 5/30/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit
import PKHUD

class ProfileGameCollectionViewCell: UICollectionViewCell {

    // MARK: - Outlets
    @IBOutlet weak var gameImageView: UIImageView! {
        didSet {
            let tap = UITapGestureRecognizer(target: self, action: #selector(gameIconPressed(_:)))
            gameImageView.addGestureRecognizer(tap)
        }
    }
    @IBOutlet var gameIconBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var gameImageShadowView: UIView!

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var copyIGNButton: UIButton!
    @IBOutlet weak var copyButtonWrapper: UIButton!
    
    @IBOutlet weak var gameTagsCollectionView: TagsHeaderCollectionView! {
        didSet {
            gameTagsCollectionView.leftInset = 0
            gameTagsCollectionView.rightInset = 8
            gameTagsCollectionView.layoutDirection = .topToBottom
            gameTagsCollectionView.tagsHeaderDelegate = self
            
            gameTagsCollectionView.onReload = { [weak self] in
                self?.resizeTagsCollectionView()
            }
            
        }
    }
    @IBOutlet var gameTagsCollectionHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var titleLabelTopAlignmentConstraint: NSLayoutConstraint!
    @IBOutlet var titleLabelCenterYAlignmentConstraint: NSLayoutConstraint!
    
    // MARK: - Properties
    private(set) var game: Game?
    private(set) var user: User?
    private(set) var gamerTag: String?

    var onGameIconPressed: ((Game) -> Void)?
    var onEditPressed: ((Game) -> Void)?
    var onTagGroupSelected: ((Game, TagsGroup) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        styleUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLabel.text = nil
        gameImageView.image = nil
        gamerTag = nil
        game = nil
        user = nil
        gameImageView.sd_cancelCurrentImageLoad()
        gameTagsCollectionView.setup(withTagGroups: [])
        titleLabelCenterYAlignmentConstraint.isActive = true
        titleLabelTopAlignmentConstraint.isActive = false
        resizeTagsCollectionView()
        gameIconBottomConstraint.isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layoutIfNeeded()
        resizeTagsCollectionView()
        
        // Add drop shadow to game images
        gameImageShadowView.addDropShadow(color: .black, opacity: 0.33, offset: CGSize(width: 1, height: 5), radius: 5)
        gameImageShadowView.cornerRadius = gameImageView.bounds.width / 2
    }
    
    private func styleUI() {
        titleLabel.font = AppConstants.Fonts.robotoRegular(14).font
        editButton.titleLabel?.font = AppConstants.Fonts.robotoMedium(14).font
        editButton.setTitleColor(UIColor(hexString: "#3399FF"), for: .normal)
    }
    
    public func configure(withGame game: Game, andUser user: User, tagsToCompare: [TagsGroup]? = nil) {
        self.game = game
        self.user = user
        
        gamerTag = user.gamerTags.filter({ $0.game?.identifier == game.identifier }).first?.gamerTag ?? user.ign
        
        if gamerTag?.isEmpty == true, user.isSignedInUser {
            gamerTag = "add your gamertag"
            titleLabel.textColor = UIColor(hexString: "#CCCCCC")
        } else {
            titleLabel.textColor = UIColor(hexString: "#000000")
        }
        
        titleLabel.text = gamerTag?.isEmpty == true ? user.ign : gamerTag
        gameImageView.sd_setImage(with: game.iconImageURL, completed: nil)
        
        editButton.isHidden = !user.isSignedInUser
        copyIGNButton.isHidden = user.isSignedInUser
        copyButtonWrapper.isHidden = user.isSignedInUser
        
        let followedTags = user.followedTags.filter({ $0.gameId == game.identifier })
        
        if followedTags.count > 0 {
            
            if let tagsToCompare = tagsToCompare {
                // Only show tags in common
                let filteredGroups: [TagsGroup] = followedTags.compactMap({
                    return tagsToCompare.containsTags(tags: $0.tags, forGame: game.identifier) ? $0 : nil
                })
                
                gameTagsCollectionView.setup(withTagGroups: filteredGroups)
                
            } else {
                // Show everything!
                gameTagsCollectionView.setup(withTagGroups: followedTags)
            }
            
            titleLabelCenterYAlignmentConstraint.isActive = false
            titleLabelTopAlignmentConstraint.isActive = true
            gameTagsCollectionHeightConstraint.isActive = true
            gameIconBottomConstraint.isActive = false

        } else {
            titleLabelCenterYAlignmentConstraint.isActive = true
            titleLabelTopAlignmentConstraint.isActive = false
            gameIconBottomConstraint.isActive = true
            gameTagsCollectionHeightConstraint.isActive = false
        }
        
        contentView.layoutIfNeeded()
        resizeTagsCollectionView()
        contentView.layoutIfNeeded()
    }
    
    private func resizeTagsCollectionView() {
        gameTagsCollectionHeightConstraint.constant = gameTagsCollectionView.collectionViewLayout.collectionViewContentSize.height
        contentView.setNeedsLayout()
        contentView.layoutIfNeeded()
    }
    
    @IBAction func copyGamerTagButtonPressed(_ sender: UIButton) {
        UIPasteboard.general.string = gamerTag
        HUD.flash(.label("gamertag copied"), delay: 1)
    }
    
    @IBAction func editButtonPressed(_ sender: UIButton) {
        guard let game = self.game else { return }
        onEditPressed?(game)
    }
    
    @IBAction func gameIconPressed(_ sender: UIButton) {
        guard let game = self.game else { return }
        onGameIconPressed?(game)
    }
}

extension ProfileGameCollectionViewCell: TagsHeaderCollectionViewDelegate {
    
    func tagsHeaderCollectionView(collectionView: TagsHeaderCollectionView, didSelectTagsGroup tagsGroup: TagsGroup) {
        if let game = game {
            onTagGroupSelected?(game, tagsGroup)
        }
    }
    
    func tagsHeaderCollectionView(collectionView: TagsHeaderCollectionView, canSelectTag tag: Tag, atIndexPath indexPath: IndexPath) -> Bool {
        return false // don't allow selection
    }
    
    func tagsHeaderCollectionView(collectionView: TagsHeaderCollectionView, selectedTagsDidChange selectedTags: [Tag]) {
        // NOP
    }
}
