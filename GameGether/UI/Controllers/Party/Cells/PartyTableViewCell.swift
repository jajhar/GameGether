//
//  PartyTableViewCell.swift
//  GameGether
//
//  Created by James Ajhar on 10/28/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

class PartyTableViewCell: UITableViewCell {
   
    struct Constants {
        static let joinButtonSelectedInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 25)
        static let joinButtonUnselectedInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    }
    
    // MARK: Outlets
    @IBOutlet weak var backgroundBorderView: UIView! {
        didSet {
            backgroundBorderView.cornerRadius = 10
            backgroundBorderView.borderWidth = 1
            backgroundBorderView.borderColor = UIColor(hexString: "#ACACAC")
        }
    }
    
    @IBOutlet weak var horizontalAvatarsView: HorizontalAvatarsView! {
        didSet {
            horizontalAvatarsView.alignment = .left
            horizontalAvatarsView.isUserInteractionEnabled = true
            horizontalAvatarsView.spacing = -10
            
            horizontalAvatarsView.onAddUserButtonPressed = { [weak self] in
                guard let party = self?.party else { return }
                self?.togglePartyButton(selected: true)
                self?.onJoinPartyButtonTapped?(party)
            }
        }
    }
    
    @IBOutlet weak var joinButton: UIButton! {
        didSet {
            joinButton.titleLabel?.font = AppConstants.Fonts.robotoMedium(13).font
            joinButton.setTitle("join now", for: .normal)
            joinButton.setTitleColor(.black, for: .normal)
            joinButton.setBackgroundColor(color: .white, forState: .normal)
        }
    }
    
    @IBOutlet weak var leavePartyButton: UIButton!
    
    // MARK: Properties
    var party: FRParty? {
        didSet {
            setupWithParty()
        }
    }
    
    var onJoinPartyButtonTapped: ((FRParty) -> Void)?
    var onLeavePartyButtonTapped: ((FRParty) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        
        horizontalAvatarsView.prepareForReuse()
        leavePartyButton.isHidden = false
    }
    
    private func setupWithParty() {
        guard let party = party else { return }
        
        leavePartyButton.isHidden = !party.containsLoggedInUser
        horizontalAvatarsView.showAddUserButton = !party.containsLoggedInUser

        if party.containsLoggedInUser {
            joinButton.isSelected = true
        } else {
            joinButton.isSelected = false
        }
        
        togglePartyButton(selected: joinButton.isSelected)

        party.fetchUsers { [weak self] (users) in
            guard party.identifier == self?.party?.identifier else { return }   // async reuse check
            performOnMainThread {
                self?.horizontalAvatarsView.users = users ?? []
            }
        }
        
        let sizeTag = party.tags.sizeTags().first
        joinButton.setTitle("\(sizeTag?.title ?? "") party", for: .normal)

        animateJoinButtonTitle()
        
        layoutIfNeeded()
    }

    func togglePartyButton(selected: Bool) {
        joinButton.isSelected = selected
        
        if selected {
            // in-party state
            joinButton.isEnabled = false
            joinButton.setTitleColor(.white, for: .normal)
            joinButton.borderWidth = 0
            joinButton.setBackgroundColor(color: UIColor(hexString: "#7AD088"), forState: .normal)
            joinButton.contentEdgeInsets = Constants.joinButtonSelectedInsets
            joinButton.cornerRadius = 0
            joinButton.roundCorners(corners: [.topLeft, .bottomLeft], radius: 8)
            
        } else {
            // out-of-party state
            joinButton.isEnabled = true
            joinButton.setTitleColor(.black, for: .normal)
            joinButton.borderWidth = 1
            joinButton.borderColor = .black
            joinButton.setBackgroundColor(color: .white, forState: .normal)
            joinButton.contentEdgeInsets = Constants.joinButtonUnselectedInsets
            joinButton.cornerRadius = 8
        }
    }
    
    /// Absolute garbage implementation of animated titles - OMG
    private func animateJoinButtonTitle() {
        
        joinButton.layer.removeAllAnimations()
        joinButton.titleLabel?.layer.removeAllAnimations()
        
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       options: [.allowUserInteraction],
                       animations: {
                        self.joinButton.titleLabel?.alpha = 1
        }, completion: { [weak self] (finished) in
            guard finished else { return }
            
            UIView.animate(withDuration: 1.0,
                           delay: 0,
                           options: [.allowUserInteraction],
                           animations: {
                            self?.joinButton.titleLabel?.alpha = 0
            }, completion: { [weak self] (finished) in
                guard finished else { return }
                
                self?.animateJoinButtonTitleReverse()
            })
        })
    }
    
    private func animateJoinButtonTitleReverse() {

        joinButton.layer.removeAllAnimations()
        joinButton.titleLabel?.layer.removeAllAnimations()

        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       options: [.allowUserInteraction],
                       animations: {
                        self.joinButton.titleLabel?.alpha = 1
        }, completion: { [weak self] (finished) in
            guard finished else { return }
            
            UIView.animate(withDuration: 1.0,
                           delay: 0,
                           options: [.allowUserInteraction],
                           animations: {
                            self?.joinButton.titleLabel?.alpha = 0
            }, completion: { [weak self] (finished) in
                guard finished else { return }
                
                self?.animateJoinButtonTitle()
            })
        })
    }

    // MARK: Interface Actions
    
    @IBAction func joinPartyButtonPressed(_ sender: UIButton) {
        guard let party = party else { return }
        
        let isSelected = sender.isSelected
        togglePartyButton(selected: !isSelected)

        if !isSelected {
            onJoinPartyButtonTapped?(party)
        }
    }
    
    @IBAction func leavePartyButtonPressed(_ sender: UIButton) {
        guard let party = party else { return }
        onLeavePartyButtonTapped?(party)
    }
}
