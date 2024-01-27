//
//  APIRequest.swift
//  App
//
//  Created by James on 4/26/18.
//  Copyright © 2018 James. All rights reserved.
//

import Foundation

enum RequestType: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

enum APIRequest: APIRequestProtocol {
    
    // Force unwrap here because we want it to hard crash immediately
    #if LOCAL
        static let baseURL: URL = URL(string: "http://localhost:8080")!
    #elseif STAGING
        static let baseURL: URL = URL(string: "http://167.99.170.147:8080")!
    #else
        static let baseURL: URL = URL(string: "https://gamegetherapi.com")!
    #endif
    
    static let aboutPageURL: URL = URL(string: "https://www.gamegether.com/about-us")!
    static let privacyPageURL: URL = URL(string: "https://www.gamegether.com/privacy")!
    
    // Login
    case login
    case loginWithFacebook
    case loginToFirebase
    case loginWithGoogle
    case loginWithApple
    case register
    
    case checkIGN(String)
    case checkEmail(String)
    case forgotPassword
    case resetPassword
    case getProfiles(String)
    case updateStatus
    case updateProfile
    case searchUsers
    
    // User Relationships
    case addFriend(String)
    case getFriendStatus(String)
    case acceptFriendRequest(String)
    case cancelFriendRequest(String)
    case getFriends
    case blockUser(String)
    case unblockUser(String)
    case getBlockedUsers
    
    // Games
    case getGames
    case addFavoriteGame
    case getFavoriteGames
    case getActiveLobbies

    // Notifications
    case sendChatroomPushNotification
    case muteChatroom(String)
    case unmuteChatroom(String)
    
    // Tags
    case getTags(String)
    case getUsersFollowingTags(String, String, String?)
    case followTags
    case unfollowTags
    case getFollowedTags
    case activeTags(String)
    
    // Scheduling
    case scheduleGameSession
    case getGameSessions(String?, String?, String?, String?, String?)
    case getGameSessionsAttending(String?, String?, String?, String?)
    case joinGameSession(String)
    case leaveGameSession(String)
    case getGameSessionTypes(String)
    case getGameSession(String)

    var methodType: RequestType {
        switch self {
            
        case .login, .loginToFirebase, .loginWithFacebook, .loginWithGoogle, .loginWithApple, .register,
             .addFriend, .resetPassword, .forgotPassword, .updateStatus,
             .searchUsers,
             .sendChatroomPushNotification, .muteChatroom, .unmuteChatroom,
             .addFavoriteGame,
             // Relationships
             .blockUser,
            // Scheduling
            .scheduleGameSession, .joinGameSession, .leaveGameSession:
            return .post
            
        case .checkIGN, .checkEmail, .getFriends, .getProfiles, .getFriendStatus,
             .getGames, .getFavoriteGames, .getActiveLobbies,
             .getTags, .getFollowedTags,
             // Relationships
             .getBlockedUsers,
             // Tags
            .activeTags, .getUsersFollowingTags,
            // Scheduling
            .getGameSessions, .getGameSessionsAttending, .getGameSessionTypes, .getGameSession:
            return .get
            
        case .updateProfile,
             .followTags, .unfollowTags:
            return .put
            
        case .acceptFriendRequest:
            return .patch
            
        case .cancelFriendRequest, .unblockUser:
            return .delete
        }
    }
    
    var path: String {
        switch self {
            // Login
        case .login:
            return "/user/login"
        case .loginToFirebase:
            return "/user/login/firebase"
        case .loginWithFacebook:
            return "/user/login/facebook"
        case .loginWithGoogle:
            return "/user/login/google"
        case .loginWithApple:
            return "/user/login/apple"
        case .register:
            return "/user/register"
            
        case .checkEmail(let email):
            return "/user/checkemail/\(email)"
        case .checkIGN(let ign):
            return "/user/checkign/\(ign)"
        case .forgotPassword:
            return "/user/password/forgot"
        case .resetPassword:
            return "/user/password/reset"
        case .updateProfile:
            return "/user/profile"
            
        // User Relationships
        case .addFriend(let userId):
            return "/relationships/\(userId)"
        case .acceptFriendRequest(let userId):
            return "/relationships/\(userId)?status[]=ACCEPTED"
        case .cancelFriendRequest(let userId):
            return "/relationships/\(userId)"
        case .getFriendStatus(let userId):
            return "/relationships/\(userId)"
        case .getFriends:
            return "/relationships?status[]=ACCEPTED"
        case .blockUser(let userId):
            return "/relationships/\(userId)"
        case .unblockUser(let userId):
            return "/relationships/\(userId)"
        case .getBlockedUsers:
            return "/relationships"
            
        case .getProfiles(let userIds):
            return "/user/profiles?userIds[]=\(userIds)"
        case .updateStatus:
            return "/user/status"
        case .searchUsers:
            return "/search/user"
            
        // Notifications
        case .sendChatroomPushNotification:
            return "/notify/push/chatroom"
        case .muteChatroom(let chatroomId):
            return "/notify/mute/\(chatroomId)"
        case .unmuteChatroom(let chatroomId):
            return "/notify/unmute/\(chatroomId)"
            
        // Games
        case .getGames:
            return "/game/all"
        case .addFavoriteGame, .getFavoriteGames:
            return "/game/favorites"
        case .getActiveLobbies:
            return "/game/favorites/lobbies"
            
        // Tags
        case .getTags(let gameId):
            return "/tags?gameId=\(gameId)"
        case .followTags:
            return "/tags/follow"
        case .unfollowTags:
            return "/tags/unfollow"
        case .getFollowedTags:
            return "/tags/following"
        case .activeTags(let gameId):
            return "/tags/online/\(gameId)"
        case .getUsersFollowingTags(let gameId, let tagIds, let offset):
            var url = "/tags/\(gameId)/followers?tags[]=\(tagIds)"
            if let offset = offset {
                url += "&lastId=\(offset)"
            }
            return url
            
        // Scheduling
        case .scheduleGameSession:
            return "/schedule"
        case .joinGameSession(let sessionId):
            return "/schedule/sessions/\(sessionId)/join"
        case .leaveGameSession(let sessionId):
            return "/schedule/sessions/\(sessionId)/leave"
        case .getGameSessionTypes(let gameId):
            return "/game/\(gameId)/sessions/types"
        case .getGameSessions(let gameId, let tags, let sessionType, let startTime, let endTime):
            var url = "/schedule/sessions?sessionType=5d929b42f6cd5547de36423b&"
            if let gameId = gameId {
                url += "gameId=\(gameId)&"
            }
            if let tags = tags, !tags.isEmpty {
                url += "tags[]=\(tags)&"
            }
            if let type = sessionType {
                url += "sessionType=\(type)&"
            }
            if let startTime = startTime {
                url += "startTime=\(startTime)&"
            }
            if let endTime = endTime {
                url += "maxStartTime=\(endTime)"
            }
            return url
            
        case .getGameSessionsAttending(let gameId, let tags, let startTime, let endTime):
            var url = "/schedule/sessions?filter=attending&sessionType=5d929b42f6cd5547de36423b&sort=lastMessageSentAt&"
            if let gameId = gameId {
                url += "gameId=\(gameId)&"
            }
            if let tags = tags, !tags.isEmpty {
                url += "tags[]=\(tags)&"
            }
            if let startTime = startTime {
                url += "startTime=\(startTime)&"
            }
            if let endTime = endTime {
                url += "maxStartTime=\(endTime)"
            }
            
            return url
            
        case .getGameSession(let sessionId):
            return "/schedule/sessions/\(sessionId)"
        }
        
    }
}
