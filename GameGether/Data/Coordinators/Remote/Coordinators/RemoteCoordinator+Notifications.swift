//
//  RemoteCoordinator+Notifications.swift
//  GameGether
//
//  Created by James Ajhar on 8/25/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation

extension RemoteCoordinator {
    
    func sendPushNotification(ofType notificationType: AppConstants.PushNotificationType,
                              toUsers userIds: [String],
                              inChatroomId chatroomId: String,
                              withTitle title: String? = nil,
                              withMessage message: String,
                              completion: @escaping ((Error?) -> Void)) {
        
        guard var request = APIRequest.sendChatroomPushNotification.request() else {
            completion(RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
        
        var body: [String: Any] = [
            "userIds": userIds,
            "message": message,
            "chatroomId": chatroomId,
            "notificationType": notificationType.rawValue,
            "fromUserId": DataCoordinator.shared.signedInUser?.identifier ?? ""
        ]
        
        if let title = title {
            body["title"] = title
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        send(request: request) { (data, response, error) in
            
            guard error == nil else {
                completion(error)
                return
            }
    
            completion(nil)
        }

    }
    
    func mute(chatroomWithId chatroomId: String, completion: @escaping (([String]?, Error?) -> Void)) {
        guard let request = APIRequest.muteChatroom(chatroomId).request() else {
            completion(nil, RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
        
        send(request: request) { (data, response, error) in
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            guard let data = data, let chatroomIds = self.jsonParse(data: data) as? [String] else {
                completion(nil, RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
            
            completion(chatroomIds, nil)
        }
    }
    
    func unmute(chatroomWithId chatroomId: String, completion: @escaping (([String]?, Error?) -> Void)) {
        guard let request = APIRequest.unmuteChatroom(chatroomId).request() else {
            completion(nil, RemoteError.apiError(message: "Failed to send request", errorCode: 0))
            return
        }
        
        send(request: request) { (data, response, error) in
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            guard let data = data, let chatroomIds = self.jsonParse(data: data) as? [String] else {
                completion(nil, RemoteError.apiError(message: "Failed to parse JSON", errorCode: 0))
                return
            }
        
            completion(chatroomIds, nil)
        }
    }
}
