//
//  SectionBarView.swift
//  GameGether
//
//  Created by James Ajhar on 5/13/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

protocol SectionBarViewDelegate: class {
    func sectionBarView(view: SectionBarView, titleForTabAt index: Int) -> String
    func sectionBarView(view: SectionBarView, imageForTabAt index: Int) -> UIImage?
    func sectionBarView(view: SectionBarView, showNotificationForTabAt index: Int) -> Bool
    func sectionBarView(view: SectionBarView, didSelectTabAt index: Int)
}

extension SectionBarViewDelegate {
    // Optional
    func sectionBarView(view: SectionBarView, imageForTabAt index: Int) -> UIImage? { return nil }
    func sectionBarView(view: SectionBarView, showNotificationForTabAt index: Int) -> Bool { return false }
}

class SectionBarView: UIView {
    
    struct Constants {
        static let selectorViewMargins: CGFloat = 4.0
    }

    private let stackView: UIStackView = {
        let stack = UIStackView(frame: .zero)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fillEqually
        return stack
    }()
    
    private let dividerView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let selectorView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private var selectorViewLeftConstraint: NSLayoutConstraint?
    private var selectorViewWidthConstraint: NSLayoutConstraint?

    private var tabs = [SectionBarButtonView]()

    private(set) var selectedIndex: Int = 0
    
    weak var delegate: SectionBarViewDelegate?
    
    var numberOfTabs: Int = 1 {
        didSet {
            setupStackView()
        }
    }
    
    var colorScheme: UIColor = .black {
        didSet {
            updateColors()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        selectorViewWidthConstraint?.constant = (bounds.width / CGFloat(numberOfTabs)) - (Constants.selectorViewMargins * 2)
    }
    
    private func commonInit() {
        addSubview(stackView)
        stackView.constrainToSuperview()
        
        updateColors()
        
        // Add bottom selector view + divider
        addSubview(dividerView)
        dividerView.constrainTo(edges: .left, .right)
        dividerView.constrainHeight(1)
        
        addSubview(selectorView)
        selectorViewLeftConstraint = selectorView.constrainTo(edge: .left)
        selectorViewWidthConstraint = selectorView.constrainWidth(100)
        selectorView.constrainHeight(3)
        selectorView.constrainTo(edge: .bottom)
        
        // Constrain the divider view to the center of the selector toggle thingy
        dividerView.constrain(attribute: .centerY, toItem: selectorView, attribute: .centerY, relation: .equal)
    }
    
    private func setupStackView() {
        _ = stackView.arrangedSubviews.compactMap({ $0.removeFromSuperview() })
        
        tabs.removeAll()
        
        for index in 0..<numberOfTabs {
            let buttonView = SectionBarButtonView(frame: .zero)
           
            let image = delegate?.sectionBarView(view: self, imageForTabAt: index)
            buttonView.button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 15)
            buttonView.button.setImage(image, for: .normal)
            
            let title = delegate?.sectionBarView(view: self, titleForTabAt: index)
            buttonView.button.setTitle(title, for: .normal)
            buttonView.button.titleLabel?.font = AppConstants.Fonts.robotoBold(15).font
            
            buttonView.notificationView.isHidden = delegate?.sectionBarView(view: self, showNotificationForTabAt: index) == false

            buttonView.button.tintColor = .clear
            buttonView.setSelected(false)
            buttonView.button.tag = index
            buttonView.button.addTarget(self, action: #selector(buttonTapped(sender:)), for: .touchUpInside)
            stackView.addArrangedSubview(buttonView)
            tabs.append(buttonView)
        }
        
        layoutIfNeeded()

        selectTab(atIndex: selectedIndex, animated: false)
    }
    
    private func updateColors() {
        selectorView.backgroundColor = colorScheme
        dividerView.backgroundColor = colorScheme
    }
    
    @objc func buttonTapped(sender: UIButton) {
        selectTab(atIndex: sender.tag)
    }
    
    func selectTab(atIndex index: Int, animated: Bool = true) {
        guard index < tabs.count else { return }
        
        for i in 0..<tabs.count {
            tabs[i].setSelected(index == i)
            
            if index == i {
                // Move the selector over to this view
                if animated {
                    UIView.animate(withDuration: 0.3) {
                        self.selectorViewLeftConstraint?.constant = self.tabs[i].frame.minX + Constants.selectorViewMargins
                        self.layoutIfNeeded()
                    }
                } else {
                    selectorViewLeftConstraint?.constant = self.tabs[i].frame.minX + Constants.selectorViewMargins
                    layoutIfNeeded()
                }
            }
        }
        
        selectedIndex = index
        delegate?.sectionBarView(view: self, didSelectTabAt: index)
    }
    
    func refreshView() {
        setupStackView()
    }
}

private class SectionBarButtonView: UIView {
    
    private(set) var button: UIButton = {
        let button = UIButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = true
        return button
    }()
    
    private(set) var notificationView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.constrainWidth(12)
        view.constrainHeight(12)
        view.backgroundColor = .red
        view.cornerRadius = 6
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(button)
        button.constrainToCenter()
        button.constrainTo(edges: .top, .bottom)

        addSubview(notificationView)
        notificationView.constrain(attribute: .left, toItem: button, attribute: .right)?.constant = 5
        notificationView.constrain(attribute: .top, toItem: button, attribute: .top)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setSelected(_ isSelected: Bool) {
        if isSelected {
            button.setTitleColor(.black, for: .normal)
        } else {
            button.setTitleColor(UIColor(hexString: "#BDBDBD"), for: .normal)
        }
    }
}
