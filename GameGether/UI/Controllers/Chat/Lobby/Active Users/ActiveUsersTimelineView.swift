//
//  ActiveUsersTimelineView.swift
//  GameGether
//
//  Created by James Ajhar on 7/7/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class ActiveUsersTimelineView: UIView {

    enum ActiveUsersTimelineViewState {
        case currentlyInLobby
        case recentlyInLobby
    }
    
    // MARK: - Properties
    
    let avatarsView: HorizontalAvatarsView = {
        let view = HorizontalAvatarsView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alignment = .right
        view.spacing = -10 // overlap the views
        view.showRemainingUserCounter = true
        view.maxVisibleUsers = 4
        return view
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "currently in lobby"
        label.font = AppConstants.Fonts.robotoMedium(12).font
        label.textColor = .white
        return label
    }()
    
    lazy var titleLabelContainerView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(hexString: "#7AD088")
        view.borderColor = UIColor(hexString: "#7AD088")
        view.borderWidth = 1
        view.clipsToBounds = true
        view.isHidden = true

        view.addSubview(titleLabel)
        titleLabel.constrainTo(edges: .top, .bottom)
        titleLabel.constrainTo(edge: .left)?.constant = 12
        titleLabel.constrainTo(edge: .right)?.constant = -(5 + bounds.height)
        return view
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
        
        addSubview(titleLabelContainerView)
        titleLabelContainerView.constrainHeight(27)
        titleLabelContainerView.constrainToCenterVertical()
        titleLabelContainerView.constrain(attribute: .right, toItem: avatarsView, attribute: .left, relation: .equal, constant: bounds.height)
        titleLabelContainerView.cornerRadius = 27 / 2
        
        addSubview(avatarsView)
        avatarsView.constrainTo(edges: .top, .right, .bottom)   // width handles itself
    }
    
    func set(state: ActiveUsersTimelineViewState) {
//        titleLabel.fadeTransition(0.2)
//        titleLabelContainerView.fadeTransition(0.2)
        
        titleLabel.text = state == .currentlyInLobby ? "currently in lobby" : "recently in lobby"
        titleLabel.textColor = state == .currentlyInLobby ? .white : UIColor(hexString: "#7AD088")
        titleLabelContainerView.backgroundColor = state == .currentlyInLobby ? UIColor(hexString: "#7AD088") : .white
    }
    
    func configure(withUsers users: [User]) {
        avatarsView.fadeTransition(0.4)
        avatarsView.users = users
        
        titleLabelContainerView.fadeTransition(0.4)
        titleLabelContainerView.isHidden = users.count == 0
        layoutIfNeeded()
    }
}
