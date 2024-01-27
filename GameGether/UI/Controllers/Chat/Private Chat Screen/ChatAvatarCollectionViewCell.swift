//
//  ChatAvatarCollectionViewCell.swift
//  GameGether
//
//  Created by James Ajhar on 8/8/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit
import FLAnimatedImage

class ChatAvatarCollectionViewCell: UICollectionViewCell {
    
    // MARK: Properties
    let imageView: AvatarInitialsImageView = {
        let view = AvatarInitialsImageView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    let chatIndicatorAnimatedImageView: FLAnimatedImageView = {
        let view = FLAnimatedImageView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = false
        view.contentMode = .scaleAspectFill
        view.alpha = 0
        
        if let path = Bundle.main.url(forResource: "Chat-Profile-Mic-Indicator", withExtension: "gif"), let data = try? Data(contentsOf: path) {
            view.animatedImage = FLAnimatedImage(animatedGIFData: data)
        }
        
        return view
    }()
    
    let userStatusImageView: UserStatusImageView = {
        let view = UserStatusImageView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var user: User? {
        didSet {
            guard let user = user else { return }
            imageView.configure(withUser: user, andFont: AppConstants.Fonts.robotoRegular(16).font)
            
            user.observeStatus { [weak self] (status, _) in
                self?.userStatusImageView.status = status
            }
        }
    }
    
    private var animationTimer: Timer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        
        // Animated Mic Gif
        contentView.addSubview(chatIndicatorAnimatedImageView)
        chatIndicatorAnimatedImageView.constrainToCenter()

        // User stuff
        contentView.addSubview(imageView)
        contentView.addSubview(userStatusImageView)
        imageView.constrainToSuperview()
        
        // Offset because the gif image has negative space. Need new design asset.
        chatIndicatorAnimatedImageView.constrainWidth(contentView.bounds.width + 24)
        chatIndicatorAnimatedImageView.constrainHeight(contentView.bounds.height + 24)

        userStatusImageView.constrainTo(edge: .right)?.constant = 1
        userStatusImageView.constrainTo(edge: .bottom)?.constant = 1
        userStatusImageView.constrainWidth(12)
        userStatusImageView.constrainHeight(12)
        
        contentView.layoutIfNeeded()
        imageView.layer.cornerRadius = imageView.bounds.width / 2
        contentView.clipsToBounds = false
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        chatIndicatorAnimatedImageView.alpha = 0
    }
    
    func animateSpeaker() {
        chatIndicatorAnimatedImageView.alpha = 1.0
        animationTimer?.invalidate()
        animationTimer = nil
        animationTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { [weak self] (_) in
            UIView.animate(withDuration: 0.3, animations: {
                self?.chatIndicatorAnimatedImageView.alpha = 0.0
            })
        }
    }
}
