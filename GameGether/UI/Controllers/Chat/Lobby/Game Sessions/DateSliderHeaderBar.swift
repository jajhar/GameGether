//
//  DateSliderHeaderBar.swift
//  GameGether
//
//  Created by James Ajhar on 9/10/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class DateSliderHeaderBar: UIView {

    struct Constants {
        static let numberOfItems = 3
    }
    
    private let stackView: UIStackView = {
        let stack = UIStackView(frame: .zero)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        return stack
    }()
    
    private(set) var todayButton: UIButton?
    private(set) var tomorrowButton: UIButton?
    private(set) var moreButton: UIButton?

    private var selectorCenterXConstraint: NSLayoutConstraint?
    private let selector: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        return view
    }()
    
    var onTodayPressed: (() -> Void)?
    var onTomorrowPressed: (() -> Void)?
    var onMorePressed: (() -> Void)?
    
    var moreButtonTitle: String = "more" {
        didSet {
            moreButton?.setTitle(moreButtonTitle, for: .normal)
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
        
        addSubview(selector)
        selector.constrainTo(edges: .top, .bottom)
        selector.constrainWidth(bounds.width * 0.39)
        selector.cornerRadius = bounds.height / 2

        addSubview(stackView)
        stackView.constrainToSuperview()
        setupStackView()
        selectIndex(0)
    }
    
    private func setupStackView() {
        _ = stackView.arrangedSubviews.compactMap({ $0.removeFromSuperview() })
        
        for i in 0..<Constants.numberOfItems {
            
            let container = UIView(frame: .zero)
            container.translatesAutoresizingMaskIntoConstraints = false
            
            let button = UIButton(frame: .zero)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.titleLabel?.font = AppConstants.Fonts.robotoMedium(12).font
            button.setTitleColor(.black, for: .normal)
            
            let leftDivider = UIView(frame: .zero)
            leftDivider.translatesAutoresizingMaskIntoConstraints = false
            leftDivider.backgroundColor = .black
            leftDivider.constrainHeight(1)
            
            let rightDivider = UIView(frame: .zero)
            rightDivider.translatesAutoresizingMaskIntoConstraints = false
            rightDivider.backgroundColor = .black
            rightDivider.constrainHeight(1)

            switch i {
            case 0:
                // today
                button.setTitle("Today", for: .normal)
                button.addTarget(self, action: #selector(todayPressed(_:)), for: .touchUpInside)
                todayButton = button
            case 1:
                // tomorrow
                button.setTitle("Tmrw", for: .normal)
                button.addTarget(self, action: #selector(tomorrowPressed(_:)), for: .touchUpInside)
                tomorrowButton = button
            case 2:
                // more
                button.setTitle(moreButtonTitle, for: .normal)
                button.addTarget(self, action: #selector(morePressed(_:)), for: .touchUpInside)
                moreButton = button
            default:
                continue
            }
            
            container.addSubview(button)
            button.constrainToCenter()
            button.constrainTo(edges: .top, .bottom)
            
            container.addSubview(leftDivider)
            leftDivider.constrainToCenterVertical()
            leftDivider.constrainTo(edge: .left)
            leftDivider.constrain(attribute: .right, toItem: button, attribute: .left)?.constant = -14

            container.addSubview(rightDivider)
            rightDivider.constrainToCenterVertical()
            rightDivider.constrainTo(edge: .right)
            rightDivider.constrain(attribute: .left, toItem: button, attribute: .right)?.constant = 14
            
            stackView.addArrangedSubview(container)
        }
        
        layoutIfNeeded()
    }
    
    private func selectIndex(_ index: UInt) {
        guard index < Constants.numberOfItems else { return }
        guard let todayButton = todayButton, let tomorrowButton = tomorrowButton, let moreButton = moreButton else { return }

        if let constraint = selectorCenterXConstraint {
            removeConstraint(constraint)
        }
        
        todayButton.setTitleColor(.black, for: .normal)
        tomorrowButton.setTitleColor(.black, for: .normal)
        moreButton.setTitleColor(.black, for: .normal)

        switch index {
        case 0:
            // today
            selectorCenterXConstraint = selector.constrain(attribute: .centerX, toItem: todayButton, attribute: .centerX)
            todayButton.setTitleColor(.white, for: .normal)
        case 1:
            // tomorrow
            selectorCenterXConstraint = selector.constrain(attribute: .centerX, toItem: tomorrowButton, attribute: .centerX)
            tomorrowButton.setTitleColor(.white, for: .normal)
        case 2:
            // more
            selectorCenterXConstraint = selector.constrain(attribute: .centerX, toItem: moreButton, attribute: .centerX)
            moreButton.setTitleColor(.white, for: .normal)
        default:
            break
        }
        
//        selectorCenterXConstraint?.priority = .defaultLow
        
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }
    // MARK: - Interface Actions
    
    @objc func todayPressed(_ sender: UIButton) {
        selectIndex(0)
        onTodayPressed?()
    }
    
    @objc func tomorrowPressed(_ sender: UIButton) {
        selectIndex(1)
        onTomorrowPressed?()
    }

    @objc func morePressed(_ sender: UIButton) {
        selectIndex(2)
        onMorePressed?()
    }
}
