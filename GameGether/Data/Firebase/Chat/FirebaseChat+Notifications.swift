//
//  FirebaseChat+Notifications.swift
//  GameGether
//
//  Created by James Ajhar on 8/25/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation

extension FirebaseChat {
    
    func sendNotifications(toChatroom chatroom: FRChatroom,
                           ofType notificationType: AppConstants.PushNotificationType,
                           withTitle title: String? = nil,
                           withMessage message: String) {
        
        guard let signedInUser = DataCoordinator.shared.signedInUser else {
            GGLog.error("Failed to send notification: User is not signed in.")
            return
        }
    
        let dataCoordinator = DataCoordinator.shared
        
        let userIds = chatroom.userIds.filter({ $0 != signedInUser.identifier})
        
        dataCoordinator.sendPushNotification(ofType: notificationType,
                                             toUsers: userIds,
                                             inChatroomId: chatroom.identifier,
                                             withTitle: title,
                                             withMessage: message) { (error) in
            if let error = error {
                GGLog.error("ERROR: \(error)")
            }
        }
    }
}
