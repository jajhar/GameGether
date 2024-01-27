//
//  GameSessionCollectionViewCell.swift
//  GameGether
//
//  Created by James Ajhar on 10/1/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class GameSessionCollectionViewCell: UICollectionViewCell {
    
    let sessionView: GameSessionView = {
        let view = UINib(nibName: "\(GameSessionView.self)", bundle: nil).instantiate(withOwner: self, options: nil).first as! GameSessionView
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.addSubview(sessionView)
        sessionView.constrainToSuperview()
        contentView.layoutIfNeeded()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(sessionView)
        sessionView.constrainToSuperview()
        contentView.layoutIfNeeded()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        sessionView.prepareForReuse()
    }
}
