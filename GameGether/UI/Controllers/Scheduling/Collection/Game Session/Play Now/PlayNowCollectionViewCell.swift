//
//  PlayNowCollectionViewCell.swift
//  GameGether
//
//  Created by James Ajhar on 11/1/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class PlayNowCollectionViewCell: UICollectionViewCell {
    
    let playNowView: PlayNowCellView = {
        let view = UINib(nibName: "\(PlayNowCellView.self)", bundle: nil).instantiate(withOwner: self, options: nil).first as! PlayNowCellView
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.addSubview(playNowView)
        playNowView.constrainToSuperview()
        contentView.layoutIfNeeded()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        playNowView.prepareForReuse()
    }
}
