//
//  AnalyticsManager.swift
//  GameGether
//
//  Created by James Ajhar on 7/8/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation
import FirebaseCore
import FirebaseAnalytics
import Analytics.SEGAnalytics
import AppsFlyerLib
import FBSDKCoreKit

public enum AnalyticEvent: String {
    
    // Onboarding
    case onboardingSignInPressed = "onboarding_sign_in_pressed"
    case onboardingExplorePressed = "onboarding_explore_pressed"
    case onboardingAppleSignInPressed = "onboarding_apple_sign_in_pressed"
    case onboardingGoogleSignInPressed = "onboarding_google_sign_in_pressed"
    case onboardingFacebookSignInPressed = "onboarding_facebook_sign_in_pressed"

    // Login Screen
    case loginPressed = "login_button_pressed"
    case loginForgotPasswordPressed = "login_forgot_button_pressed"
    case loginBackButtonPressed = "login_back_button_pressed"

    // Create Account
    case registerBackButtonPressed = "register_back_button_pressed"
    case createAccountButtonPressed = "create_account_button_pressed"
    case createAccountSuccess = "create_account_success"
    
    // Birthday Picker
    case birthdayBackButtonPressed = "birthday_back_button_pressed"
    case birthdayNextButtonPressed = "birthday_next_button_pressed"

    // Select Gamer Tag Screen
    case selectIGNBackButtonPressed = "select_ign_back_button_pressed"
    case selectIGNNextButtonPressed = "select_ign_next_button_pressed"
    case profileBackgroundColorSelected = "profile_background_color_selected"
    case onboardingUploadProfilePicPressed = "onboarding_upload_profile_pic_pressed"

    // Forgot Password
    case forgotPasswordSendButtonPressed = "forgot_password_send_button_pressed"
    case forgotPasswordBackButtonPressed = "forgot_password_back_button_pressed"
    
    // Reset Password
    case resetPasswordConfirmPressed = "reset_password_confirm_button_pressed"
    case resetPasswordBackPressed = "reset_password_back_button_pressed"

    // Profile
    case profileGameIconTapped = "profile_game_icon_pressed"
    case profileSocialIconTapped = "profile_social_icon_pressed"
    case profileAskToPlayTapped = "profile_ask_to_play_pressed"
    case profileAddFriendTapped = "profile_add_friend_pressed"
    case profileEditProfilePicTapped = "profile_edit_pic_pressed"
    case profileEditMediaTapped = "profile_edit_media_pressed"
    case profileEditButtonTapped = "profile_edit_button_pressed"
    case profileChangeMediaTapped = "profile_change_media_pressed"
    case profileDeleteMediaTapped = "profile_delete_media_pressed"
    case profileCancelEditMediaTapped = "profile_cancel_edit_media_pressed"
    case profileSendMessageTapped = "profile_send_message_pressed"
    case profileCancelSendMessageTapped = "profile_cancel_send_message_pressed"

    // Gamer Tag Pop Up View
    case profileEditGamerTagPressed = "edit_gamer_tag_pressed"
    case profileSaveGamerTagPressed = "save_gamer_tag_pressed"
    case profileRemoveGamerTagPressed = "remove_gamer_tag_pressed"
    case gamerTagCopied = "gamer_tag_copied"

    // MARK: - Chat
    
    // MARK: Messages SubHeader
    case chatSubheaderMessagesSelected = "chat_subheader_messages_selected"
    case chatSubheaderLFGSelected = "chat_subheader_lfg_selected"
    case chatSubheaderFriendsSelected = "chat_subheader_friends_selected"
    
    case chatroomOpened = "chat_open_msg"
    case lfgOpened  = "LFG_open_msg"
    
    // MARK: Manage Chat
    case chatInfoButtonPressed = "chat_manage_button_pressed"
    case manageChatEditButtonPressed = "chat_manage_edit_pressed"
    case manageChatEditNameButtonPressed = "chat_manage_edit_name_pressed"
    case manageChatEditPhotoButtonPressed = "chat_manage_edit_photo_pressed"
    case manageChatNotificationsOff = "chat_manage_notif_off"
    case manageChatNotificationsOn = "chat_manage_notif_on"
    case manageChatLeaveButtonPressed = "chat_manage_leave_pressed"

    case chatGGPopUpCreateGroupPressed = "chat_gg_create_group_pressed"
    case tappedChatMessageTags = "chat_message_tags_pressed"
    case micOn = "mic_on_pressed"
    case micOff = "mic_off_pressed"
    case voiceOverlayBackPressed = "voice_overlay_back_pressed"
    case voiceVolumeChanged = "voice_volume_changed"
    case gameHomeButtonTapped = "game_home_button_pressed"
    case gameChatButtonTapped = "game_chat_button_pressed"
    case gameActiveUsersButtonTapped = "game_active_users_button_pressed"
    case voiceEjectAlertButtonTapped = "voice_eject_alert_button_pressed"
    case chatroomUserSelected = "chatroom_user_selected"
    case messageSent = "message_sent"

    // Lobby
    case gameTagsGeneralLobbyPressed = "game_tags_general_lobby_pressed"
    case gameTagsEmptyStatePressed = "game_tags_empty_state_pressed"
    case lobbyWalkthroughClosePressed = "lobby_walkthrough_close_pressed"
    case lobbyWalkthroughGoToLobbyPressed = "lobby_walkthrough_go_to_lobby_pressed"
    case lobbyGamerTagModalSavePressed = "lobby_gamertag_modal_save_pressed"
    case lobbyGamerTagModalSkipPressed = "lobby_gamertag_modal_skip_pressed"

    // Friends
    case addFriendPressed = "add_friend_button_pressed"
    case friendSelected = "friend_selected"

    // Party
    case createdParty = "created_party"
    case leftParty = "left_party"
    case joinedParty = "joined_party"
    case partyFilled = "party_filled"
    case partyAlertLeave = "party_alert_leave"
    case partyAlertStay = "party_alert_stay"
    case expandedPartyTable = "expanded_party_table"
    case collapsedPartyTable = "collapsed_party_table"

    // GG Activity Indicator
    case activityIndicatorTapped = "activity_indicator_pressed"
    case seeOtherPartiesTapped = "see_other_parties_pressed"

    // Select game
    case savedGame = "select_game_tapped_save"
    case removedGame = "select_game_tapped_remove"
    case selectGameGenreSelected = "select_game_genre_selected"
    case selectGameByGenreTapped = "select_game_by_genre_pressed"
    case selectGameSupportedTapped = "select_game_supported_pressed"
    case selectGameDoneTapped = "select_game_done_pressed"

    // Profile Quick View
    case quickViewProfileImageTapped = "quick_view_profile_pressed"
    case quickViewPlayWithTapped = "quick_view_play_with_pressed"
    case quickViewPlayWithCreateGroupTapped = "quick_view_create_group_pressed"
    case quickViewPlayWithSendMessageTapped = "quick_view_send_message_pressed"
    case quickViewPlayWithCancelTapped = "quick_view_play_with_cancel_pressed"
    case quickViewIGNTapped = "quick_view_ign_pressed"
    case quickViewOpened = "quick_view_opened"
    case quickViewClosed = "quick_view_closed"
    case quickViewGamerTagsTapped = "quick_view_gamer_tags_pressed"

    // Giphy
    case giphyIconTapped = "giphy_icon_pressed"
    case giphyReactionsButtonTapped = "giphy_reactions_pressed"
    case giphyTrendingButtonTapped = "giphy_trending_pressed"
    case giphyCloseButtonTapped = "giphy_close_pressed"
    case giphySearchButtonTapped = "giphy_search_pressed"

    // Chatrooms
    case chatroomFilterSelected = "chatroom_filter_selected"
    case createNewChatroomTapped = "create_chat_pressed"
    
    // Navigation Overlay
    case navigationOverlayProfileButtonTapped = "nav_profile_pressed"
    case navigationOverlayChatButtonTapped = "nav_chat_pressed"
    case navigationOverlayGGButtonTapped = "nav_GG_pressed"
    case navigationOverlayFriendsButtonTapped = "nav_friends_pressed"
    case navigationOverlayKeyboardButtonTapped = "nav_keyboard_pressed"
    case navigationOverlayProfileButtonSwiped = "nav_profile_swiped"
    case navigationOverlayChatButtonSwiped = "nav_chat_swiped"
    case navigationOverlayFriendsButtonSwiped = "nav_friends_swiped"
    case navigationOverlayJoystickSwipeDown = "nav_joystick_swipe_down"
    case navigationOverlayJoystickSwipeUp = "nav_joystick_swipe_up"
    case navigationOverlayGameSelected = "nav_game_selected"

    // MARK: - Scheduling
    
    // Create session
    case scheduleSessionCreateTapped = "schedule_session_create_tapped"
    case scheduleSessionCancelTapped = "schedule_session_cancel_tapped"
    case scheduleSessionGameIconTapped = "schedule_session_game_icon_tapped"
    case scheduleSessionCalendarTapped = "schedule_session_calendar_tapped"
    case scheduleSessionCalendarDateSelected = "schedule_session_calendar_date_selected"
    case scheduleSessionTomorrowButtonTapped = "schedule_session_tomorrow_tapped"
    case scheduleSessionJoinButtonTapped = "schedule_session_join_tapped"
    case scheduleSessionBackButtonTapped = "schedule_session_back_tapped"
    
    // Sessions
    case sessionJoined = "session_joined"
    case sessionLeft = "session_left"
    case sessionEmptyStateTapped = "session_empty_state_tapped"
    case sessionNotificationStartingSoonTapped = "session_notification_starting_soon_tapped"
    case sessionNotificationStartingNowTapped = "session_notification_starting_now_tapped"

    // MARK: - Game Session Details
    case gameSessionSelected = "session_selected"
    case sessionDetailsGoToLobbyTapped = "session_details_go_to_lobby_tapped"
    case sessionDetailCloseTapped = "session_details_close_tapped"

    // Select Game
    case scheduleSessionGameSelected = "schedule_session_game_selected"
    case scheduleSessionSelectGameCancelTapped = "schedule_session_select_game_cancel_tapped"

    // MARK: - Home
    case ggHomeStarredLobbiesPressed = "gg_home_starred_lobbies_pressed"
    case ggHomePlayLaterTabSelected = "gg_home_play_later_tab_selected"
    case ggHomeStarredLobbiesTabSelected = "gg_home_lobbies_tab_selected"
    case ggHomeMySessionsFilterTapped = "gg_home_my_sessions_filter_tapped"
    case ggHomeAllSessionsFilterTapped = "gg_home_all_sessions_filter_tapped"
    case playNowSessionSelected = "play_now_session_selected"
    case onboardingNotificationsNextTapped = "onboarding_notifications_next_tapped"
    case onboardingMicrophoneNextTapped = "onboarding_microphone_next_tapped"
    case onboardingBottomNavNextTapped = "onboarding_bottom_nav_next_tapped"
    case onboardingPlayWithNextTapped = "onboarding_play_with_next_tapped"
    case onboardingGameTagsNextTapped = "onboarding_game_tags_next_tapped"
    case onboardingSwipeTutorialSwiped = "onboarding_swipe_gg_icon_swiped"
    
    // MARK: - GG Shortcuts
    case shortcutsAddGameTapped = "gg_shortcut_add_game_tapped"
    case shortcutsCreateSessionTapped = "gg_shortcut_create_session_tapped"
    case shortcutsCreateRequestTapped = "gg_shortcut_create_request_tapped"
    case shortcutsCloseTapped = "gg_shortcut_close_tapped"

    // MARK: - Blocking & Reporting
    case blockUserButtonPressed = "block_user_button_pressed"
    case blockUserYesPressed = "block_user_yes_pressed"
    case blockUserNoPressed = "block_user_no_pressed"
    case unblockUserButtonPressed = "unblock_user_button_pressed"
    case unblockUserYesPressed = "unblock_user_yes_pressed"
    case unblockUserNoPressed = "unblock_user_no_pressed"
    case reportUserButtonPressed = "report_user_button_pressed"
    
    // MARK: - Create LFG
    case createLFGCancelPressed = "create_lfg_cancel_pressed"
    case createLFGPostPressed = "create_lfg_post_pressed"

}

protocol AnalyticsManagerInterface {
    static func track(event: AnalyticEvent, withParameters parameters: JSONDictionary?)
}

struct AnalyticsManager: AnalyticsManagerInterface {
    
    static func track(event: AnalyticEvent, withParameters parameters: JSONDictionary? = nil) {
        var params = parameters ?? [:]
        params["userId"] = DataCoordinator.shared.signedInUser?.identifier ?? "unknown"
        params["ign"] = DataCoordinator.shared.signedInUser?.ign ?? "unknown"

        // Firebase
        Analytics.logEvent(event.rawValue, parameters: params)
        
        // Segment
        SEGAnalytics.shared()?.track(event.rawValue, properties: params)
        
        // AppsFlyer
        AppsFlyerTracker.shared().trackEvent(event.rawValue, withValues: params)
        
        // Facebook
        AppEvents.logEvent(AppEvents.Name(event.rawValue), parameters: params)
    }
}
