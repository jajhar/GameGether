//
//  ProfileGamesCollectionReusableView.swift
//  GameGether
//
//  Created by James Ajhar on 5/30/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class ProfileGamesCollectionReusableView: UICollectionReusableView {
    
    lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "your games"
        label.font = AppConstants.Fonts.robotoMedium(15).font
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        titleLabel.constrainTo(edge: .left)?.constant = 15
        titleLabel.constrainTo(edge: .right)?.constant = 15
        titleLabel.constrainTo(edges: .top, .bottom)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
