//
//  ProfileMediaView.swift
//  GameGether
//
//  Created by James Ajhar on 5/30/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class ProfileMediaView: UIView {

    // MARK: - Outlets
    @IBOutlet weak var mediaScrollView: UIScrollView!
    @IBOutlet weak var mediaViewStack: ProfileMediaStackView!
    
    // MARK: - Properties
    private(set) var currentPage: Int = 0 {
        didSet {
            mediaViewStack.setActiveView(atIndex: currentPage)
        }
    }
    
    private var blurEffectView: UIView!
    
    var user: User? {
        didSet {
            setupWithUser()
        }
    }
    
    var onVideoTapped: ((AVPlayerView) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        mediaScrollView.delegate = self
        
        // Add a gaussian blur effect to the view
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.regular)
        let backgroundBlurEffectView = UIVisualEffectView(effect: blurEffect)
        backgroundBlurEffectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundBlurEffectView)
        backgroundBlurEffectView.constrainToSuperview()
        blurEffectView = backgroundBlurEffectView
        adjustBlurEffect(alpha: 0)  // hide by default
    }
    
    private func setupWithUser() {
        guard let user = user else { return }
        
        mediaViewStack.onVideoTapped = onVideoTapped
        mediaViewStack.profileMedia = user.profileMedia
        
        currentPage = 0
    }
    
    public func pausePlayer() {
        mediaViewStack.pauseAllVideoPlayers()
    }
    
    public func resumePlayer() {
        mediaViewStack.setActiveView(atIndex: currentPage)
    }
    
    public func adjustBlurEffect(alpha: CGFloat) {
        blurEffectView.alpha = alpha
    }
}

extension ProfileMediaView: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        currentPage = Int(scrollView.contentOffset.x / scrollView.bounds.width)
    }
}
