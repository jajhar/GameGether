//
//  GameSessionGroupCollectionViewCell.swift
//  GameGether
//
//  Created by James Ajhar on 12/9/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class GameSessionGroupCollectionViewCell: UICollectionViewCell {
    
    let sessionView: GameSessionGroupView = {
        let view = UINib(nibName: "\(GameSessionGroupView.self)", bundle: nil).instantiate(withOwner: self, options: nil).first as! GameSessionGroupView
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.addSubview(sessionView)
        sessionView.constrainToSuperview()
        contentView.layoutIfNeeded()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        sessionView.prepareForReuse()
    }
}
