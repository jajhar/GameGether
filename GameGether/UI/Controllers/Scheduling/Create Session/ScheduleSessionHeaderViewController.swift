//
//  ScheduleSessionHeaderViewController.swift
//  GameGether
//
//  Created by James Ajhar on 9/12/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class ScheduleSessionHeaderViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var gameIconButton: UIButton!
    @IBOutlet weak var gameBackgroundImageView: UIImageView!
    @IBOutlet weak var gameTypeLabel: UILabel!
    
    @IBOutlet weak var gameImageGradientView: GradientView! {
        didSet {
            gameImageGradientView.startPointX = 0
            gameImageGradientView.endPointX = 0
            gameImageGradientView.startPointY = 0.5
            gameImageGradientView.endPointY = 1
            gameImageGradientView.topColor = UIColor.white.withAlphaComponent(0)
            gameImageGradientView.bottomColor = UIColor.black.withAlphaComponent(0.55)
        }
    }

    @IBOutlet weak var tagsCollectionView: TagsDisplayCollectionView! {
        didSet {
            tagsCollectionView.cellHeight = 26
            tagsCollectionView.cellPadding = 3
            tagsCollectionView.cellFont = AppConstants.Fonts.robotoBold(13).font
            
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
    
    var game: Game? {
        didSet {
            guard isViewLoaded else { return }
            setupView()
        }
    }
    
    var tags: [Tag]? {
        didSet {
            guard isViewLoaded else { return }
            setupView()
        }
    }
    
    var onGameIconTapped: (() -> Void)?
    var onTypeSelectorTapped: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
    }

    private func setupView() {
        guard let game = game else { return }
        
        gameIconButton.sd_setImage(with: game.iconImageURL, for: .normal, placeholderImage: #imageLiteral(resourceName:"GG_AI_Selected"), completed: nil)
        tagsCollectionView.tags = tags ?? []
    }
    
    public func setSessionType(_ sessionType: GameSessionType) {
        
        gameTypeLabel.text = sessionType.title

        if sessionType.type == .request {
            gameBackgroundImageView.image = #imageLiteral(resourceName: "RequestSessionBackground")
            gameBackgroundImageView.backgroundColor = UIColor(hexString: game?.headerColor ?? "")
            
        } else if let imageURL = sessionType.imageURL {
            gameBackgroundImageView.sd_setImage(with: imageURL, completed: nil)
            
        } else {
            gameBackgroundImageView.sd_setImage(with: game?.tagThemeImageURL, completed: nil)
        }
        
    }
    
    // MARK: - Interface Actions
    
    @IBAction func gameIconPressed(_ sender: UIButton) {
        onGameIconTapped?()
    }
    
    @IBAction func typeDropdownButtonPressed(_ sender: Any) {
        onTypeSelectorTapped?()
    }
}
