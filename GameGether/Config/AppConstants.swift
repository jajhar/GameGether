//
//  AppConstants.swift
//  GameGether
//
//  Created by James Ajhar on 6/19/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation
import UIKit

struct AppConstants {
    
    struct Keychain {
        static let remoteTokenKey = "KEYCHAIN_REMOTE_AUTH_TOKEN"
        static let firebaseAuthTokenKey = "FIREBASE_AUTH_TOKEN"
        static let password = "KEYCHAIN_USER_PASSWORD"
        static let appleUserIdentifier = "APPLE_USER_IDENTIFIER"
    }
    
    struct UserDefaults {
        static let mutedChatrooms = "GG_MUTED_CHATROOMS"
        static let micNotificationWasShown = "GG_MIC_NOTIFICATION_WAS_SHOWN"
        static let videosMuted = "GG_VIDEOS_MUTED"
        static let recentlySharedGIFs = "GG_RECENTLY_SHARED_GIFS"
        static let microphoneVolumeLevel = "GG_VOICE_MIC_VOLUME_LEVEL"
        static let activePartyAlertShown = "GG_ACTIVE_PARTY_ALERT_SHOWN"
        static let showVoiceCallForceEjectAlert = "GG_VOICE_EJECT_ALERT"
        
        struct Onboarding {
            static let gameTagsOnboardingTooltipShown = "GG_GAME_TAGS_TOOLTIP_SHOWN"
            static let tagsChatOnboardingTooltipShown = "GG_TAGS_CHAT_TOOLTIP_SHOWN"
            static let partyOnboardingTooltipShown = "GG_PARTY_TOOLTIP_SHOWN"
            static let profileSwipeTooltipShown = "GG_PROFILE_SWIPE_TOOLTIP_SHOWN"
            static let starredLobbyTooltipShown = "GG_STARRED_LOBBY_TOOLIP_SHOWN"
            static let pushNotificationAccessAlertShown = "GG_PUSH_NOTIFICATION_ACCESS_ALERT_SHOWN"
            static let microphoneAccessAlertShown = "GG_MICROPHONE_ACCESS_ALERT_SHOWN"
            static let ggHomeTutorialShown = "GG_HOME_TUTORIAL_SHOWN"
            static let ggHomeCreateLFGTooltipShown = "GG_HOME_CREATE_LFG_TOOLTIP_SHOWN"
            static let ggHomePBTooltipShown = "GG_HOME_PB_TOOLTIP_SHOWN"
            static let ggHomeStarredTagsTooltipShown = "GG_HOME_STARRED_TAGS_TOOLTIP_SHOWN"
        }

        static func lastKnownGameScreen(for game: Game) -> String {
            return "GG_LAST_GAME_SCREEN_FOR_\(game.identifier)"
        }
        
        static func generalLobbyTagBookmark(for game: Game) -> String {
            return "GG_GENERAL_LOBBY_TAG_BOOKMARK_FOR_\(game.identifier)"
        }
    }
    
    struct AWS {
        static let s3Bucket = "gamegether-west"
        static let cdn = "https://d29y84nmsvv3wc.cloudfront.net"
        static let S3IdentityPoolIdentifier = "us-west-2:e6e0b20a-66f6-4e88-b08b-25f37d6b3089"
    }
    
    struct Storyboards {
        static let onboarding = "Onboarding"
        static let game = "Game"
        static let forgotPassword = "ForgotPassword"
        static let resetPassword = "ResetPassword"
        static let chat = "Chat"
        static let main = "Main"
        static let friends = "Friends"
        static let profile = "Profile"
        static let giphy = "Giphy"
        static let tabBar = "TabBarStoryboard"
        static let aiPopUps = "GGAIPopUps"
        static let ggHome = "StarredLobbiesStoryboard"
        static let scheduling = "Scheduling"
        static let lfg = "LFGStoryboard"
        static let ggShortcuts = "GGShortcutsStoryboard"
    }   
    
    enum Fonts {
        
        case robotoLight(CGFloat)
        case robotoRegular(CGFloat)
        case robotoMedium(CGFloat)
        case robotoBold(CGFloat)
        
        case twCenMTRegular(CGFloat)

        var font: UIFont {
            switch self {
            case .robotoLight(let size):
                return UIFont(name: "Roboto-Light", size: size)!
            case .robotoRegular(let size):
                return UIFont(name: "Roboto-Regular", size: size)!
            case .robotoMedium(let size):
                return UIFont(name: "Roboto-Medium", size: size)!
            case .robotoBold(let size):
                return UIFont(name: "Roboto-Bold", size: size)!
            case .twCenMTRegular(let size):
                return UIFont(name: "Tw Cen MT", size: size)!
            }
        }
    }
    
    enum Colors {
        
        case textFieldErrorBorder
        case tagPillColor
        case newMessageTabButtonUnselected
        case newMessageTabButtonSelected
        case messageAction
        case ggBlue

        var color: UIColor {
            switch self {
            case .textFieldErrorBorder:
                return UIColor(red: 250/255.0, green: 153/255.0, blue: 23/255.0, alpha: 1.0)
            case .tagPillColor:
                return UIColor(hexString: "#3E3E3E")
            case .newMessageTabButtonSelected:
                return UIColor(hexString: "#57A2E1")
            case .newMessageTabButtonUnselected:
                return UIColor(hexString: "#E0E0E0")
            case .messageAction:
                return UIColor(hexString: "#bdbdbd")
            case .ggBlue:
                return UIColor(hexString: "#3399FF")
            }
        }
    }
    
    enum PushNotificationType: Int {
        case newChatMessage
        case friendRequest
        case friendOnline
        case partyCreated
        case voiceChat
        case sessionStartingSoon
        case sessionStartingNow
    }
}

