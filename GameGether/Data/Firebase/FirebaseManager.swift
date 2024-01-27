//
//  Firebase.swift
//  GameGether
//
//  Created by James Ajhar on 10/25/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth
import KeychainSwift

enum FirebaseManagerError: Error, Equatable, LocalizedError {
    
    case error(message: String?)
    
    var description: String {
        switch self {
        case .error(let message):
            if let message = message {
                return message
            } else {
                return "An unknown error occurred"
            }
        }
    }
    
    var errorDescription: String? {
        get {
            return self.description
        }
    }
}

class FirebaseManager {

    static func signOut() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch {
            GGLog.error("Error signing out: \(error.localizedDescription)")
        }
    }
    
    func signIn(retryAttempt: Int = 0, completion: AuthDataResultCallback? = nil) {
        
        guard DataCoordinator.shared.isUserSignedIn() else {
            Auth.auth().signInAnonymously(completion: completion)
            return
        }
        
        guard DataCoordinator.shared.signedInUser?.identifier != Auth.auth().currentUser?.uid else {
            // User is already signed in
            completion?(nil, nil)
            return
        }
        
        // Delete the stored token so we can try to fetch a new one.
        KeychainSwift().delete(AppConstants.Keychain.firebaseAuthTokenKey)
        
        guard retryAttempt < 3 else {
            // Only allow 3 retry attempts if the token request fails
            completion?(nil, FirebaseManagerError.error(message: "Sign in failed. Exceeded max retry attempts"))
            return
        }
        
        let signInBlock = { (token) in
            // Sign in with one of our JWT tokens if possible
            Auth.auth().signIn(withCustomToken: token, completion: { [weak self] (user, error) in
                if let err = error {
                    GGLog.error(err.localizedDescription)
                    
                    // Delete the stored token so we can try to fetch a new one.
                    KeychainSwift().delete(AppConstants.Keychain.firebaseAuthTokenKey)
                    // try, try again
                    self?.signIn(retryAttempt: retryAttempt + 1, completion: completion)
                    return
                }
                
                completion?(user, error)
            })
        }
        
        if let existingToken = KeychainSwift().get(AppConstants.Keychain.firebaseAuthTokenKey) {
            signInBlock(existingToken)
            
        } else {
            DataCoordinator.shared.renewFirebaseToken { (token, error) in
                guard let token = token, error == nil else {
                    GGLog.error(error?.localizedDescription ?? "unknown error")
                    completion?(nil, error)
                    return
                }
                
                signInBlock(token)
            }
        }
    }
}
