//
//  GGHUDView.swift
//  GameGether
//
//  Created by James Ajhar on 9/16/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class GGHUDView: UIView {
    
    static private var presentedView: GGHUDView?

    private let textLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = AppConstants.Fonts.robotoMedium(17).font
        label.textAlignment = .center
        return label
    }()
    
    private let subTextLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = AppConstants.Fonts.robotoRegular(14).font
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    static func show(withText text: String,
                     subText: String? = nil,
                     textColor: UIColor = .black,
                     backgroundColor: UIColor = .white,
                     duration: TimeInterval = 1,
                     _ completion: (() -> Void)? = nil) {
        
        let view = GGHUDView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.textLabel.text = text
        view.textLabel.textColor = textColor
        view.subTextLabel.text = subText
        view.subTextLabel.textColor = textColor
        view.backgroundColor = backgroundColor
        
        // Add view to window
        NavigationManager.shared.window?.addSubview(view)
        view.constrainToCenter()
        NavigationManager.shared.window?.layoutIfNeeded()
        
        GGHUDView.presentedView?.removeFromSuperview()
        GGHUDView.presentedView = view
        
        Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { (_) in
            UIView.animate(withDuration: 0.3, animations: {
                view.alpha = 0
            }, completion: { (_) in
                GGHUDView.presentedView = nil
                view.removeFromSuperview()
                completion?()
            })
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
        addSubview(textLabel)
        textLabel.constrainTo(edge: .left)?.constant = 10
        textLabel.constrainTo(edge: .right)?.constant = -10
        textLabel.constrainTo(edge: .top)?.constant = 10
        
        addSubview(subTextLabel)
        subTextLabel.constrainTo(edge: .left)?.constant = 10
        subTextLabel.constrainTo(edge: .right)?.constant = -10
        subTextLabel.constrainTo(edge: .bottom)?.constant = -10
        subTextLabel.constrain(attribute: .top, toItem: textLabel, attribute: .bottom, relation: .equal, constant: 0)

        clipsToBounds = true
        cornerRadius = 7
        
        layoutIfNeeded()
    }
}
