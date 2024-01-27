//
//  UIDevice+Extensions.swift
//  GameGether
//
//  Created by James Ajhar on 8/26/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit
import AVFoundation
import UserNotifications

extension UIDevice {
    
    static func checkPushNotificationEnabled(_ completion: @escaping (Bool) -> Void) {
      let center = UNUserNotificationCenter.current()
      center.getNotificationSettings(completionHandler: { settings in
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            completion(true)
        case .denied, .notDetermined:
            completion(false)
        default:
            completion(false)
        }
      })
    }
    
    var hasNotch: Bool {
        let bottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
        return bottom > 0
    }
    
    static var isSimulator: Bool {
        return TARGET_OS_SIMULATOR != 0
    }
    
    var hasMicrophonePermission: Bool {
        switch AVAudioSession.sharedInstance().recordPermission {
        case AVAudioSessionRecordPermission.granted:
            return true
        case AVAudioSessionRecordPermission.denied:
            return false
        case AVAudioSessionRecordPermission.undetermined:
            return false
        default:
            return false
        }
    }
    
    func requestMicrophonePermission() {
        
        AVAudioSession.sharedInstance().requestRecordPermission({ (granted: Bool)-> Void in
            if granted {
                GGLog.debug("Microphone Permission Granted")
            } else{
                GGLog.debug("Microphone Permission Denied")
            }
        })
    }
}

extension UIApplication {
    
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    static let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
}
