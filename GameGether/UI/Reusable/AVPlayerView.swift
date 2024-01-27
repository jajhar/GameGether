//
//  AVPlayerView.swift
//  GameGether
//
//  Created by James Ajhar on 9/5/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit
import AVFoundation

enum AVPlayerNotifications: String, NotificationName {
    case muteEventNotification
}

class AVPlayerView: UIView {
    
    private(set) var url: URL?
    private(set) var player = AVPlayer()
    private var playerLayer = AVPlayerLayer()
    private var timeObserverToken: Any?
    private var playbackObserver: NSKeyValueObservation?
    private var muteTapGesture: UITapGestureRecognizer!

    private lazy var controlsContainerView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.layer.cornerRadius = 5
        view.clipsToBounds = true
        
        // Background View
        let background = UIView(frame: .zero)
        background.translatesAutoresizingMaskIntoConstraints = false
        background.backgroundColor = .black
        background.alpha = 0.4
        view.addSubview(background)
        background.constrainToSuperview()
        
        let controlsStack = UIStackView(frame: .zero)
        controlsStack.translatesAutoresizingMaskIntoConstraints = false
        controlsStack.axis = .horizontal
        controlsStack.distribution = .fill
        controlsStack.spacing = 5
        view.addSubview(controlsStack)
        controlsStack.constrainTo(edges: .top, .bottom)
        controlsStack.constrainTo(edge: .left)?.constant = 3
        controlsStack.constrainTo(edge: .right)?.constant = -3
        
        controlsStack.addArrangedSubview(muteButton)
        controlsStack.addArrangedSubview(noSoundLabel)
        controlsStack.addArrangedSubview(durationLabel)

        muteTapGesture = UITapGestureRecognizer(target: self, action:#selector(muteButtonPressed))
        view.addGestureRecognizer(muteTapGesture)
        
        return view
    }()
    
    private lazy var durationLabel: UILabel = {
        // Duration Label
        let label = UILabel(frame: .zero)
        label.text = "00:00"
        label.font = AppConstants.Fonts.robotoRegular(12).font
        label.textColor = UIColor(hexString: "#bdbdbd")
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var noSoundLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "video has no sound"
        label.font = AppConstants.Fonts.robotoRegular(12).font
        label.textColor = UIColor(hexString: "#bdbdbd")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true // hidden by default
        return label
    }()
    
    private lazy var muteButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(#imageLiteral(resourceName: "VideoSoundOff"), for: .selected)
        button.setImage(#imageLiteral(resourceName: "SoundOn"), for: .normal)
        button.setImage(#imageLiteral(resourceName: "VideoSoundOff"), for: .disabled)
        button.addTarget(self, action: #selector(muteButtonPressed), for: .touchUpInside)
        return button
    }()
    
    var onTap: ((AVPlayerView) -> Void)?
    
    var shouldShowControls: Bool = true
    var forceSoundOn: Bool = false
    
    var videoHasSound: Bool {
        guard let asset = player.currentItem?.asset else { return false }
        return asset.tracks(withMediaType: .audio).count > 0
    }
    
    var videoGravity: AVLayerVideoGravity = .resizeAspect {
        didSet {
            playerLayer.videoGravity = videoGravity
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        removePeriodicTimeObserver()
        playbackObserver?.invalidate()
    }
    
    private func commonInit() {
    
        addSubview(controlsContainerView)
        controlsContainerView.constrainHeight(30)
        controlsContainerView.constrainTo(edge: .right)?.constant = -5
        controlsContainerView.constrainTo(edge: .bottom)?.constant = -5
        controlsContainerView.isHidden = true   // Hidden by default until the video loads in

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(playerTapped))
        addGestureRecognizer(tapGesture)
    }
    
    override func layoutSubviews() {
         super.layoutSubviews()
        
        // Keep the player's frame up to date
        playerLayer.frame = bounds
    }
    
    public func configurePlayer(withURL url: URL, videoGravity: AVLayerVideoGravity = .resizeAspect) {
        
//        guard !UIDevice.isSimulator else { return }
        self.url = url
        
        removePeriodicTimeObserver()

        playerLayer.removeFromSuperlayer()
        player = AVPlayer(url: url)
        player.actionAtItemEnd = .none
        playerLayer = AVPlayerLayer(player: player)
        layer.addSublayer(playerLayer)
        playerLayer.frame = bounds
        self.videoGravity = videoGravity
        
        addPeriodicTimeObserver()
        
        // Register as an observer of the player item's status property
        playbackObserver = player.currentItem?.observe(\.status, options:  [.new, .old], changeHandler: { [weak self] (playerItem, change) in
            guard let weakSelf = self else { return }
            if playerItem.status == .readyToPlay {
                performOnMainThread {
                    
                    weakSelf.controlsContainerView.isHidden = !weakSelf.shouldShowControls
                    
                    if !weakSelf.videoHasSound {
                        weakSelf.muteButton.isEnabled = false
                        weakSelf.noSoundLabel.isHidden = false
                    } else {
                        // Muted by default unless user has specified otherwise through their behavior (tapping the button)
                        weakSelf.muteButton.isEnabled = true
                        let isMuted = UserDefaults.standard.value(forKey: AppConstants.UserDefaults.videosMuted) as? Bool ?? true
                        weakSelf.muteButton.isSelected = weakSelf.forceSoundOn ? false : isMuted
                    }
                    weakSelf.player.isMuted = weakSelf.muteButton.isSelected
                    weakSelf.layoutIfNeeded()
                }
            }
        })

        // Make sure controls are always visible
        bringSubviewToFront(controlsContainerView)
        
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd(notification:)),
                                               name: Notification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: player.currentItem)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(muteEventDidOccur(notification:)),
                                               name: AVPlayerNotifications.muteEventNotification.name,
                                               object: nil)
    }
    
    @objc func playerItemDidReachEnd(notification: Notification) {
        if let playerItem: AVPlayerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: CMTime.zero, completionHandler: nil)
        }
    }
    
    @objc func muteEventDidOccur(notification: Notification) {
        performOnMainThread {
            let isMuted = UserDefaults.standard.value(forKey: AppConstants.UserDefaults.videosMuted) as? Bool ?? true
            self.muteButton.isSelected = isMuted
            self.player.isMuted = self.muteButton.isSelected
        }
    }
    
    @objc func muteButtonPressed() {
        guard muteButton.isEnabled else { return }
        
        muteButton.isSelected.toggle()
        player.isMuted = muteButton.isSelected
        
        let defaults = UserDefaults.standard
        defaults.setValue(player.isMuted, forKey: AppConstants.UserDefaults.videosMuted)
        defaults.synchronize()
        
        // Keep ALL avplayers in sync with this value
        NotificationCenter.default.post(name: AVPlayerNotifications.muteEventNotification.name, object: player.isMuted)
    }
    
    @objc func playerTapped() {
        onTap?(self)
    }

    public func play() {
        player.play()
    }
    
    public func pause() {
        player.pause()
    }
    
    public func stop() {
        player.pause()
        player.seek(to: CMTime.zero)
    }
}

extension AVPlayerView {
    
    // MARK: Time Observing
    
    func addPeriodicTimeObserver() {
        // Notify every half second
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let durationValue = self?.player.currentItem?.duration.seconds else { return }
            
            let totalDuration = durationValue.isNaN ? 0 : Int(durationValue)

            let currentTime = totalDuration - (time.seconds.isNaN ? 0 : Int(time.seconds))
            let currentTimeString = currentTime % 60 >= 10 ? "\(currentTime % 60)" : "0\(currentTime % 60)"
            
            // update player UI
            performOnMainThread {
                self?.durationLabel.text = "\(currentTime / 60):\(currentTimeString)"
            }
        }
    }
    
    func removePeriodicTimeObserver() {
        guard let token = timeObserverToken else { return }
        player.removeTimeObserver(token)
        timeObserverToken = nil
    }
}
