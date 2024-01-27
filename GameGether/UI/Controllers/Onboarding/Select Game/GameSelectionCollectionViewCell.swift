//
//  GameSelectionCollectionViewCell.swift
//  GameGether
//
//  Created by James Ajhar on 9/6/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

class GameSelectionCollectionViewCell: UICollectionViewCell {
    
    // MARK: Properties
    private let imageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.cornerRadius = 30
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let checkmarkImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .center
        return imageView
    }()
    
    var game: Game? {
        didSet {
            setupWithGame()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        contentView.addSubview(imageView)
        imageView.constrainToSuperview()
        
        contentView.addSubview(checkmarkImageView)
        checkmarkImageView.constrainTo(edge: .top)?.constant = 9
        checkmarkImageView.constrainTo(edge: .right)?.constant = -9
        setSelected(selected: false)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
    
    func setupWithGame() {
        guard let game = game else { return }
        imageView.sd_setImage(with: game.gameSelectionImageURL, completed: nil)
    }
    
    func setSelected(selected: Bool) {
        if selected {
            checkmarkImageView.image = #imageLiteral(resourceName: "SelectGameCheckmarkSelected")
        } else {
            checkmarkImageView.image = #imageLiteral(resourceName: "SelectGameCheckmarkUnselected")
        }
    }
}
