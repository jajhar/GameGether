//
//  AddGameCollectionViewCell.swift
//  GameGether
//
//  Created by James Ajhar on 7/16/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class AddGameCollectionViewCell: UICollectionViewCell {
    
    let addGameImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.constrainWidth(60)
        imageView.constrainHeight(60)
        imageView.contentMode = .scaleAspectFit
        imageView.image = #imageLiteral(resourceName: "AddGameRound")
        return imageView
    }()
    
    let titleLabel: UILabel = {
        let titleLabel = UILabel(frame: .zero)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Add Game"
        titleLabel.font = AppConstants.Fonts.robotoMedium(14).font
        titleLabel.textColor = UIColor(hexString: "#3399FF")
        return titleLabel
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        
        contentView.addSubview(addGameImageView)
        addGameImageView.constrainTo(edge: .left)
        addGameImageView.constrainTo(edges: .top, .bottom)
        
        contentView.addSubview(titleLabel)
        titleLabel.constrain(attribute: .left, toItem: addGameImageView, attribute: .right, constant: 14)
        titleLabel.constrainToCenterVertical()
        
        contentView.layoutIfNeeded()
    }
}
