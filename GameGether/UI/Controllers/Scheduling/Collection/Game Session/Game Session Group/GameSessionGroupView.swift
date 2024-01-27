//
//  GameSessionGroupView.swift
//  GameGether
//
//  Created by James Ajhar on 12/9/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class GameSessionGroupView: UIView {

    // MARK: - Outlets
    
    @IBOutlet weak var tagsCollectionView: TagsDisplayCollectionView! {
        didSet {
            tagsCollectionView.cellHeight = 15
            tagsCollectionView.cellPadding = 2
            tagsCollectionView.cellFont = AppConstants.Fonts.robotoBold(11).font
            
            tagsCollectionView.onReload = { [weak self] in
                guard let weakSelf = self else { return }
                // Resize to fit content
                weakSelf.tagsCollectionHeightConstraint.constant = weakSelf.tagsCollectionView.collectionViewLayout.collectionViewContentSize.height
                weakSelf.layoutIfNeeded()
            }
        }
    }
    @IBOutlet weak var tagsCollectionHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var ignLabel: UILabel! {
        didSet {
            ignLabel.font = AppConstants.Fonts.robotoRegular(12).font
            ignLabel.textColor = .white
        }
    }
    
    @IBOutlet weak var gameIconImageView: UIImageView!
    @IBOutlet weak var backgroundImageView: AvatarInitialsImageView!
    
    @IBOutlet weak var shadowView: UIView! {
        didSet {
            shadowView.addDropShadow(color: UIColor(hexString: "#0000002B"), opacity: 1, offset: CGSize(width: 1, height: 2), radius: 2)
            shadowView.cornerRadius = 11
        }
    }
    
    @IBOutlet weak var textView: UITextView! {
        didSet {
            textView.font = AppConstants.Fonts.robotoMedium(14).font
            textView.textContainerInset = UIEdgeInsets(top: 0, left: 1, bottom: 5, right: 1)
        }
    }
    
    // MARK: - Properties
    var session: GameSession? {
        didSet {
            configureView()
        }
    }
    
    public func prepareForReuse() {
        textView.text = nil
        tagsCollectionView.tags = []
        
        gameIconImageView.sd_cancelCurrentImageLoad()
        gameIconImageView.image = nil
        
        backgroundImageView.sd_cancelCurrentImageLoad()
        backgroundImageView.image = nil
    }
    
    public func configureForHeightCalculation(session: GameSession) {
        // Only do the bare minimum to calculate the height of this view
        ignLabel.text = session.createdBy?.ign
        textView.text = session.description
        ignLabel.sizeToFit()
        textView.sizeToFit()
    }
    
    private func configureView() {
        guard let session = session else {
            prepareForReuse()
            return
        }

        backgroundColor = UIColor(hexString: session.game?.headerColor ?? "#000000")
        backgroundImageView.sd_setImage(with: session.createdBy?.profileImageURL ?? session.game?.tagThemeImageURL, completed: nil)
        gameIconImageView.sd_setImage(with: session.game?.iconImageURL, completed: nil)
        tagsCollectionView.tags = session.tags
        ignLabel.text = session.createdBy?.ign
        textView.text = session.description
    }
}
