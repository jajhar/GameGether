//
//  PartyFilledMessageTableViewCell.swift
//  GameGether
//
//  Created by James Ajhar on 7/9/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class PartyFilledMessageTableViewCell: UITableViewCell {

    let titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = AppConstants.Fonts.robotoRegular(14).font
        label.textColor = UIColor(hexString: "#ACACAC")
        return label
    }()
    
    let containerView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(hexString: "#F2F2F2")
        view.clipsToBounds = true
        view.cornerRadius = 12
        view.constrainHeight(46)
        return view
    }()
    
    let avatarsView: HorizontalAvatarsView = {
        let view = HorizontalAvatarsView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.constrainHeight(30)
        view.alignment = .right
        view.spacing = -10
        view.showRemainingUserCounter = true
        view.maxVisibleUsers = 4
        return view
    }()

    var message: FRMessage? {
        didSet {
            setupWithMessage()
        }
    }
    
    private var refreshTimer: Timer?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        contentView.addSubview(containerView)
        containerView.constrainTo(edge: .right)?.constant = -10
        containerView.constrainTo(edge: .top)?.constant = 6
        containerView.constrainTo(edge: .bottom)?.constant = -10

        containerView.addSubview(titleLabel)
        titleLabel.constrainTo(edges: .top, .bottom)
        titleLabel.constrainTo(edge: .left)?.constant = 14
        
        containerView.addSubview(avatarsView)
        avatarsView.constrainTo(edge: .right)?.constant = -9
        avatarsView.constrainToCenterVertical()
        
        titleLabel.constrain(attribute: .right, toItem: avatarsView, attribute: .left, constant: -14)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarsView.prepareForReuse()
        titleLabel.text = nil
        resetTimer()
    }
    
    private func resetTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func setupWithMessage() {
        guard let message = message else { return }
        
        switch message.type {
        case .createdPartyNotification:
            
            updateTimeLabel()
            resetTimer()
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] (_) in
                self?.updateTimeLabel()
            })
            
            fetchUsers()
        default:
            break
        }
        
        contentView.layoutIfNeeded()
    }
    
    private func updateTimeLabel() {
        guard let message = message else { return }
        titleLabel.text = "\(message.text) \(message.createdAt.partyCreatedTimestampFormat())"
    }

    private func fetchUsers() {
        guard let message = message, message.userIds.count > 0 else { return }
        
        DataCoordinator.shared.getProfiles(forUsersWithIds: message.userIds) { [weak self] (userProfiles, error) in
            guard let weakSelf = self, weakSelf.message?.identifier == message.identifier else { return }
            guard error == nil, let userProfiles = userProfiles else {
                GGLog.error("\(error?.localizedDescription ?? "unknown error")")
                return
            }
            
            performOnMainThread {
                weakSelf.avatarsView.users = userProfiles
            }
        }
    }
}
