//
//  GameSessionHeaderCollectionReusableView.swift
//  GameGether
//
//  Created by James Ajhar on 9/11/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class GameSessionHeaderCollectionReusableView: UICollectionReusableView {
    
    let titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = AppConstants.Fonts.robotoMedium(20).font
        return label
    }()
    
    let subtitleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = AppConstants.Fonts.robotoRegular(16).font
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        setTitle(nil)
    }
    
    private func commonInit() {
        let stack = UIStackView(frame: .zero)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(subtitleLabel)
        stack.spacing = 2
        
        addSubview(stack)
        stack.constrainTo(edge: .bottom)
        stack.constrainTo(edge: .left)?.constant = 8
        layoutIfNeeded()
    }
    
    public func setTitle(_ title: String?, subtitle: String? = nil) {
        subtitleLabel.isHidden = subtitle == nil
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }
}
