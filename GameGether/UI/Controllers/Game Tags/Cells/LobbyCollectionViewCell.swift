//
//  LobbyCollectionViewCell.swift
//  GameGether
//
//  Created by James Ajhar on 6/9/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class LobbyCollectionViewCell: UICollectionViewCell {

    // MARK: Outlets
    @IBOutlet weak var wrapperView: UIView!
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var lobbyImageView: UIImageView!
    
    @IBOutlet weak var horizontalAvatarsView: HorizontalAvatarsView! {
        didSet {
            horizontalAvatarsView.spacing = -10 // overlap the views
            horizontalAvatarsView.maxVisibleUsers = 4
            horizontalAvatarsView.backgroundColor = .clear
        }
    }
    
    private(set) var isTagSelected: Bool = false
    
    private let firebaseChat: FirebaseChat = {
        let chat = FirebaseChat()
        chat.signIn()
        return chat
    }()
    
    var tagGroup: TagsGroup? {
        didSet {
            setupWithTagGroup()
        }
    }
    
    var themeColor: UIColor = AppConstants.Colors.tagPillColor.color {
        didSet {
            wrapperView.layer.borderColor = themeColor.cgColor
            setSelected(isTagSelected)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        tagLabel.text = nil
        setSelected(false)
        horizontalAvatarsView.users = []
        tagGroup = nil
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        styleUI()
        
        wrapperView.clipsToBounds = true
        wrapperView.layer.cornerRadius = 11
        wrapperView.layer.borderColor = themeColor.cgColor
        wrapperView.layer.borderWidth = 1
        
        // These two lines fix an auto resizing bug...
        // https://stackoverflow.com/questions/25804588/auto-layout-in-uicollectionviewcell-not-working
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    private func styleUI() {
        tagLabel.font = AppConstants.Fonts.robotoBold(14).font
        tagLabel.textColor = themeColor
        lobbyImageView.tintColor = themeColor
        wrapperView.backgroundColor = .white
    }

    func setupWithTagGroup() {
        guard let tagGroup = tagGroup else { return }
        
        tagLabel.text = tagGroup.tags.compactMap({ $0.title }).joined(separator: " ")
        horizontalAvatarsView.prepareForReuse()    // reset state
        
        firebaseChat.observeUsers(forGame: tagGroup.gameId, withTags: tagGroup.tags, limit: 10) { [weak self] (activeUsers, _) in
            self?.horizontalAvatarsView.prepareForReuse()    // reset state

            guard activeUsers.count > 0 else { return }
            DataCoordinator.shared.getProfiles(forUsersWithIds: activeUsers.compactMap({ $0.identifier }), completion: { (remoteUsers, error) in
                guard self?.tagGroup?.identifier == tagGroup.identifier else { return }
                self?.horizontalAvatarsView.users = remoteUsers ?? []
            })
        }
        
        layoutIfNeeded()
    }
    
    func setSelected(_ isSelected: Bool) {
        isTagSelected = isSelected
        if isSelected {
            tagLabel.textColor = .white
            lobbyImageView.tintColor = .white
            wrapperView.backgroundColor = themeColor
        } else {
            tagLabel.textColor = themeColor
            lobbyImageView.tintColor = themeColor
            wrapperView.backgroundColor = .white
        }
    }
}
