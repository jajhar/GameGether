//
//  ProfileMediaContainerView.swift
//  GameGether
//
//  Created by James Ajhar on 5/30/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit
import AVFoundation

class ProfileMediaContainerView: UIView {

    struct Constants {
        static let maxPages: Int = 3
    }
    
    enum ProfileMediaContainerViewMode {
        case viewing
        case editing
    }

    // MARK: - Outlets
    @IBOutlet weak var mediaScrollView: UIScrollView!
    @IBOutlet weak var mediaViewStack: ProfileMediaStackView!
    @IBOutlet weak var pageControls: UIPageControl!
    @IBOutlet weak var editButton: UIButton!
    
    // MARK: - Properties
    var currentPage: Int = 0 {
        didSet {
            mediaViewStack.setActiveView(atIndex: currentPage)
            pageControls.currentPage = currentPage
            editButton.setTitle("edit \(currentPage + 1)/\(Constants.maxPages)", for: .normal)
            scrollTo(page: currentPage)
        }
    }
    
    var currentMode: ProfileMediaContainerViewMode = .viewing {
        didSet {
            setMode(currentMode)
        }
    }
    
    private var blurEffectView: UIView!
    
    var user: User? {
        didSet {
            setupWithUser()
        }
    }
    
    var onVideoTapped: ((AVPlayerView) -> Void)? {
        didSet {
            mediaViewStack.onVideoTapped = onVideoTapped
        }
    }
    
    var videoPlayerGravity: AVLayerVideoGravity = .resizeAspect {
        didSet {
            mediaViewStack.videoPlayerGravity = videoPlayerGravity
        }
    }
    
    /// Returns the button and the index of the media item
    var onEditPressed: ((UIButton, Int) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        mediaScrollView.delegate = self
        
        // Add a gaussian blur effect to the view
        let blurEffect = UIBlurEffect(style: .light)
        let backgroundBlurEffectView = UIVisualEffectView(effect: blurEffect)
        backgroundBlurEffectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundBlurEffectView)
        backgroundBlurEffectView.constrainToSuperview()
        blurEffectView = backgroundBlurEffectView
        adjustBlurEffect(alpha: 0)  // hide by default
        
        currentMode = .viewing
        currentPage = 0
    }
    
    private func styleUI() {
        editButton.titleLabel?.font = AppConstants.Fonts.robotoMedium(14).font
        editButton.setTitleColor(UIColor(hexString: "#57A2E1"), for: .normal)
        editButton.borderColor = UIColor(hexString: "#57A2E1")
        editButton.borderWidth = 1
    }
    
    private func setupWithUser() {
        setMode(currentMode)
    }
    
    private func setMode(_ mode: ProfileMediaContainerViewMode) {
        guard let user = user else { return }

        mediaViewStack.profileMedia = user.profileMedia

        switch mode {
        case .viewing:
            pageControls.numberOfPages = user.profileMedia.count > 1 ? user.profileMedia.count : 0
            editButton.isHidden = true
            
        case .editing:
            pageControls.numberOfPages = 3
            mediaViewStack.fillWithEmptyViews(count: Constants.maxPages - user.profileMedia.count)
            editButton.isHidden = false
        }
        
        pageControls.currentPage = currentPage
    }
    
    private func scrollTo(page: Int) {
        mediaScrollView.scrollToPage(page: page, animated: true)
    }
    
    public func pausePlayer() {
        mediaViewStack.pauseAllVideoPlayers()
    }
    
    public func resumePlayer() {
        mediaViewStack.resumeActivePlayer()
    }
    
    public func adjustBlurEffect(alpha: CGFloat) {
        blurEffectView.alpha = alpha
    }
    
    // MARK: - Interface Actions
    
    @IBAction func editButtonPressed(_ sender: UIButton) {
        onEditPressed?(sender, currentPage)
    }
}

extension ProfileMediaContainerView: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        currentPage = Int(scrollView.contentOffset.x / scrollView.bounds.width)
    }
}
