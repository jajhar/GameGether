//
//  DataCoordinator.swift
//  App
//
//  Created by James on 4/26/18.
//  Copyright © 2018 James. All rights reserved.
//

import Foundation
import KeychainSwift

enum DataCoordinatorError: Error {
    case unknown
    case userNotFound
}

class DataCoordinator {
    
    public static let shared = DataCoordinator()
    
    internal let localCoordinator = LocalCoordinator()
    internal let remoteCoordinator = RemoteCoordinator()
    
    internal var signedInUser: User? {
        didSet {
            if let oldUser = oldValue {
                // unsubscribe this device from any previous user identities
                PushNotificationsManager.shared.unsubscribe(fromUser: oldUser.identifier)
            }
            
            if let newUser = signedInUser, !newUser.identifier.isEmpty {
                // subscribe to this user for push notifications
                PushNotificationsManager.shared.subscribe(toUser: newUser.identifier)
                
                updateOnlineStatus() 
                
                // clear any cached info from the previous user
                localCoordinator.deleteAllTags()
                localCoordinator.deleteAllFollowedTags()
                localCoordinator.deleteAllGames()
                localCoordinator.deleteAllBookmarks()
            }
        }
    }
    
    internal var getProfilesCompletionBlocks = [String: [([User]?, Error?) -> Void]]()
    internal var getProfileCompletionBlocks = [String: [(User?, Error?) -> Void]]()
    
    private lazy var firebaseChat = FirebaseChat()
    private lazy var firebaseUser = FirebaseUser()
    
    public let s3Uploader = S3Uploader()
}

extension DataCoordinator {
    
    func isUserSignedIn() -> Bool {
        return DataCoordinator.shared.signedInUser != nil && DataCoordinator.shared.signedInUser?.identifier.isEmpty == false
    }
    
    func clearCache() {
        localCoordinator.deleteAllUsers()
        localCoordinator.deleteAllTags()
        localCoordinator.deleteAllFollowedTags()
        localCoordinator.deleteAllGames()
        localCoordinator.deleteAllBookmarks()
        DataCoordinator.shared.signedInUser = nil
    }
    
    func start() {
        signedInUser = localCoordinator.currentUser()
        if !isUserSignedIn() {
            clearCache()
        }
        
        // clear out any saved profiles since last app launch
        localCoordinator.deleteAllProfiles()
        
        firebaseChat.signIn()
        firebaseUser.signIn()

        if isUserSignedIn(), let signedInUser = signedInUser {
            getProfile(forUser: signedInUser.identifier) { [unowned self] (user, error) in
                if let user = user {
                    self.localCoordinator.setCurrentUser(user: user)
                }
            }
        }
    }
    
    func logout() {
        if let user = signedInUser {
            // unsubscribe this device from any previous user identities
            PushNotificationsManager.shared.unsubscribe(fromUser: user.identifier)
        }
        
        // clear all cached data
        clearCache()
        
        // clear keychain
        KeychainSwift().clear()

        // Reset onboarding flags
        UserDefaults.standard.set(false, forKey: AppConstants.UserDefaults.Onboarding.gameTagsOnboardingTooltipShown)
        UserDefaults.standard.set(false, forKey: AppConstants.UserDefaults.Onboarding.tagsChatOnboardingTooltipShown)
        UserDefaults.standard.set(false, forKey: AppConstants.UserDefaults.Onboarding.partyOnboardingTooltipShown)
        UserDefaults.standard.set(false, forKey: AppConstants.UserDefaults.Onboarding.profileSwipeTooltipShown)
        UserDefaults.standard.set(0, forKey: AppConstants.UserDefaults.Onboarding.starredLobbyTooltipShown)
        UserDefaults.standard.set(false, forKey: AppConstants.UserDefaults.Onboarding.ggHomeTutorialShown)
        UserDefaults.standard.set(false, forKey: AppConstants.UserDefaults.Onboarding.ggHomeCreateLFGTooltipShown)
        UserDefaults.standard.set(0, forKey: AppConstants.UserDefaults.Onboarding.ggHomePBTooltipShown)
        UserDefaults.standard.set(0, forKey: AppConstants.UserDefaults.Onboarding.ggHomeStarredTagsTooltipShown)
        UserDefaults.standard.synchronize()
        
        FirebaseManager.signOut()

        // GO TO onboarding screen
        NavigationManager.shared.showOnboarding()
    }
    
    func updateOnlineStatus() {
        guard isUserSignedIn(), let user = signedInUser else { return }
        
        firebaseUser.signIn() { [unowned self] (_, _) in
            // Update the signed in user's online status
            self.firebaseUser.updateOnlineStatus(forUser: user.identifier)
        }
    }
    
    func loginUser(withEmail email: String, andPassword password: String, completion: @escaping ((User?, Error?) -> Void)) {
        
        remoteCoordinator.loginUser(withEmail: email, andPassword: password) { [unowned self] (user, error) in
            
            guard error == nil, let user = user else {
                performOnMainThread {
                    completion(nil, error ?? DataCoordinatorError.unknown)
                }
                return
            }
            
            // Save the user to cache and return
            self.localCoordinator.setCurrentUser(user: user, completion: { (user, error) in
                
                performOnMainThread {
                    guard error == nil else {
                        completion(nil, error)
                        return
                    }
                
                    self.signedInUser = user
                    completion(user, nil)
                    
                    self.updateUserStatus()
                }
            })
        }
    }
    
    func loginUser(withFacebookToken token: String, completion: @escaping ((User?, Error?) -> Void)) {
        
        remoteCoordinator.loginUser(withFacebookToken: token) { [unowned self] (user, error) in
            
            guard error == nil, let user = user else {
                performOnMainThread {
                    completion(nil, error ?? DataCoordinatorError.unknown)
                }
                return
            }
            
            // Save the user to cache and return
            self.localCoordinator.setCurrentUser(user: user, completion: { (user, error) in
                
                performOnMainThread {
                    guard error == nil else {
                        completion(nil, error)
                        return
                    }
                    
                    self.signedInUser = user
                    completion(user, nil)
                }
            })
        }
    }
    
    func loginUser(withAppleUserId userId: String, completion: @escaping ((User?, Error?) -> Void)) {

        remoteCoordinator.loginUser(withAppleUserId: userId) { [unowned self] (user, error) in
            
            guard error == nil, let user = user else {
                performOnMainThread {
                    completion(nil, error ?? DataCoordinatorError.unknown)
                }
                return
            }
            
            // Save the user to cache and return
            self.localCoordinator.setCurrentUser(user: user, completion: { (user, error) in
                
                performOnMainThread {
                    guard error == nil else {
                        completion(nil, error)
                        return
                    }
                    
                    self.signedInUser = user
                    completion(user, nil)
                }
            })
        }

    }
    
    func loginUser(withGoogleToken token: String, completion: @escaping ((User?, Error?) -> Void)) {
        
        remoteCoordinator.loginUser(withGoogleToken: token) { [unowned self] (user, error) in
            
            guard error == nil, let user = user else {
                performOnMainThread {
                    completion(nil, error ?? DataCoordinatorError.unknown)
                }
                return
            }
            
            // Save the user to cache and return
            self.localCoordinator.setCurrentUser(user: user, completion: { (user, error) in
                
                performOnMainThread {
                    guard error == nil else {
                        completion(nil, error)
                        return
                    }
                    
                    self.signedInUser = user
                    completion(user, nil)
                }
            })
        }
    }
    
    func register(user: User, completion: @escaping ((User?, Error?) -> Void)) {
        
        let keychain = KeychainSwift()
        let password = keychain.get(AppConstants.Keychain.password)

        remoteCoordinator.register(user: user, andPassword: password) { [unowned self] (user, error) in
            
            guard error == nil, let user = user else {
                performOnMainThread {
                    completion(nil, error ?? DataCoordinatorError.unknown)
                }
                return
            }
            
            // Destroy the password since it's no longer necesssary.
            keychain.set("", forKey: AppConstants.Keychain.password)

            // Save the user to cache and return
            self.localCoordinator.setCurrentUser(user: user, completion: { (user, error) in
                
                performOnMainThread {
                    guard error == nil else {
                        completion(nil, error)
                        return
                    }
                    
                    self.signedInUser = user
                    completion(user, nil)
                }
            })
        }
    }
    
    func checkIGNAvailability(ign: String, completion: @escaping (Int, Error?) -> Void) {
        
        remoteCoordinator.checkIGNAvailability(ign: ign) { (count, error) in
            performOnMainThread {
                completion(count, error)
            }
        }
    }
    
    func checkEmailAvailability(email: String, completion: @escaping (Bool, Error?) -> Void) {
        
        remoteCoordinator.checkEmailAvailability(email: email) { (isAvailable, error) in
            performOnMainThread {
                completion(isAvailable, error)
            }
        }
    }
    
    /// Call to create an instance of a logged in user and save it to cache.
    ///
    /// - Parameters:
    ///   - email: The email of the user
    ///   - password: The optional password (if no password is provided, the API will generate one (social media registrations ONLY!)
    ///   - completion: <#completion description#>
    func createLocalUser(withEmail email: String, password: String? = nil, completion: @escaping ((User?, Error?) -> Void)) {
        let user = UserObject(email: email)
        let keychain = KeychainSwift()
        
        if let password = password {
            keychain.set(password, forKey: AppConstants.Keychain.password)
        }

        localCoordinator.setCurrentUser(user: user) { [weak self] (user, error) in
            performOnMainThread {
                
                guard error == nil else {
                    completion(nil, error)
                    return
                }
                
                self?.signedInUser = user
                completion(user, error)
            }
        }
    }
    
    func updateLocalUser(withIGN ign: String, profileImageURL: URL? = nil, profileImageColoredBackgroundURL: URL? = nil, completion: @escaping ((User?, Error?) -> Void)) {
        guard let user = signedInUser else {
            completion(nil, DataCoordinatorError.userNotFound)
            return
        }
        
        // Doesn't matter what ignCount is here. The API will define this # on user creation.
        user.update(ign: ign, ignCount: 1)
        user.profileImageURL = profileImageURL
        user.profileImageColoredBackgroundURL = profileImageColoredBackgroundURL
        
        localCoordinator.updateCurrentUser(withProperties: user) { (user, error) in
            
            performOnMainThread {
                guard error == nil else {
                    completion(nil, error)
                    return
                }
                
                self.signedInUser = user
                completion(user, error)
            }
        }
    }
    
    func updateLocalUser(withBirthday birthday: Date, completion: @escaping ((User?, Error?) -> Void)) {
        guard let user = signedInUser else {
            completion(nil, DataCoordinatorError.userNotFound)
            return
        }
        
        user.birthday = birthday
        
        localCoordinator.updateCurrentUser(withProperties: user) { (user, error) in
            
            performOnMainThread {
                guard error == nil else {
                    completion(nil, error)
                    return
                }
                
                self.signedInUser = user
                completion(user, error)
            }
        }
    }
    
    func sendForgotPasswordEmail(toEmail email: String, completion: @escaping ((Error?) -> Void)) {
        remoteCoordinator.sendForgotPasswordEmail(toEmail: email, completion: completion)
    }
    
    func resetPassword(newPassword password: String, completion: @escaping ((Error?) -> Void)) {
        remoteCoordinator.resetPassword(newPassword: password, completion: completion)
    }
    
    func updateUserStatus(_ completion: ((Error?) -> Void)? = nil) {
        guard isUserSignedIn() else {
            // User isn't signed in. Fire and forget mentality = no error
            completion?(nil)
            return
        }
        
        remoteCoordinator.updateUserStatus { (error) in
            completion?(error)
        }
    }
    
    func updateHighlights(tagline: String,
                          about: String,
                          completion: @escaping (User?, Error?) -> Void) {
        guard let signedInUser = signedInUser else {
            completion(nil, DataCoordinatorError.userNotFound)
            return
        }
        
        remoteCoordinator.updateHighlights(tagline: tagline, about: about) { [unowned self] (error) in
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            signedInUser.tagline = tagline
            signedInUser.about = about
            self.localCoordinator.updateCurrentUser(withProperties: signedInUser)
            completion(signedInUser, nil)
        }
    }
    
    func updateProfileMedia(media: [ProfileMedia], completion: @escaping (User?, Error?) -> Void) {
        guard let signedInUser = signedInUser else {
            completion(nil, DataCoordinatorError.userNotFound)
            return
        }
        
        remoteCoordinator.updateProfileMedia(media: media) { (error) in
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            completion(signedInUser, nil)
        }
    }
    
    func updateSocialLinks(socialLinks: [SocialLink], completion: @escaping (User?, Error?) -> Void) {
        guard let signedInUser = signedInUser else {
            completion(nil, DataCoordinatorError.userNotFound)
            return
        }
        
        remoteCoordinator.updateSocialLinks(socialLinks: socialLinks) { (error) in
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            completion(signedInUser, nil)
        }
    }
    
    func updateProfileImage(withImageURL imageURL: String, completion: @escaping ((User?, Error?) -> Void)) {
        
        guard let user = signedInUser else {
            completion(nil, DataCoordinatorError.userNotFound)
            return
        }
        
        remoteCoordinator.updateProfileImage(withImageURL: imageURL) { [unowned self] (error) in
            
            guard error == nil else {
                performOnMainThread {
                    completion(nil, error ?? DataCoordinatorError.unknown)
                }
                return
            }
            
            user.profileImageURL = URL(string: imageURL)
            
            self.localCoordinator.updateCurrentUser(withProperties: user, completion: { (updatedUser, error) in
                
                performOnMainThread {
                    guard error == nil else {
                        completion(nil, error)
                        return
                    }
                    
                    self.signedInUser = updatedUser
                    
                    // Notify observers of the profile pic change
                    NotificationCenter.default.post(name: UserNotifications.updatedProfileImage.name, object: nil)
                    
                    completion(self.signedInUser, error)
                }
            })
        }
    }
        
    func addFriend(withUserId userId: String, completion: @escaping ((Error?, FRChatroom?) -> Void)) {
        remoteCoordinator.addFriend(withUserId: userId) { [unowned self] (error) in
            
            guard error == nil else {
                completion(error, nil)
                return
            }
            
            self.firebaseChat.createPrivateRoom(withUserIds: [userId], completion: { (chatroom) in
                self.localCoordinator.deleteProfiles(withUserIds: [userId], nil)
                self.localCoordinator.deleteAllFriends(nil)
                completion(nil, chatroom)
            })
        }
    }
    
    func acceptFriendRequest(fromUser userId: String, completion: @escaping ((Error?) -> Void)) {
        remoteCoordinator.acceptFriendRequest(fromUser: userId) { [unowned self] (error) in
            guard error == nil else {
                completion(error)
                return
            }

            self.localCoordinator.deleteProfiles(withUserIds: [userId], nil)
            self.localCoordinator.deleteAllFriends(nil)
            completion(nil)
        }
    }
    
    func cancelFriendRequest(toUser userId: String, completion: @escaping ((Error?) -> Void)) {
        remoteCoordinator.cancelFriendRequest(toUser: userId) { [unowned self] (error) in
            guard error == nil else {
                completion(error)
                return
            }
            
            self.localCoordinator.deleteProfiles(withUserIds: [userId], nil)
            self.localCoordinator.deleteAllFriends(nil)
            completion(nil)
        }
    }
    
    func getFriends(ignoreCache: Bool = false, completion: @escaping (([User]?, Error?) -> Void)) {
        
        localCoordinator.getFriends { [unowned self] (cachedFriends, error) in

            if !ignoreCache, error == nil, let friends = cachedFriends, !friends.isEmpty {
                completion(friends, nil)
                return
            }
            
            // Nothing cached, fetch from remote
            self.remoteCoordinator.getFriends { (friends, error) in
                
                performOnMainThread {
                    guard error == nil, let friends = friends else {
                        completion(nil, error)
                        return
                    }
                    
                    completion(friends, error)
                    
                    self.localCoordinator.saveFriends(friends: friends, completion: nil)
                }
            }
        }
    }
    
    func getFriendStatus(forUser userId: String, completion: @escaping ((UserRelationship?, Error?) -> Void)) {
        remoteCoordinator.getFriendStatus(forUser: userId, completion: completion)
    }
    
    func blockUser(_ userId: String, _ completion: @escaping ((Error?) -> Void)) {
        remoteCoordinator.blockUser(userId, completion)
        localCoordinator.deleteProfiles(withUserIds: [userId], nil)
    }
    
    func unblockUser(_ userId: String, _ completion: @escaping ((Error?) -> Void)) {
        remoteCoordinator.unblockUser(userId, completion)
        localCoordinator.deleteProfiles(withUserIds: [userId], nil)
    }
    
    func getBlockedUsers(_ completion: @escaping (([User], Error?) -> Void)) {
        remoteCoordinator.getBlockedUsers { (blockedUsers, error) in
            // TODO: More stuff here!
            completion(blockedUsers, error)
        }
    }

    func getProfile(forUser userId: String, allowCache: Bool = true, completion: @escaping ((User?, Error?) -> Void)) {
        
        guard getProfileCompletionBlocks[userId] == nil else {
            getProfileCompletionBlocks[userId]?.append(completion)
            return
        }
        
        getProfileCompletionBlocks[userId] = [completion]
        
        localCoordinator.getProfiles(withUserIds: [userId]) { (cachedProfiles, error) in
            
            if allowCache, let profile = cachedProfiles.first {
                if let completions = self.getProfileCompletionBlocks[userId] {
                    for completion in completions {
                        completion(profile, nil)
                    }
                }
                self.getProfileCompletionBlocks[userId] = nil
                return
            }
            
            self.remoteCoordinator.getProfiles(forUsersWithIds: [userId]) { (profiles, error) in
                performOnMainThread {
                    
                    guard error == nil, let profile = profiles?.first else {
                        if let completions = self.getProfileCompletionBlocks[userId] {
                            for completion in completions {
                                completion(nil, error)
                            }
                        }
                        self.getProfileCompletionBlocks[userId] = nil
                        return
                    }
                    
                    // Save the user to cache
                    self.localCoordinator.saveProfiles(profiles: [profile], completion: nil)
                    
                    if let completions = self.getProfileCompletionBlocks[userId] {
                        for completion in completions {
                            completion(profile, nil)
                        }
                    }
                    self.getProfileCompletionBlocks[userId] = nil
                }
            }
        }
    }
    
    func getProfiles(forUsersWithIds userIds: [String], allowCache: Bool = true, completion: @escaping (([User]?, Error?) -> Void)) {
        
        guard userIds.count > 0 else {
            completion([], nil)
            return
        }
        
        let hash = userIds.joined(separator: "")
        
        guard getProfilesCompletionBlocks[hash] == nil else {
            getProfilesCompletionBlocks[hash]?.append(completion)
            return
        }
        
        getProfilesCompletionBlocks[hash] = [completion]

        localCoordinator.getProfiles(withUserIds: userIds) { (cachedProfiles, error) in
            
            if allowCache, cachedProfiles.count == userIds.count {
                if let completions = self.getProfilesCompletionBlocks[hash] {
                    for completion in completions {
                        completion(cachedProfiles, nil)
                    }
                }
                self.getProfilesCompletionBlocks[hash] = nil
                return
            }

            self.remoteCoordinator.getProfiles(forUsersWithIds: userIds) { (profiles, error) in
                performOnMainThread {
                    
                    guard error == nil, let profiles = profiles else {
                        if let completions = self.getProfilesCompletionBlocks[hash] {
                            for completion in completions {
                                completion(nil, error)
                            }
                        }
                        self.getProfilesCompletionBlocks[hash] = nil
                        return
                    }
                    
                    // Save the users to cache
                    self.localCoordinator.saveProfiles(profiles: profiles, completion: nil)

                    if let completions = self.getProfilesCompletionBlocks[hash] {
                        for completion in completions {
                            completion(profiles, nil)
                        }
                    }
                    self.getProfilesCompletionBlocks[hash] = nil
                }
            }
        }
    }
    
    func search(forUsersWithIGN ign: String, andIGNCount count: Int?, completion: @escaping (([User]?, Error?) -> Void)) {
        remoteCoordinator.search(forUsersWithIGN: ign, andIGNCount: count, completion: completion)
    }
}

extension DataCoordinator {
    
    /// Call to get users that are following a set of tags
    ///
    /// - Parameters:
    ///   - gameId: The game that the tags belong to
    ///   - tags: The tags that the users follow
    ///   - offset: The current page offset
    ///   - completion: Returns the Users fetched, the current page offset as a string, an error if one occurred

    func getUsersFollowingTags(forGame gameId: String, withTags tags: [String], offset: String?, completion: @escaping (([User]?, String?, Error?) -> Void)) {
        remoteCoordinator.getUsersFollowingTags(forGame: gameId, withTags: tags, offset: offset, completion: completion)
    }
    
    /// Call to fetch a new auth token from the firebase server
    ///
    /// - Parameter completion: returns the new token or an error
    func renewFirebaseToken(completion: @escaping ((String?, Error?) -> Void)) {
        remoteCoordinator.renewFirebaseToken(completion: completion)
    }
    
    /// Call to begin updating this user's status every 5 minutes so other's know they are currently online
    func beginUserStatusUpdatePolling() {
        updateUserStatus()  // fire immediately
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { (_) in
            self.updateUserStatus()
            self.updateOnlineStatus()
        }
    }
}
