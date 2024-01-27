//
//  SoundManager.swift
//  GameGether
//
//  Created by James Ajhar on 8/5/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit
import AVFoundation

enum SoundEffectType: String {
    case incomingCall =         "INCOMING_2.mp3"
    case outgoingCall =         "OUTGOING_2.mp3"
    case callJoined =           "JOIN_CALL_V1.mp3"
    case callLeft =             "LEFT_CALL_V1.mp3"
    case callVolume =           "CALL_VOLUME_2.mp3"
    case messageSent =          "SENT_2.mp3"
    case friendOnline =         "FRIEND_ONLINE.mp3"
    case friendRequest =        "FriendRequest_v17.mp3"
    case messageNotification =  "MESSAGE_FRIEND_v1.mp3"
    case appStartup =           "START_UP_v1.mp3"
}

class SoundManager: NSObject {
    
    static let shared = SoundManager()
    
    private var soundEffectPlayers = [SoundEffectPlayer]()
    
    override init() {
        super.init()
        
        do {
            // Respect the mute switch!
            try AVAudioSession.sharedInstance().setCategory(.ambient)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            GGLog.error(error)
        }
    }
        
    func playSound(_ soundType: SoundEffectType) {

        guard UIApplication.shared.applicationState != .background else { return }

        guard let path = Bundle.main.path(forResource: soundType.rawValue, ofType: nil) else { return }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            let player = try SoundEffectPlayer(contentsOf: url)
            player.soundType = soundType
            player.delegate = self
            
            soundEffectPlayers.append(player)
            
            player.prepareToPlay()
            player.play()
        } catch {
            GGLog.error(error)
        }
    }
    
    func killSound(_ soundType: SoundEffectType) {
        _ = soundEffectPlayers.compactMap { (player) -> SoundEffectPlayer? in
            if player.soundType == soundType {
                player.stop()
                return nil
            }
            return player
        }
    }
}

extension SoundManager: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        soundEffectPlayers.removeAll(where: { $0 == player })
    }
}

private class SoundEffectPlayer: AVAudioPlayer {
    
    var soundType: SoundEffectType?
}
