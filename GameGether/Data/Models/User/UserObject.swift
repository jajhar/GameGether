//
//  UserJSON.swift
//  GameGether
//
//  Created by James Ajhar on 6/16/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation

class UserObject: User {
    
    private(set) var identifier: String = ""
    private(set) var ign: String = ""
    private(set) var ignCount: Int16 = 1
    private(set) var email: String = ""
    var tagline: String?
    var about: String?
    var highlightLink: URL?
    var profileImageURL: URL?
    var profileImageColoredBackgroundURL: URL?
    var birthday: Date?
    var lastOnline: Date?
    var friends: [User]?
    var relationship: UserRelationship?
    var gamerTags: [GamerTag] = []
    var games: [Game] = [Game]()
    var socialLinks: [SocialLink] = []
    var profileMedia: [ProfileMedia] = []
    var followedTags: [TagsGroup] = []
    var status: UserStatus = .offline

    lazy var firebaseUser: FirebaseUser = {
        let firebase = FirebaseUser()
        firebase.signIn()
        return firebase
    }()
    
    static func parseJSON(json: [String: Any]) -> UserObject? {
        
        guard let identifier = json["id"] as? String ?? json["_id"] as? String else { return nil }
        
        let user = UserObject()
        user.identifier = identifier
        user.ign = json["ign"] as? String ?? ""
        user.ignCount = json["ignCount"] as? Int16 ?? 1
        
        if let status = json["status"] as? JSONDictionary {
            if let timestamp = status["updatedAt"] as? String {
                user.lastOnline = Formatter.iso8601.date(from: timestamp)
            }
        }
        
        if let urlString = json["profileImageURL"] as? String {
            user.profileImageURL = URL(string: urlString)
        }
        
        if let urlString = json["profileImageColoredBackgroundURL"] as? String {
            user.profileImageColoredBackgroundURL = URL(string: urlString)
        }
        
        if let gamesJSON = json["games"] as? [JSONDictionary] {
            user.games = gamesJSON.compactMap({ GameObject.parseJSON($0) })
        }
        
        if let gamerTagsJSON = json["gamerTags"] as? [JSONDictionary] {
            user.gamerTags = gamerTagsJSON.compactMap({ GamerTag(json: $0) })
        }
        
        if let followingTags = json["followingTags"] as? [JSONDictionary] {
            user.followedTags = followingTags.compactMap({ TagsGroupObject.parseJSON($0) })
        }
        
        if let tagline = json["tagline"] as? String {
            user.tagline = tagline
        }
        
        if let about = json["about"] as? String {
            user.about = about
        }

        if let relationshipJSON = json["relationship"] as? JSONDictionary {
            let relationship = UserRelationship.parseJSON(relationshipJSON)
            user.relationship = relationship
        }
        
        if let mediaJSONs = json["profileMedia"] as? [JSONDictionary] {
            // Parse media for the profile header
            for mediaJSON in mediaJSONs {
                guard let mediaType = MediaType(rawValue: mediaJSON["mediaType"] as? String ?? ""),
                    let url = URL(string: mediaJSON["url"] as? String ?? ""),
                    let index = mediaJSON["index"] as? Int else { continue }
                
                let media = ProfileMedia(type: mediaType, url: url, index: index)
                user.profileMedia.append(media)
                user.profileMedia.sort(by: { $0.index < $1.index })
            }
        }
        
        if let links = json["socialLinks"] as? JSONDictionary {
            if let username = links["twitter"] as? String, !username.isEmpty {
                user.socialLinks.append(SocialLink(type: .twitter, username: username))
            }
            if let username = links["facebook"] as? String, !username.isEmpty {
                user.socialLinks.append(SocialLink(type: .facebook, username: username))
            }
            if let username = links["youtube"] as? String, !username.isEmpty {
                user.socialLinks.append(SocialLink(type: .youtube, username: username))
            }
            if let username = links["instagram"] as? String, !username.isEmpty {
                user.socialLinks.append(SocialLink(type: .instagram, username: username))
            }
            if let username = links["twitch"] as? String, !username.isEmpty {
                user.socialLinks.append(SocialLink(type: .twitch, username: username))
            }
        }
        
        return user
    }
    
    convenience init(email: String) {
        self.init()
        self.email = email
    }
    
    convenience init(identifier: String) {
        self.init()
        self.identifier = identifier
    }
    
    convenience init(fromUserMO userMO: UserMO) {
        self.init()
        self.identifier = userMO.identifier
        self.ign = userMO.ign
        self.email = userMO.email
        self.ignCount = userMO.ignCount
        self.birthday = userMO.birthday
        self.profileImageURL = userMO.profileImageURL
        self.profileImageColoredBackgroundURL = userMO.profileImageColoredBackgroundURL
        self.friends = userMO.friends
        self.relationship = userMO.relationship
        self.lastOnline = userMO.lastOnline
        self.tagline = userMO.tagline
        self.about = userMO.about
    }
    
    func update(ign: String, ignCount: Int16) {
        self.ign = ign
        self.ignCount = ignCount
    }
}

struct GamerTag {
    var game: Game?
    var gamerTag: String?
    
    init(json: JSONDictionary) {
        gamerTag = json["gamerTag"] as? String
        
        if let gameJSON = json["gameId"] as? JSONDictionary {
            game = GameObject.parseJSON(gameJSON)
        }
    }
}
