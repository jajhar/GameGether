//
//  DataCoordinator+Notifications.swift
//  GameGether
//
//  Created by James Ajhar on 8/25/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation
import UserNotifications
import UIKit
import AirshipKit

extension DataCoordinator {
    
    
    func sendPushNotification(ofType notificationType: AppConstants.PushNotificationType,
                              toUsers userIds: [String],
                              inChatroomId chatroomId: String,
                              withTitle title: String? = nil,
                              withMessage message: String,
                              completion: @escaping ((Error?) -> Void)) {
        
        remoteCoordinator.sendPushNotification(ofType: notificationType,
                                               toUsers: userIds,
                                               inChatroomId: chatroomId,
                                               withTitle: title,
                                               withMessage: message,
                                               completion: completion)
    }
        
    func mute(chatroomWithId chatroomId: String, completion: @escaping ([String]?, Error?) -> Void) {
        
        remoteCoordinator.mute(chatroomWithId: chatroomId) { [unowned self] (chatroomIds, error) in
            guard error == nil, let chatroomIds = chatroomIds else {
                completion(nil, error)
                return
            }
            
            self.saveMutedChatrooms(chatroomIds: chatroomIds)
            completion(chatroomIds, nil)
        }
    }
    
    func unmute(chatroomWithId chatroomId: String, completion: @escaping ([String]?, Error?) -> Void) {
        
        remoteCoordinator.unmute(chatroomWithId: chatroomId) { [unowned self] (chatroomIds, error) in
            guard error == nil, let chatroomIds = chatroomIds else {
                completion(nil, error)
                return
            }
            
            self.saveMutedChatrooms(chatroomIds: chatroomIds)
            completion(chatroomIds, nil)
        }
    }
}

extension DataCoordinator {
    
    private func saveMutedChatrooms(chatroomIds: [String]) {
        let defaults = UserDefaults.standard
        defaults.setValue(chatroomIds, forKey: AppConstants.UserDefaults.mutedChatrooms)
        defaults.synchronize()
    }
    
    var mutedChatrooms: [String]? {
        return UserDefaults.standard.array(forKey: AppConstants.UserDefaults.mutedChatrooms) as? [String]
    }
    
    func isChatroomMuted(chatroomId: String) -> Bool {
        guard let mutedChatrooms = UserDefaults.standard.array(forKey: AppConstants.UserDefaults.mutedChatrooms) as? [String] else {
            return false
        }
        return mutedChatrooms.contains(chatroomId)
    }
}
