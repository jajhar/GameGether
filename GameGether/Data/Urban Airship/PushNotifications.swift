//
//  PushNotifications.swift
//  GameGether
//
//  Created by James Ajhar on 7/18/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import Foundation
import AirshipKit

class PushNotificationsManager {
    
    static let shared = PushNotificationsManager()
    
    public func registerForRemoteNotifications() {
        UAirship.push().userPushNotificationsEnabled = true
        UAirship.push().defaultPresentationOptions = [.alert, .badge, .sound]
//        UAirship.push()?.isQuietTimeEnabled = false
        UAirship.push()?.setQuietTimeStartHour(0, startMinute: 0, endHour: 7, endMinute: 0)    // 12am -> 7am
        setQuietTime(enabled: true)
    }

    public func subscribe(toChatroom chatroomId: String) {
        UAirship.channel().addTag(chatroomId)
        UAirship.push().updateRegistration()
    }
    
    public func unsubscribe(fromChatroom chatroomId: String) {
        UAirship.channel().removeTag(chatroomId)
        UAirship.push().updateRegistration()
    }
    
    public func subscribe(toChatrooms chatroomIds: [String]) {
        UAirship.channel()?.addTags(chatroomIds)
        UAirship.push().updateRegistration()
    }
    
    public func subscribe(toUser userId: String) {
        UAirship.namedUser().identifier = userId
        UAirship.channel().addTag(userId)
        UAirship.push().updateRegistration()
    }
    
    public func unsubscribe(fromUser userId: String) {
        UAirship.channel().removeTag(userId)
        UAirship.push().updateRegistration()
    }
    
    public func setQuietTime(enabled: Bool) {
        UAirship.push()?.isQuietTimeEnabled = enabled
        UAirship.push().updateRegistration()
    }
}
