//
//  ProfileMediaStackView.swift
//  GameGether
//
//  Created by James Ajhar on 6/3/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit
import AVFoundation

class ProfileMediaStackView: UIStackView {

    private(set) var mediaViews = [ProfileMediaView]()
    private(set) var activeViewIndex: Int = 0
    private(set) var isPaused: Bool = false
    
    var profileMedia = [ProfileMedia]() {
        didSet {
            setupMediaStack()
        }
    }
    
    var onVideoTapped: ((AVPlayerView) -> Void)?
    
    var videoPlayerGravity: AVLayerVideoGravity = .resizeAspectFill {
        didSet {
            _ = mediaViews.compactMap({ $0.playerView?.videoGravity = videoPlayerGravity })
        }
    }
    
    private func setupMediaStack() {
        _ = arrangedSubviews.compactMap({ $0.removeFromSuperview() })
        mediaViews.removeAll()
        
        // Add the user's profile media
        for (_, media) in profileMedia.enumerated() {
            let view = ProfileMediaView(frame: .zero)
            view.translatesAutoresizingMaskIntoConstraints = false
            view.configure(withMedia: media)
            view.playerView?.videoGravity = videoPlayerGravity
            view.playerView?.pause() // start in paused state
            addArrangedSubview(view)
            
            if let superview = self.superview {
                view.widthAnchor.constraint(equalTo: superview.widthAnchor).isActive = true
            }
            
            view.playerView?.onTap = onVideoTapped
            
            mediaViews.append(view)
        }
        
        if mediaViews.isEmpty {
            // Show empty state
            let view = ProfileMediaView(frame: .zero)
            view.translatesAutoresizingMaskIntoConstraints = false
            view.configure(withImage: #imageLiteral(resourceName: "default-profile-media"))
            addArrangedSubview(view)
            mediaViews.append(view)
            
            if let superview = self.superview {
                view.widthAnchor.constraint(equalTo: superview.widthAnchor).isActive = true
            }
        }
        
        layoutIfNeeded()

        setActiveView(atIndex: activeViewIndex)
    }
    
    public func pauseAllVideoPlayers() {
        isPaused = true
        _ = mediaViews.compactMap({ $0.playerView?.pause() })
    }
    
    public func resumeActivePlayer() {
        isPaused = false
        guard activeViewIndex < mediaViews.count else { return }
        mediaViews[activeViewIndex].playerView?.play()
    }
    
    public func setActiveView(atIndex index: Int) {
        guard index < mediaViews.count else { return }
        activeViewIndex = index

        if !isPaused {
            pauseAllVideoPlayers()
            resumeActivePlayer()
        }
    }
    
    public func fillWithEmptyViews(count: Int) {
        for i in 0..<count {
            guard let url = URL(string: "www.gamegether.com") else { continue }
            let media = ProfileMedia(type: .image, url: url, index: i)
            profileMedia.append(media)
        }
    }
}

class ProfileMediaView: UIView {
    
    private(set) var media: ProfileMedia?
    private(set) var playerView: AVPlayerView?
    private(set) var imageView: UIImageView?
    
    func configure(withMedia media: ProfileMedia) {
        self.media = media
        
        switch media.type {
        case .image:
            let imageView = self.imageView(forMedia: media)
            addSubview(imageView)
            imageView.constrainToSuperview()
        case .video:
            let player = playerView(forMedia: media)
            addSubview(player)
            player.constrainToSuperview()
        }
    }
    
    func configure(withImage image: UIImage) {
        let imageView = UIImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = image
        addSubview(imageView)
        imageView.constrainToSuperview()
        self.imageView = imageView
    }
    
    private func imageView(forMedia media: ProfileMedia) -> UIImageView {
        let imageView = UIImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.sd_setImage(with: media.url, completed: nil)
        self.imageView = imageView
        return imageView
    }
    
    private func playerView(forMedia media: ProfileMedia) -> AVPlayerView {
        let view = AVPlayerView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        view.configurePlayer(withURL: media.url)
        view.play()
        self.playerView = view
        return view
    }
}
