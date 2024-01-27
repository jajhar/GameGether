//
//  AgoraManager.swift
//  GameGether
//
//  Created by James Ajhar on 11/23/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation
import AgoraRtcEngineKit
import CallKit
import MediaPlayer
import AVFoundation

protocol AgoraManagerDelegate: class {
    func agoraManager(manager: AgoraManager, activeSpeakersDidChange uuids: [UInt])
    func agoraManager(manager: AgoraManager, userDidLeaveCall uuid: UInt)
    func agoraManager(manager: AgoraManager, userDidJoinCall uuid: UInt)
}

class AgoraManager: NSObject {
        
    enum VoicePlaybackVolume {
        case mute
        case low
        case medium
        case mediumHigh
        case high
    }
    
    struct Constants {
        static let appID = "f8091571efd9462faff00bc9d269ed68"
        static let highPlaybackVolume: Int = 125
        static let mediumHighPlaybackVolume: Int = 100
        static let mediumPlaybackVolume: Int = 75
        static let lowPlaybackVolume: Int = 50
        static let voiceBackgroundTimeout: Double = 300    // 5 minutes
    }
    
    static let shared = AgoraManager()
    
    fileprivate var agoraKit: AgoraRtcEngineKit!
    fileprivate var backgroundTimer: Timer?

    //    private lazy var callCenter = CallCenter(delegate: self)
    private(set) var activeChannel: String?
    private(set) var isMuted: Bool = false
    private(set) var users = Set<UInt>() // uid list of each user on the voice call
    
    weak var delegate: AgoraManagerDelegate?
    
    var isVoiceEnabled: Bool {
        return activeChannel != nil && !isMuted
    }
    
    var isInVoiceChannel: Bool {
        return activeChannel != nil
    }
    
    var onUserJoinedRoom: ((UInt) -> Void)?
    var onUserLeftRoom: ((UInt) -> Void)?

    override init() {
        super.init()
        self.agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: Constants.appID, delegate: self)
        agoraKit.setChannelProfile(.communication)
        agoraKit.adjustPlaybackSignalVolume(Constants.mediumPlaybackVolume)
        beginBackgroundMonitoring()
    }
    
    func toggleAudio(enabled: Bool) {
        if enabled {
            agoraKit.enableAudio()
        } else {
            agoraKit.disableAudio()
        }
    }
    
    func muteRecording() {
        agoraKit.muteLocalAudioStream(true)
        isMuted = true
    }
    
    func unmuteRecording() {
        agoraKit.muteLocalAudioStream(false)
        isMuted = false
    }
    
    func setPlaybackVolume(_ volume: VoicePlaybackVolume) {
        switch volume {
        case .mute:
            agoraKit.adjustPlaybackSignalVolume(0)
        case .low:
            agoraKit.adjustPlaybackSignalVolume(Constants.lowPlaybackVolume)
        case .medium:
            agoraKit.adjustPlaybackSignalVolume(Constants.mediumPlaybackVolume)
        case .mediumHigh:
            agoraKit.adjustPlaybackSignalVolume(Constants.mediumHighPlaybackVolume)
        case .high:
            agoraKit.adjustPlaybackSignalVolume(Constants.highPlaybackVolume)
        }
    }
    
    func leaveChannel(withId channelId: String) {
        guard channelId == activeChannel else {
            GGLog.debug("Unable to leave channel \(channelId). User is not in this channel.")
            return
        }
        
        GGLog.debug("Leaving voice channel: \(channelId)")
        agoraKit.leaveChannel(nil)
        activeChannel = nil
        
        users.removeAll()
        
        FirebaseChat().setMicEnabledStatus(isEnabled: false, inChatroom: channelId)
        
        if let uid = DataCoordinator.shared.signedInUser?.uid {
            delegate?.agoraManager(manager: self, userDidLeaveCall: uid)
        }
    }
    
    func joinChannel(withId channelId: String) {
        guard channelId != activeChannel else { return }
        
        guard activeChannel == nil else {
            GGLog.debug("Unable to join channel. Another channel is already active: \(String(describing: activeChannel))")
            return
        }
        
        activeChannel = channelId
        
        guard let signedInUser = DataCoordinator.shared.signedInUser else {
            GGLog.error("Join channel failed: User is not signed in")
            return
        }
        
        let code = agoraKit.joinChannel(byToken: nil,
                                        channelId: channelId,
                                        info: nil,
                                        uid: signedInUser.uid,
                                        joinSuccess: nil)
        
        guard code == 0 else {
            GGLog.error("Join channel failed: \(code)")
            return
        }
        
        agoraKit.setDefaultAudioRouteToSpeakerphone(true)
        enableSpeaker(true)
        agoraKit.enableAudioVolumeIndication(200, smooth: 3, report_vad: true) // Values recommended by SDK
        
        // inform firebase that this user's mic is enabled
        FirebaseChat().setMicEnabledStatus(isEnabled: true, inChatroom: channelId)
        
//        callCenter.startOutgoingCall(of: channelId)
    }
    
    func enableSpeaker(_ enabled: Bool) {
        agoraKit.setEnableSpeakerphone(enabled)
    }
    
    func muteUser(withId uid: UInt) {
        agoraKit.muteRemoteAudioStream(uid, mute: true)
    }
    
    func unmuteUser(withId uid: UInt) {
        agoraKit.muteRemoteAudioStream(uid, mute: false)
    }
    
    func beginBackgroundMonitoring() {
        backgroundTimer?.invalidate()
        backgroundTimer = nil
        
        backgroundTimer = Timer.scheduledTimer(withTimeInterval: Constants.voiceBackgroundTimeout, repeats: true) { (timer) in
            guard let chatroomId = AgoraManager.shared.activeChannel else {
                return
            }
            
            // User is voice chatting
            if self.users.filter({ $0 != 0 && $0 != DataCoordinator.shared.signedInUser?.uid }).isEmpty {
                // No one else is voice chatting except the signed in user. Force eject the user from the voice chat
                self.leaveChannel(withId: chatroomId)
                NavigationManager.shared.toggleActiveCallView(visible: false)
                
                let alert = UIAlertController(title: "yoooo! you left your mic on..",
                                              message: "so we turned it off after 5 minutes when you exited the app (and no one else was on)",
                                              preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "whew, thanks!", style: .default, handler: { (_) in
                    AnalyticsManager.track(event: .voiceEjectAlertButtonTapped)
                }))
                
                alert.show()

//                // Show the voice eject alert the next time the app is foregrounded
//                UserDefaults.standard.set(true, forKey: AppConstants.UserDefaults.showVoiceCallForceEjectAlert)
//                UserDefaults.standard.synchronize()                
            }
        }
    }
    
    func endBackgroundMonitoring() {
        backgroundTimer?.invalidate()
        backgroundTimer = nil
    }
}

extension AgoraManager: AgoraRtcEngineDelegate {
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, activeSpeaker speakerUid: UInt) {
        GGLog.debug("Active speaker: \(speakerUid)")
    }

    func rtcEngineConnectionDidInterrupted(_ engine: AgoraRtcEngineKit) {
        GGLog.debug("Connection Interrupted")
    }
    
    func rtcEngineConnectionDidLost(_ engine: AgoraRtcEngineKit) {
        GGLog.debug("Connection Lost")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        GGLog.error("Agora error: \(errorCode.rawValue)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        GGLog.debug("Did join channel: \(channel), with uid: \(uid), elapsed: \(elapsed)")
        users.insert(uid)
        delegate?.agoraManager(manager: self, userDidJoinCall: uid)
        onUserJoinedRoom?(uid)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        GGLog.debug("Did joined of uid: \(uid)")
        users.insert(uid)
        delegate?.agoraManager(manager: self, userDidJoinCall: uid)
        onUserJoinedRoom?(uid)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        GGLog.debug("Did offline of uid: \(uid), reason: \(reason.rawValue)")
        users.remove(uid)
        delegate?.agoraManager(manager: self, userDidLeaveCall: uid)
        onUserLeftRoom?(uid)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didAudioMuted muted: Bool, byUid uid: UInt) {
        GGLog.debug("Did mute/unmute audio of uid: \(uid) isMuted: \(muted)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, audioQualityOfUid uid: UInt, quality: AgoraNetworkQuality, delay: UInt, lost: UInt) {
        GGLog.debug("Audio Quality of uid: \(uid), quality: \(quality.rawValue), delay: \(delay), lost: \(lost)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didApiCallExecute api: String, error: Int) {
        GGLog.debug("Did api call execute: \(api), error: \(error)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, reportAudioVolumeIndicationOfSpeakers speakers: [AgoraRtcAudioVolumeInfo], totalVolume: Int) {
        
        // Ignore speakers who's volume does not meet the minimum threshold
        let filteredSpeakers = speakers.filter({ $0.volume > 20 })
        
        let uuids = filteredSpeakers.compactMap({ $0.uid })
        delegate?.agoraManager(manager: self, activeSpeakersDidChange: uuids)
        FloatingAudioView.activeView?.animateActiveSpeakers(speakers: uuids)
    }
    
}

//extension AgoraManager: CallCenterDelegate {
//
//    func callCenter(_ callCenter: CallCenter, startCall session: String) {
//    }
//
//    func callCenter(_ callCenter: CallCenter, answerCall session: String) {
////        callCenter.setCallConnected(of: session)
//    }
//
//    func callCenter(_ callCenter: CallCenter, declineCall session: String) {
//        print("call declined")
//    }
//
//    func callCenter(_ callCenter: CallCenter, muteCall muted: Bool, session: String) {
//
//    }
//
//    func callCenter(_ callCenter: CallCenter, endCall session: String) {
//
//    }
//
//    func callCenterDidActiveAudioSession(_ callCenter: CallCenter) {
//
//    }
//}
