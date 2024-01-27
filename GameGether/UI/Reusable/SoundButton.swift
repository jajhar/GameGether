//
//  SoundButton.swift
//  GameGether
//
//  Created by James Ajhar on 12/11/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit
import MediaPlayer

class SoundButton: UIButton {

    enum Volume: String {
        case high
        case mediumHigh
        case medium
        case low
        case mute
    }
    
    var currentVolume: Volume = .high {
        didSet {
            updateState()
        }
    }
    
    var onVolumeChanged: ((Volume) -> Void)?
    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        updateState()
        addTarget(self, action: #selector(SoundButton.pressed(sender:)), for: .touchUpInside)
    }
    
    private func updateState() {
        switch currentVolume {
        case .mute:
            setImage(#imageLiteral(resourceName: "SoundOff"), for: .normal)
        case .low:
            setImage(#imageLiteral(resourceName: "SoundControl1"), for: .normal)
        case .medium:
            setImage(#imageLiteral(resourceName: "SoundControl2"), for: .normal)
        case .mediumHigh:
            setImage(#imageLiteral(resourceName: "SoundControl3"), for: .normal)
        case .high:
            setImage(#imageLiteral(resourceName: "SoundControl4"), for: .normal)
        }
        
        onVolumeChanged?(currentVolume)
    }
    
    @objc func pressed(sender: UIButton) {
        
        // Provide haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        
        switch currentVolume {
        case .mute:
            currentVolume = .low
        case .low:
            currentVolume = .medium
        case .medium:
            currentVolume = .mediumHigh
        case .mediumHigh:
            currentVolume = .high
        case .high:
            currentVolume = .mute
        }
        
        AnalyticsManager.track(event: .voiceVolumeChanged, withParameters: [
            "user": DataCoordinator.shared.signedInUser?.identifier ?? "",
            "volume": currentVolume.rawValue
        ])
        
        onTap?()
    }
}

extension MPVolumeView {

    static func setVolume(_ volume: Float) {
        let volumeView = MPVolumeView()
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = volume
        }
    }
}
