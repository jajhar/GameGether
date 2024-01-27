//
//  SocialIconStackView.swift
//  GameGether
//
//  Created by James Ajhar on 6/3/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class SocialIconStackView: UIStackView {

    var socialLinks: [SocialLink] = [] {
        didSet {
            setupStackView()
        }
    }
    
    var showAllLinkTypes: Bool = false {
        didSet {
            setupStackView()
        }
    }
    
    private var socialLinkButtons = [SocialLinkbutton]()
    
    var onSocialLinkTapped: ((SocialLink) -> Void)?
    
    private func setupStackView() {
        _ = arrangedSubviews.compactMap({ $0.removeFromSuperview() })
        
        var socialLinks = self.socialLinks
        
        if showAllLinkTypes {
            for type in SocialLinkType.allTypes {
                guard socialLinks.filter({ $0.type == type }).first == nil else { continue }
                // Add a dummy link to show as unselected
                let dummyLink = SocialLink(type: type, username: "")
                socialLinks.append(dummyLink)
            }
        }
        
        // Add the user's social links
        for (_, link) in socialLinks.enumerated() {
            let button = SocialLinkbutton(frame: .zero)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.socialLink = link
            socialLinkButtons.append(button)
            button.addTarget(self, action: #selector(linkButtonTapped(button:)), for: .touchUpInside)
            addArrangedSubview(button)
        }
        
        layoutIfNeeded()
    }

    @objc func linkButtonTapped(button: SocialLinkbutton) {
        guard let link = button.socialLink else { return }
        
        onSocialLinkTapped?(link)
    }
}

class SocialLinkbutton: UIButton {
    
    var socialLink: SocialLink? {
        didSet {
            setupWithSocialLink()
        }
    }
    
    private func setupWithSocialLink() {
        guard let link = socialLink else { return }
        
        switch link.type {
        case .twitter:
            setImage(#imageLiteral(resourceName: "TwitterLink"), for: .normal)
        case .instagram:
            setImage(#imageLiteral(resourceName: "InstagramLink"), for: .normal)
        case .facebook:
            setImage(#imageLiteral(resourceName: "FacebookLink"), for: .normal)
        case .twitch:
            setImage(#imageLiteral(resourceName: "TwitchLink"), for: .normal)
        case .youtube:
            setImage(#imageLiteral(resourceName: "YouTubeLink"), for: .normal)
        }
        
        // unselected state
        alpha = link.username.isEmpty ? 0.5 : 1.0
    }
}
