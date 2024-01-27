//
//  GameTagReusableSectionHeaderView.swift
//  GameGether
//
//  Created by James Ajhar on 9/8/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

class GameTagReusableSectionHeaderView: UICollectionReusableView {
    
    // MARK: Properties
    let titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = AppConstants.Fonts.robotoBold(16).font
        label.textColor = UIColor(hexString: "#BDBDBD")
        return label
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
        addSubview(titleLabel)
        titleLabel.constrainTo(edge: .left)?.constant = 9
        titleLabel.constrainTo(edges: .top, .right, .bottom)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = ""
    }
}
