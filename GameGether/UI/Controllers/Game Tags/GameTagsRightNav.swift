//
//  GameTagsRightNav.swift
//  GameGether
//
//  Created by James Ajhar on 2/21/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import Foundation
import UIKit

class GameTagsRightNav: UIView {
    
    // MARK: Properties
    var selectedIndex: Int = 0
    
    private let stackView: UIStackView = {
        let stack = UIStackView(frame: .zero)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()
    
    private let scrollView: UIScrollView = {
        let view = UIScrollView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.showsVerticalScrollIndicator = false
        return view
    }()
    
    private lazy var homeButton: GameTagRightNavButton = {
        let button = GameTagRightNavButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.imageView.image = #imageLiteral(resourceName: "TagHome - Right Nav")
        button.button.addTarget(self, action: #selector(homeButtonTapped(button:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var chatButton: GameTagRightNavButton = {
        let button = GameTagRightNavButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.imageView.image = #imageLiteral(resourceName: "TagChat - Right Nav")
        button.button.addTarget(self, action: #selector(chatButtonTapped(button:)), for: .touchUpInside)
        return button
    }()
    
    var onHomeSelected: (() -> Void)?
    var onChatSelected: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        addSubview(scrollView)
        scrollView.constrainToSuperview()
        
        let container = UIView(frame: .zero)
        container.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(container)
        container.constrainToSuperview()
        container.constrainToCenterHorizontal()
        container.constrain(attribute: .width, toItem: scrollView, attribute: .width)
        
        container.addSubview(stackView)
        stackView.constrainTo(edge: .right)                 // right side has no drop shadow
        stackView.constrainTo(edge: .left)?.constant = 2    // leave 2 point space for the drop shadow
        stackView.constrainTo(edge: .top)?.constant = 2     // leave 2 point space for the drop shadow
        stackView.constrainTo(edge: .bottom)?.constant = 2  // leave 2 point space for the drop shadow
        layoutIfNeeded()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layoutIfNeeded()
        setupStackView()
    }
    
    @objc func homeButtonTapped(button: UIButton? = nil) {
        selectButton(atIndex: 0)
    }
    
    @objc func chatButtonTapped(button: UIButton? = nil) {
        selectButton(atIndex: 1)
    }

    private func setupStackView() {
        _ = stackView.arrangedSubviews.compactMap({ $0.removeFromSuperview() })
        
        // Add the home button
        stackView.addArrangedSubview(homeButton)
        homeButton.constrainHeight(stackView.bounds.width)
        homeButton.setSelected(true)    // home button selected by default
        
        // Add the chat button
        stackView.addArrangedSubview(chatButton)
        chatButton.constrainHeight(stackView.bounds.width)

        layoutIfNeeded()
    }
    
    func selectButton(atIndex index: Int) {
        selectedIndex = index
        
        switch index {
        case 0:
            homeButton.setSelected(true)
            chatButton.setSelected(false)
            onHomeSelected?()
        case 1:
            homeButton.setSelected(false)
            chatButton.setSelected(true)
            onChatSelected?()
        default:
            break
        }
    }
}

private class GameTagRightNavButton: UIView {
    
    let imageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let button: UIButton = {
        let button = UIButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let roundedBackgroundView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        view.layer.cornerRadius = 10
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        view.backgroundColor = .clear
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(roundedBackgroundView)
        roundedBackgroundView.constrainToSuperview()
        
        addSubview(imageView)
        imageView.constrainToCenter()
        
        addSubview(button)
        button.constrainToSuperview()
        
        addDropShadow(color: .black, opacity: 0.22, radius: 2)
        
        setSelected(false)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setSelected(_ isSelected: Bool) {
        if isSelected {
            roundedBackgroundView.backgroundColor = UIColor(hexString: "#F4F4F4")
            imageView.alpha = 1.0
        } else {
            roundedBackgroundView.backgroundColor = .clear
            imageView.alpha = 0.3
        }
    }
}
