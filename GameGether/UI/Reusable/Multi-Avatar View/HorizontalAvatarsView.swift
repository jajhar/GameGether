//
//  HorizontalAvatarsView.swift
//  GameGether
//
//  Created by James Ajhar on 10/30/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

class HorizontalAvatarsView: UIView {
    
    enum HorizontalAvatarsViewAlignment {
        case left
        case right
    }
    
    enum HorizontalAvatarsViewLayoutZIndex {
        case topDown
        case bottomUp
    }
    
    // MARK: Views
    
    lazy var remainingUserCountLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = AppConstants.Fonts.robotoRegular(12).font
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = UIColor(displayP3Red: 82/255, green: 82/255, blue: 82/255, alpha: 0.55)
        label.cornerRadius = bounds.height / 2
        label.clipsToBounds = true
        return label
    }()
    
    private var imageViews = [UIImageView]()
    
    // MARK: Properties
    
    var alignment: HorizontalAvatarsViewAlignment = .right
    var zIndexAlignment: HorizontalAvatarsViewLayoutZIndex = .topDown

    var spacing: CGFloat = 0.0

    var users = [User]() {
        didSet {
            layoutImages()
        }
    }
    
    var onAddUserButtonPressed: (() -> Void)?
    
    var maxVisibleUsers: UInt?
    
    var showAddUserButton: Bool = false {
        didSet {
            layoutImages()
        }
    }
    
    var showRemainingUserCounter: Bool = false {
        didSet {
            layoutImages()
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
        // NOP
    }
    
    func prepareForReuse() {
        _ = subviews.map({ $0.removeFromSuperview() })
        _ = imageViews.map({ $0.removeFromSuperview() })
        imageViews.removeAll()
    }
    
    private func imageView(user: User, size: CGFloat) -> AvatarInitialsImageView {
        let view = AvatarInitialsImageView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        view.backgroundColor = .lightGray
        view.constrainWidth(size)
        view.constrainHeight(size)
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor(hexString: "#ACACAC").cgColor

        user.observeStatus { (newStatus, _) in
            switch newStatus {
            case .online:
                view.layer.borderColor = UIColor(hexString: "#7AD088").cgColor
            case .away:
                view.layer.borderColor = UIColor(hexString: "#F3CA3E").cgColor
            case .offline:
                view.layer.borderColor = UIColor(hexString: "#ACACAC").cgColor
            }
        }

        view.image = #imageLiteral(resourceName: "Pastel Green #66CC33")
        view.layer.cornerRadius = size / 2
        view.configure(withUser: user, andFont: AppConstants.Fonts.robotoRegular(16).font)
        
        return view
    }
    
    private func layoutImages() {
        prepareForReuse()
        
        var offset: CGFloat = 0
        for (index, user) in users.enumerated() {
            
            if let maxVisibleUsers = maxVisibleUsers {
                guard index < maxVisibleUsers else { break }
            }
            
            let imageView = self.imageView(user: user, size: bounds.height)
            addSubview(imageView)
            imageViews.append(imageView)
            imageView.constrainToCenterVertical()
            
            if alignment == .right {
                imageView.constrainTo(edge: .right)?.constant = offset
                offset -= (bounds.height + spacing)
            } else {
                imageView.constrainTo(edge: .left)?.constant = offset
                offset += (bounds.height + spacing)
            }
            
            
            var remainingUserCount = users.count - Int(maxVisibleUsers ?? 0)
            remainingUserCount = remainingUserCount < 0 ? 0 : remainingUserCount

            if index == 0, showRemainingUserCounter, alignment == .right, remainingUserCount > 0 {
                addSubview(remainingUserCountLabel)
                remainingUserCountLabel.constrain(attribute: .centerX, toItem: imageView, attribute: .centerX)
                remainingUserCountLabel.constrain(attribute: .centerY, toItem: imageView, attribute: .centerY)
                remainingUserCountLabel.constrain(attribute: .width, toItem: imageView, attribute: .width)
                remainingUserCountLabel.constrain(attribute: .height, toItem: imageView, attribute: .height)
                remainingUserCountLabel.text = "+\(remainingUserCount)"
                
            } else if index == users.count-1, showRemainingUserCounter, alignment == .left  {
                addSubview(remainingUserCountLabel)
                remainingUserCountLabel.constrain(attribute: .centerX, toItem: imageView, attribute: .centerX)
                remainingUserCountLabel.constrain(attribute: .centerY, toItem: imageView, attribute: .centerY)
                remainingUserCountLabel.constrain(attribute: .width, toItem: imageView, attribute: .width)
                remainingUserCountLabel.constrain(attribute: .height, toItem: imageView, attribute: .height)
                remainingUserCountLabel.text = "+\(remainingUserCount)"
            }
            
            if zIndexAlignment == .topDown {
                sendSubviewToBack(imageView)
            }
        }
        
        if !showAddUserButton {
            // constrain the last image to the opposite edge of the view to finish
            imageViews.last?.constrainTo(edge: alignment == .right ? .left : .right)
        }
        
        if showAddUserButton {
            let button = UIButton(frame: .zero)
            button.translatesAutoresizingMaskIntoConstraints = false
            addSubview(button)
            sendSubviewToBack(button)
            button.constrainWidth(bounds.height)
            button.constrainHeight(bounds.height)
            button.constrainToCenterVertical()
            button.setImage(#imageLiteral(resourceName: "DottedJoinParty"), for: .normal)
            button.addTarget(self, action: #selector(addUserButtonPressed(sender:)), for: .touchUpInside)
            
            if alignment == .right {
                button.constrainTo(edge: .right)?.constant = offset
                offset -= (bounds.height + spacing)
            } else {
                button.constrainTo(edge: .left)?.constant = offset
                offset += (bounds.height + spacing)
            }
            
            // constrain to the opposite edge of the view to finish
            button.constrainTo(edge: alignment == .right ? .left : .right)
        }
        
        layoutIfNeeded()
    }
    
    @objc func addUserButtonPressed(sender: UIButton) {
        onAddUserButtonPressed?()
    }
    
    public func bringUserToFront(userId: String, animated: Bool = false) {
        guard let user = users.filter({ $0.identifier == userId }).first else { return }
        users.removeUser(user)
        users.insert(user, at: 0)
        
        if animated {
            fadeTransition(0.4)
        }
        
        layoutImages()
    }
    
    public func pushUserToBack(userId: String, animated: Bool = false) {
        guard let user = users.filter({ $0.identifier == userId }).first else { return }
        users.removeUser(user)
        users.append(user)
        
        if animated {
            fadeTransition(0.4)
        }
        
        layoutImages()
    }
}
