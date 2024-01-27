//
//  UserMO.swift
//  GameGether
//
//  Created by James Ajhar on 6/16/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation
import CoreData

class UserMO: NSManagedObject, User {
    
    @NSManaged public var identifier: String
    @NSManaged public var ign: String
    @NSManaged public var ignCount: Int16
    @NSManaged public var email: String
    @NSManaged public var birthday: Date?
    @NSManaged public var friendStatusRaw: String?
    @NSManaged public var tagline: String?
    @NSManaged public var about: String?
    @NSManaged public var highlightLink: URL?
    @NSManaged public var profileImageURL: URL?
    @NSManaged public var profileImageColoredBackgroundURL: URL?
    @NSManaged public var profileBackgroundImageURL: URL?
    @NSManaged public var isSignedInUser: Bool
    @NSManaged public var isSavedProfile: Bool
    @NSManaged var lastOnline: Date?
    @NSManaged var updatedAt: Date?
    @NSManaged var userRelationshipStatus: UserRelationshipStatus?
    @NSManaged var highlightVideoURL: URL?
    
    // MARK: Not stored in cache
    var gamerTags: [GamerTag] = []
    var games: [Game] = []
    var socialLinks: [SocialLink] = []
    var profileMedia: [ProfileMedia] = []
    var followedTags: [TagsGroup] = []
    var status: UserStatus = .offline

    lazy var firebaseUser: FirebaseUser = {
        let firebase = FirebaseUser()
        firebase.signIn()
        return firebase
    }()
    
    // MARK: Relationships
    @NSManaged public var friendsRelationship: Set<UserMO>?

    var friends: [User]? {
        get {
            guard let relationships = friendsRelationship else { return nil }
            
            var threadSafeUsers = [User]()
            for userMO in relationships {
                threadSafeUsers.append(UserObject(fromUserMO: userMO))
            }
            return threadSafeUsers
        }
        set {
            GGLog.warning("This object does not support setting of friends variable")
        }
    }
    
    var relationship: UserRelationship? {
        get {
            guard let relationship = userRelationshipStatus else { return nil }
            // Make it thread safe!
            return UserRelationship(fromRelationship: relationship)
        }
        set {
            GGLog.warning("This object does not support setting of relationship variable")
        }
    }
    
    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    /// Update Entity Properties from User protocol
    ///
    /// - Parameter model: The user model to update from
    func update(fromUserModel model: User) {
        self.identifier = model.identifier
        self.ign = model.ign
        self.email = model.email
        self.ignCount = model.ignCount
        self.birthday = model.birthday
        self.profileImageURL = model.profileImageURL
        self.profileImageColoredBackgroundURL = model.profileImageColoredBackgroundURL
        self.lastOnline = model.lastOnline
        self.tagline = model.tagline
        self.about = model.about
        self.updatedAt = Date()
    }
    
    func update(ign: String, ignCount: Int16) {
        self.ign = ign
        self.ignCount = ignCount
    }
}
