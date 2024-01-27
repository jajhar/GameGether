//
//  GameSession.swift
//  GameGether
//
//  Created by James Ajhar on 9/8/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import Foundation

protocol GameSessionType {
    var identifier: String { get }
    var title: String { get }
    var imageURL: URL? { get }
    var type: GameSessionTypeIdentifier { get }
    var associatedTags: [Tag] { get }
}

enum GameSessionTypeIdentifier: String {
    case gameMode = "GAME_MODE"
    case request = "REQUEST"
}

struct GameSessionTypeObject: GameSessionType {
    var identifier: String
    var title: String
    var type: GameSessionTypeIdentifier
    var imageURL: URL?
    var associatedTags = [Tag]()
    
    static func parse(json: JSONDictionary) -> GameSessionTypeObject? {
        guard let id = json["_id"] as? String,
            let title = json["title"] as? String else {
                return nil
        }
        
        guard let rawType = json["type"] as? String, let type = GameSessionTypeIdentifier(rawValue: rawType) else { return nil }
        
        var imageURL: URL?
        if let urlString = json["imageURL"] as? String {
            imageURL = URL(string: urlString)
        }
        
        var associatedTags = [Tag]()
        if let tagsJSON = json["associatedTags"] as? [JSONDictionary] {
            associatedTags = tagsJSON.compactMap({ TagObject.parseJSON($0) })
        }
        
        return GameSessionTypeObject(identifier: id, title: title, type: type, imageURL: imageURL, associatedTags: associatedTags)
    }
}

protocol GameSession {
    var identifier: String { get }
    var begins: Date { get }
    var ends: Date { get }
    var title: String { get }
    var description: String { get }
    var createdBy: User? { get }
    var isJoined: Bool { get }
    var sessionType: GameSessionType? { get }
    var game: Game? { get }
    var chatroomId: String? { get }
    var tags: [Tag] { get }
    var attendees: [User] { get }
    var userCount: Int { get }

    func updateJoinedState(isJoined: Bool)
    func addAttendee(_ user: User)
    func removeAttendee(_ user: User)
}

class GameSessionObject: GameSession {
    
    var identifier: String = ""
    var begins: Date = Date()
    var ends: Date = Date()
    var title: String = ""
    var description: String = ""
    var createdBy: User?
    var isJoined: Bool = false
    var game: Game?
    var chatroomId: String?
    var sessionType: GameSessionType?
    var tags = [Tag]()
    var attendees = [User]()
    var userCount: Int = 0
    
    convenience init(json: JSONDictionary) {
        self.init()
        
        identifier = json["id"] as? String ?? json["_id"] as? String ?? ""
        title = json["title"] as? String ?? ""
        description = json["description"] as? String ?? ""
        isJoined = json["isJoined"] as? Bool ?? false
        chatroomId = json["chatroomId"] as? String
        
        if let timestamp = json["begins"] as? String {
            begins = Formatter.iso8601.date(from: timestamp) ?? Date()
        }
        
        if let timestamp = json["ends"] as? String {
            ends = Formatter.iso8601.date(from: timestamp) ?? Date()
        }
        
        if let gameJSON = json["gameId"] as? JSONDictionary {
            game = GameObject.parseJSON(gameJSON)
        }
        
        if let userJSON = json["createdBy"] as? JSONDictionary {
            createdBy = UserObject.parseJSON(json: userJSON)
        }
        
        if let tagsJSON = json["tags"] as? [JSONDictionary] {
            tags = tagsJSON.compactMap({ TagObject.parseJSON($0) })
        }
        
        if let usersJSON = json["users"] as? [JSONDictionary] {
            attendees = usersJSON.compactMap({ UserObject.parseJSON(json: $0) })
        }

        if let sessionTypeJSON = json["sessionType"] as? JSONDictionary {
            sessionType = GameSessionTypeObject.parse(json: sessionTypeJSON)
        }
        
        userCount = json["curUserCount"] as? Int ?? 0
    }
    
    convenience init(identifier: String) {
        self.init()
        self.identifier = identifier
    }
    
    func addAttendee(_ user: User) {
        attendees.insert(user, at: 0)
    }
    
    func removeAttendee(_ user: User) {
        attendees.removeUser(user)
    }
    
    func updateJoinedState(isJoined: Bool) {
        self.isJoined = isJoined
    }
}

extension Array where Iterator.Element == GameSession {

    func sessions(onDate date: Date) -> [GameSession] {
        var sessions = [GameSession]()
        for session in self {
            
            // Remove the nano seconds from both dates for EXACT matching
            let normalizedSessionDate = session.begins.subtractNanoseconds(session.begins.nanoseconds) ?? session.begins
            let normalizedDate = date.subtractNanoseconds(date.nanoseconds) ?? date

            if (normalizedSessionDate >= normalizedDate && normalizedSessionDate < normalizedDate.addHours(1) ?? normalizedDate) ||
                (normalizedSessionDate <= normalizedDate && normalizedSessionDate > normalizedDate.subtractHours(1) ?? normalizedDate) {
                sessions.append(session)
            }
        }
        return sessions
    }
}
