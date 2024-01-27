//
//  ChatroomSessionBannerViewController.swift
//  GameGether
//
//  Created by James Ajhar on 12/16/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class ChatroomSessionBannerViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var gameImageView: UIImageView!
    
    @IBOutlet weak var descriptionLabel: UILabel! {
        didSet {
            descriptionLabel.textColor = .white
            descriptionLabel.font = AppConstants.Fonts.robotoMedium(14).font
        }
    }
    
    @IBOutlet weak var tagsCollectionView: TagsDisplayCollectionView! {
        didSet {
            tagsCollectionView.backgroundColor = .clear
            tagsCollectionView.cellHeight = 15
            tagsCollectionView.cellPadding = 2
            tagsCollectionView.cellFont = AppConstants.Fonts.robotoBold(11).font
           
            tagsCollectionView.onReload = { [weak self] in
                guard let weakSelf = self else { return }
                // Resize to fit content
                weakSelf.tagsCollectionHeightConstraint.constant = weakSelf.tagsCollectionView.collectionViewLayout.collectionViewContentSize.height
                weakSelf.view.layoutIfNeeded()
            }
        }
    }
    @IBOutlet weak var tagsCollectionHeightConstraint: NSLayoutConstraint!
    
    
    // MARK: - Properties
    
    var session: GameSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let session = session {
            configure(withSession: session)
        }
    }
    
    private func configure(withSession session: GameSession) {
        self.session = session
        descriptionLabel.text = session.description
        gameImageView.sd_setImage(with: session.game?.iconImageURL, completed: nil)
        tagsCollectionView.tags = session.tags
        view.backgroundColor = UIColor(hexString: session.game?.headerColor ?? "#FFFFFF")
        view.layoutIfNeeded()
    }
}
