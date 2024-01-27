//
//  User.swift
//  App
//
//  Created by James on 4/26/18.
//  Copyright © 2018 James. All rights reserved.
//

import Foundation
import UIKit

protocol User: class {
    var identifier: String { get }
    
    var ign: String { get }
    var email: String { get }
    var profileImageURL: URL? { get set }
    var profileImageColoredBackgroundURL: URL? { get set }
    var ignCount: Int16 { get }
    var birthday: Date? { get set }
    var tagline: String? { get set }
    var about: String? { get set }
    var friends: [User]? { get set }
    var lastOnline: Date? { get }
    var status: UserStatus { get set }
    var relationship: UserRelationship? { get }
    var gamerTags: [GamerTag] { get }
    var followedTags: [TagsGroup] { get }
    var games: [Game] { get}
    var socialLinks: [SocialLink] { get }
    var profileMedia: [ProfileMedia] { get }
    var firebaseUser: FirebaseUser { get }
    
    func update(ign: String, ignCount: Int16)
}

enum SocialLinkType: String {
    case twitter
    case facebook
    case instagram
    case youtube
    case twitch
    
    var domain: String {
        switch self {
        case .twitter:
            return "www.twitter.com/"
        case .instagram:
            return "www.instagram.com/"
        case .facebook:
            return "www.facebook.com/"
        case .youtube:
            return ""
        case .twitch:
            return "www.twitch.tv/"
        }
    }
    
    var prefixURL: String {
        return "https://\(domain)"
    }
    
    static var allTypes: [SocialLinkType] {
        return [.twitter, .twitch, .youtube, .instagram, .facebook]
    }
}

struct SocialLink {
    var type: SocialLinkType
    var username: String
    
    var url: URL? {
        switch self.type {
        case .youtube:
            return URL(string: username)
        default:
            return URL(string: "\(type.prefixURL)\(username)")
        }
    }
}

enum MediaType: String {
    case video
    case image
}

struct ProfileMedia {
    var type: MediaType
    var url: URL
    var index: Int
}

enum FriendStatus: String {
    case pending = "PENDING"
    case accepted = "ACCEPTED"
    case blocked = "BLOCKED"
    case none = "NONE"
}

enum UserStatus: String {
    case online = "ONLINE"
    case away = "AWAY"
    case offline = "OFFLINE"
    
    var order: Int {
        switch self {
        case .online:
            return 0
        case .away:
            return 1
        case .offline:
            return 2
        }
    }
}

extension User {
    
    var isSignedInUser: Bool {
        return identifier == DataCoordinator.shared.signedInUser?.identifier
    }
    
    var fullIGNText: NSMutableAttributedString {
        let string = NSMutableAttributedString(string: ign, attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
//        string.append(NSAttributedString(string: "#\(ignCount)", attributes: [NSAttributedStringKey.foregroundColor: UIColor(hexString: "#d2d1d1")]))
        return string
    }
    
    var initials: String {
        return "\(ign.prefix(2))".uppercased()
    }
    
    var isFriend: Bool {
        return relationship?.status == .accepted
    }
    
    func observeStatus(onChange: @escaping (UserStatus, Date?) -> Void) {
        guard !isSignedInUser else {
            // Signed in user doesn't need to be monitored, they're always online.
            onChange(.online, Date())
            return
        }
        
        firebaseUser.observeUserStatus(forUser: identifier) { [weak self] (isOnline, lastUpdated) in
            guard let weakSelf = self else { return }
            
            performOnMainThread {
                if isOnline {
                    weakSelf.status = .online
                    onChange(.online, lastUpdated)
                    return
                }
                
                let now = Date()
                
                guard let thirtyMinutesAgo = now.subtractMinutes(30), let lastUpdated = lastUpdated else {
                    weakSelf.status = .offline
                    onChange(.offline, nil)
                    return
                }
                
                if lastUpdated > thirtyMinutesAgo {
                    weakSelf.status = .away
                    onChange(.away, lastUpdated)
                    return
                }
                
                weakSelf.status = .offline
                onChange(.offline, lastUpdated)
            }
        }
    }
    
    var uid: UInt {
        var sum: UInt = 0
        for scalar in identifier.unicodeScalars {
            sum += UInt(scalar.value)
        }
        return sum
    }
    
    var jsonValue: JSONDictionary {
        var dictionary = JSONDictionary()
        dictionary["_id"] = identifier
        dictionary["profileImageURL"] = profileImageURL?.absoluteString ?? ""
        dictionary["ign"] = ign
        dictionary["muted"] = AgoraManager.shared.isMuted
        return dictionary
    }
}

func == (lhs: User, rhs: User) -> Bool {
    return lhs.identifier == rhs.identifier
}

extension Array where Iterator.Element == User {

    var fullIGNText: NSMutableAttributedString {
        let str = NSMutableAttributedString(string: "")
        for (i, user) in enumerated() {
            str.append(user.fullIGNText)
            if i < count - 1 {
                str.append(NSAttributedString(string: ", "))
            }
        }
        return str
    }
    
    mutating func removeUser(_ user: User) {
        if let index = firstIndex(where: { $0.identifier == user.identifier }) {
            remove(at: index)
        }
    }
}
