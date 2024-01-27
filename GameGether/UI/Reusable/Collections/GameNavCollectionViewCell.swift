//
//  GameNavCollectionViewCell.swift
//  GameGether
//
//  Created by James Ajhar on 2/7/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit
import FLAnimatedImage

class GameNavCollectionViewCell: UICollectionViewCell {
    
    // MARK: Properties
    let imageView: UIImageView = {
       let imageView = UIImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let shadowView: UIView = {
        let shadowView = UIView(frame: .zero)
        shadowView.translatesAutoresizingMaskIntoConstraints = false
        shadowView.addDropShadow(color: .black, opacity: 0.33, offset: CGSize(width: 1, height: 5), radius: 5)
        return shadowView
    }()
    
    private let animatedSelectorView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFit
        view.image = #imageLiteral(resourceName: "Path 306")
        return view
    }()
    
    var game: Game? {
        didSet {
            setupWithGame()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(shadowView)
        shadowView.constrainToSuperview()

        shadowView.addSubview(imageView)
        imageView.constrainToSuperview()
        imageView.cornerRadius = contentView.bounds.width / 2
        
        contentView.addSubview(animatedSelectorView)
        animatedSelectorView.constrainTo(edge: .left)?.constant = -12
        animatedSelectorView.constrainTo(edge: .top)?.constant = -12
        animatedSelectorView.constrainTo(edge: .right)?.constant = 12
        animatedSelectorView.constrainTo(edge: .bottom)?.constant = 12
        animatedSelectorView.isHidden = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        game = nil
        setSelected(false)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.cornerRadius = contentView.bounds.width / 2
        shadowView.cornerRadius = contentView.bounds.width / 2
    }
    
    func setupWithGame() {
        guard let game = game else { return }
        imageView.sd_setImage(with: game.iconImageURL, completed: nil)
    }
    
    func setSelected(_ isSelected: Bool) {
        animatedSelectorView.isHidden = !isSelected
        
        if isSelected {
            animatedSelectorView.layer.removeAllAnimations()
            animatedSelectorView.rotate(duration: 2.5)
        }
    }
}
