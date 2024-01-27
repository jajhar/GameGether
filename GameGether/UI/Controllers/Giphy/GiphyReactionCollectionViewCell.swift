//
//  GiphyReactionCollectionViewCell.swift
//  GameGether
//
//  Created by James Ajhar on 1/17/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit
import FLAnimatedImage

class GiphyReactionCollectionViewCell: UICollectionViewCell {
    
    lazy var titleBackgroundView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        view.alpha = 0.27
        return view
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    lazy var imageView: FLAnimatedImageView = {
        let imageView = FLAnimatedImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .lightGray
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = ""
        imageView.animatedImage = nil
        imageView.image = nil
        imageView.sd_cancelCurrentImageLoad()
    }
    
    private func commonInit() {
        addSubview(imageView)
        imageView.constrainToSuperview()
        
        addSubview(titleBackgroundView)
        titleBackgroundView.constrainTo(edges: .left, .bottom, .right)
        
        addSubview(titleLabel)
        titleLabel.constrainTo(edges: .left, .bottom, .right)
        
        // Make the faded background view the same height as the title label
        titleBackgroundView.constrain(attribute: .height, toItem: titleLabel, attribute: .height)
    }
}
