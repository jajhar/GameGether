//
//  AppDelegate.swift
//  GameGether
//
//  Created by James Ajhar on 6/16/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit
import SwiftyBeaver
import Firebase
import AWSCore
import AWSCognito
import AWSMobileClient
import KeychainSwift
import UserNotifications
import Firebase
import FirebaseFirestore
import AVFoundation
import FBSDKCoreKit
import GoogleSignIn
import NotificationBannerSwift
import GiphyCoreSDK
import Fabric
import Crashlytics
import AirshipKit
import Analytics.SEGAnalytics
import Segment_Amplitude
import AppsFlyerLib
import SDWebImage

let GGLog = SwiftyBeaver.self

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    private var animatedLaunchTimer: Timer?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
                
        // Override point for customization after application launch.
        configureLogs()
        
        FirebaseApp.configure()
        
        let segmentConfig = SEGAnalyticsConfiguration(writeKey: "GCIrbAkpdabJnKrnyi3QhNpFMnpj1nio")
        segmentConfig.use(SEGAmplitudeIntegrationFactory.instance())
        segmentConfig.trackApplicationLifecycleEvents = true
        segmentConfig.recordScreenViews = true
        SEGAnalytics.setup(with: segmentConfig)
        
        // Apps Flyer
        configureAppsFlyer()
        
        // Configure SDWebImage
//        SDImageCache.shared().config.shouldCacheImagesInMemory = false
        SDImageCache.shared().config.maxCacheAge = 3600 * 24 * 7 // 1 Week
        SDImageCache.shared().maxMemoryCost = 1024 * 1024 * 4 * 20 // 20 images (1024 * 1024 pixels)
        
        #if DEBUG
        Firestore.enableLogging(true)
        #endif
        
        // Urban Airship
        UAirship.takeOff()
        UAirship.push()?.pushNotificationDelegate = self

        // Crashlytics
        Fabric.with([Crashlytics.self])
        
        GiphyCore.configure(apiKey: "GXA1RBtgGmAPP4bCx69ESu6jNTBNeWly")
        
        // Facebook SDK
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        // Google Sign in SDK
        GIDSignIn.sharedInstance().clientID = "443126323113-gieu3ct7v0uj22oerodao6hiah6djfnf.apps.googleusercontent.com"
        
        configureAWS()
        
        // Run initial startup configuration
        DataCoordinator.shared.start()
        
        window = FloatingViewWindow()
        window?.makeKeyAndVisible()
        NavigationManager.shared.window = self.window as? FloatingViewWindow
        
        showAnimatedLaunchScreen()
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        if DataCoordinator.shared.isUserSignedIn() {
            PushNotificationsManager.shared.registerForRemoteNotifications()
        }
        
        DataCoordinator.shared.beginUserStatusUpdatePolling()
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        AgoraManager.shared.beginBackgroundMonitoring()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        DataCoordinator.shared.updateUserStatus()
        
        AgoraManager.shared.endBackgroundMonitoring()
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        showVoiceEjectAlertIfNeeded()
        
        DataCoordinator.shared.updateOnlineStatus()
        
        // For some reason the damn joystick keeps going off center when app is backgrounded and foregrounded...
        NavigationManager.shared.navigationOverlay?.joyStickView.resetJoystick()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            NavigationManager.shared.navigationOverlay?.joyStickView.resetJoystick()
        }
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        AppsFlyerTracker.shared().trackAppLaunch()

        showVoiceEjectAlertIfNeeded()
        DataCoordinator.shared.updateOnlineStatus()
        
        // Call the 'activate' method to log an app event for use
        // in analytics and advertising reporting.
        AppEvents.activateApp()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        if let activeChannel = AgoraManager.shared.activeChannel {
            AgoraManager.shared.leaveChannel(withId: activeChannel)
        }
        
        if let party = FirebasePartyManager.shared.activeParty {
            let firebaseParty = FirebaseParty()
            firebaseParty.signIn()
            firebaseParty.leaveParty(party, completion: { (error) in
                if let error = error {
                    GGLog.error(error.localizedDescription)
                }
            })
        }
    }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        SDImageCache.shared().clearMemory()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        AppsFlyerTracker.shared().continue(userActivity, restorationHandler: nil)
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        AppsFlyerTracker.shared().handleOpen(url, options: options)
       
        if ApplicationDelegate.shared.application(app, open: url, options: options) == true {
            // Allow Facebook SDK to handle the URL first
            return true
        }
        
        if GIDSignIn.sharedInstance().handle(url as URL?) {
            // Allow Google SDK to handle the URL first
            return true
        }

        guard url.host == "GameGether" else { return false }
        
        if url.path == "/resetPassword" {
            
            guard let token = url.queryParams["token"] else {
                GGLog.debug("No token found within deep link url: \(url.absoluteString)")
                return false
            }
            
            // Store the Auth token
            let keychain = KeychainSwift()
            keychain.set(token, forKey: AppConstants.Keychain.remoteTokenKey)

            let viewController = UIStoryboard(name: AppConstants.Storyboards.resetPassword, bundle: nil).instantiateViewController(withIdentifier: ResetPasswordViewController.storyboardIdentifier)
            
            if let navController =  window?.rootViewController as? UINavigationController {
                navController.pushViewController(viewController, animated: true)
            } else {
                window?.rootViewController?.navigationController?.pushViewController(viewController, animated: true)
            }
        }
        
        return true
    }
}

extension AppDelegate {
    
    func configureAWS() {
        // Initialize the Amazon Cognito credentials provider
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: .USWest2,
                                                                identityPoolId: AppConstants.AWS.S3IdentityPoolIdentifier)
        let configuration = AWSServiceConfiguration(region:.USWest2, credentialsProvider:credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
    }
    
    // MARK: Configure SwiftyBeaver Logging
    func configureLogs() {
        // add log destinations. at least one is needed!
        let console = ConsoleDestination()  // log to Xcode Console
        
        // use custom format and set console output to short time, log level & message
        console.format = "$DHH:mm:ss$d $N.$F():$l $L: $M"
        // or use this for JSON output: console.format = "$J"
        
        // add the destinations to SwiftyBeaver
        GGLog.addDestination(console)
    }
    
    func showAnimatedLaunchScreen() {
        let vc = AnimatedLaunchScreenViewController()
        window?.rootViewController = vc
        window?.makeKeyAndVisible()
        
        // Play startup sound
        SoundManager.shared.playSound(.appStartup)

        animatedLaunchTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] (_) in
            self?.showOnboardingIfNeeded()
        }
    }
    
    func showOnboardingIfNeeded() {
        
        // kill the animated launch screen timer if it hasn't been run yet
        animatedLaunchTimer?.invalidate()
        animatedLaunchTimer = nil
        
        if DataCoordinator.shared.isUserSignedIn() {
            
            NavigationManager.shared.showMainView()

            if DataCoordinator.shared.signedInUser?.ign.count == 0 {
                // User has not yet selected a gamer tag. Kick them to the select gamer tag screen.
                let viewController = UIStoryboard(name: AppConstants.Storyboards.onboarding, bundle: nil).instantiateViewController(withIdentifier: SelectGamerTagViewController.storyboardIdentifier)
                
                let nav = GGNavigationViewController(rootViewController: viewController)
                nav.hidesBottomBarWhenPushed = true
                nav.isNavigationBarHidden = true
                nav.modalTransitionStyle = .crossDissolve
                
                NavigationManager.shared.present(nav, animated: true)
            }
            
        } else {
            NavigationManager.shared.showOnboarding()
        }
    }
    
    private func showVoiceEjectAlertIfNeeded() {
        guard UserDefaults.standard.value(forKey: AppConstants.UserDefaults.showVoiceCallForceEjectAlert) as? Bool == true else { return }
        
        // Do NOT show the voice eject alert the next time the app is foregrounded
        UserDefaults.standard.set(false, forKey: AppConstants.UserDefaults.showVoiceCallForceEjectAlert)
        UserDefaults.standard.synchronize()
        
        let alert = UIAlertController(title: "yoooo! you left your mic on..",
                                      message: "so we turned it off after 5 minutes when you exited the app (and no one else was on)",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "whew, thanks!", style: .default, handler: { (_) in
            AnalyticsManager.track(event: .voiceEjectAlertButtonTapped)
        }))
        
        alert.show()
    }
}

extension AppDelegate: UAPushNotificationDelegate {
    
    func receivedBackgroundNotification(_ notificationContent: UANotificationContent, completionHandler: @escaping (UIBackgroundFetchResult) -> Swift.Void) {
        // Background content-available notification
        completionHandler(.noData)
    }
    
    func receivedForegroundNotification(_ notificationContent: UANotificationContent, completionHandler: @escaping () -> Swift.Void) {
        // Foreground notification
        parseNotificationContent(notificationContent: notificationContent)
    }
    
    func receivedNotificationResponse(_ notificationResponse: UANotificationResponse, completionHandler: @escaping () -> Void) {
        guard let signedInUser = DataCoordinator.shared.signedInUser else { return }
        
        // Make sure the main view is present (kill the animated launch screen)
        showOnboardingIfNeeded()
        
        // Notification response to user clicking on a notification
        let notificationInfo = notificationResponse.notificationContent.notificationInfo
        guard let notificationTypeRaw = notificationInfo["notificationType"] as? Int,
            let notificationType = AppConstants.PushNotificationType(rawValue: notificationTypeRaw) else {
                GGLog.error("Unknown push notifiation receieved: \(notificationInfo["notificationType"] ?? "")")
                completionHandler()
                return
        }
        
        switch notificationType {
        case .newChatMessage, .voiceChat:
            guard let chatroomId = notificationInfo["chatroomId"] as? String else { return }

            let firebaseChat = FirebaseChat()
            firebaseChat.signIn { (result, error) in
                firebaseChat.fetchChatroom(chatroomId, onFetch: { (chatroom) in
                    
                    guard let chatroom = chatroom else { return }
                       
                    if let session = chatroom.session {
                        DataCoordinator.shared.getGameSession(withSessionId: session.identifier) { (gameSession, error) in
                            performOnMainThread {
                                if let vc = NavigationManager.topMostViewController() as? ChatViewController, vc.chatroom?.identifier == chatroom.identifier {
                                    // Chat is already presented, stop here
                                    return
                                }
                                
                                let viewController = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: ChatViewController.storyboardIdentifier) as! ChatViewController
                                viewController.chatroom = chatroom
                                viewController.session = gameSession
                                NavigationManager.shared.push(viewController)
                            }
                        }
                    } else {
                        performOnMainThread {
                            if let vc = NavigationManager.topMostViewController() as? ChatViewController, vc.chatroom?.identifier == chatroom.identifier {
                                // Chat is already presented, stop here
                                return
                            }
                            
                            let viewController = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: ChatViewController.storyboardIdentifier) as! ChatViewController
                            viewController.chatroom = chatroom
                            NavigationManager.shared.push(viewController)
                        }
                    }
                })
            }

        case .friendRequest, .friendOnline:
            guard let userJSON = notificationInfo["from"] as? JSONDictionary,
                let fromUser = UserObject.parseJSON(json: userJSON) else { return }
            
            
            performOnMainThread {
                let firebaseChat = FirebaseChat()
                firebaseChat.signIn { (result, error) in
                    firebaseChat.getChatroom(withUserIds: [signedInUser.identifier, fromUser.identifier], completion: { (chatroom) in
                        
                        guard let chatroom = chatroom else { return }
                            
                        performOnMainThread {
                            if let vc = NavigationManager.topMostViewController() as? ChatViewController, vc.chatroom?.identifier == chatroom.identifier {
                                // Chat is already presented, stop here
                                return
                            }
                            
                            let viewController = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: ChatViewController.storyboardIdentifier) as! ChatViewController
                            viewController.chatroom = chatroom
                            NavigationManager.shared.push(viewController)
                        }
                    })
                }
            }

        case .partyCreated:
            break
        case .sessionStartingSoon, .sessionStartingNow:
            guard let sessionId = notificationInfo["sessionId"] as? String else { break }

            DataCoordinator.shared.getGameSession(withSessionId: sessionId) { [unowned self] (session, error) in
                guard error == nil, let session = session else {
                    GGLog.error(error?.localizedDescription ?? "unknown error")
                    return
                }
                
                performOnMainThread {
                    self.handleSessionNotificationAction(forSession: session, notificationType: notificationType)
                }
            }
        }
        
        completionHandler()
    }
    
    func presentationOptions(for notification: UNNotification) -> UNNotificationPresentationOptions {
        return [.alert, .sound, .badge]
    }
    
    private func parseNotificationContent(notificationContent: UANotificationContent) {
        guard let signedInUser = DataCoordinator.shared.signedInUser else { return }

        let notificationInfo = notificationContent.notificationInfo
        guard let notificationTypeRaw = notificationInfo["notificationType"] as? Int,
            let notificationType = AppConstants.PushNotificationType(rawValue: notificationTypeRaw) else {
                GGLog.error("Unknown push notifiation receieved: \(notificationInfo["notificationType"] ?? "")")
                return
        }
        
        switch notificationType {
        case .partyCreated:
            // NOP
            break
            
        case .sessionStartingSoon, .sessionStartingNow:
            guard let sessionId = notificationInfo["sessionId"] as? String else { break }
            
            handleIncomingSessionNotification(sessionId: sessionId,
                                              title: notificationInfo["title"] as? String,
                                              subtitle: notificationInfo["message"] as? String,
                                              notificationType: notificationType)

        case .newChatMessage, .voiceChat:
            guard let chatroomId = notificationInfo["chatroomId"] as? String else { break }
          
            let firebaseChat = FirebaseChat()
            firebaseChat.signIn { [weak self] (result, error) in
                guard let weakSelf = self else { return }
                
                firebaseChat.fetchChatroom(chatroomId, onFetch: { (chatroom) in
                    
                    guard let chatroom = chatroom else { return }
                    
                    if let vc = NavigationManager.topMostViewController() as? ChatViewController, vc.chatroom?.identifier == chatroom.identifier {
                        // Chat is already presented, stop here
                        return
                    }
                    
                    if let session = chatroom.session {
                        DataCoordinator.shared.getGameSession(withSessionId: session.identifier) { (gameSession, error) in
                            
                            performOnMainThread {
                                let nib = UINib(nibName: "\(ChatMessageNotificationBanner.self)", bundle: nil)
                                let view = nib.instantiate(withOwner: weakSelf.window, options: nil).first as! ChatMessageNotificationBanner
                                view.messageLabel.text = notificationInfo["message"] as? String
                                if let userJSON = notificationInfo["from"] as? JSONDictionary {
                                    view.user = UserObject.parseJSON(json: userJSON)
                                }
                                
                                let banner = NotificationBanner(customView: view)
                                
                                banner.onTap = {
                                    if let vc = NavigationManager.topMostViewController() as? ChatViewController, vc.chatroom?.identifier == chatroom.identifier {
                                        // Chat is already presented, stop here
                                        return
                                    }
                                    
                                    let viewController = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: ChatViewController.storyboardIdentifier) as! ChatViewController
                                    viewController.chatroom = chatroom
                                    viewController.session = gameSession
                                    NavigationManager.shared.push(viewController)
                                }
                                
                                banner.show()
                                
                                SoundManager.shared.playSound(.messageNotification)
                            }
                        }
                    } else {
                        performOnMainThread {
                            
                            let nib = UINib(nibName: "\(ChatMessageNotificationBanner.self)", bundle: nil)
                            let view = nib.instantiate(withOwner: weakSelf.window, options: nil).first as! ChatMessageNotificationBanner
                            view.messageLabel.text = notificationInfo["message"] as? String
                            if let userJSON = notificationInfo["from"] as? JSONDictionary {
                                view.user = UserObject.parseJSON(json: userJSON)
                            }
                            
                            let banner = NotificationBanner(customView: view)
                            
                            banner.onTap = {
                                if let vc = NavigationManager.topMostViewController() as? ChatViewController, vc.chatroom?.identifier == chatroom.identifier {
                                    // Chat is already presented, stop here
                                    return
                                }
                                
                                let viewController = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: ChatViewController.storyboardIdentifier) as! ChatViewController
                                viewController.chatroom = chatroom
                                NavigationManager.shared.push(viewController)
                            }
                            
                            banner.show()
                            
                            SoundManager.shared.playSound(.messageNotification)
                        }
                    }
                })
            }
        case .friendRequest:
            guard let userJSON = notificationInfo["from"] as? JSONDictionary,
                let fromUser = UserObject.parseJSON(json: userJSON) else { return }
            

            performOnMainThread {
                
                let nib = UINib(nibName: "\(ChatMessageNotificationBanner.self)", bundle: nil)
                let view = nib.instantiate(withOwner: self.window, options: nil).first as! ChatMessageNotificationBanner
                view.messageLabel.text = notificationInfo["message"] as? String ?? "sent you a friend request"
                view.user = fromUser

                let banner = NotificationBanner(customView: view)
                
                banner.onTap = {
                    let firebaseChat = FirebaseChat()
                    firebaseChat.signIn { (result, error) in
                        firebaseChat.getChatroom(withUserIds: [signedInUser.identifier, fromUser.identifier], completion: { (chatroom) in
                            
                            guard let chatroom = chatroom else { return }
                            
                            performOnMainThread {
                                if let vc = NavigationManager.topMostViewController() as? ChatViewController, vc.chatroom?.identifier == chatroom.identifier {
                                    // Chat is already presented, stop here
                                    return
                                }
                                
                                let viewController = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: ChatViewController.storyboardIdentifier) as! ChatViewController
                                viewController.chatroom = chatroom
                                NavigationManager.shared.push(viewController)
                            }
                        })
                    }
                }
                
                banner.show()
                
                SoundManager.shared.playSound(.friendRequest)
            }

        case .friendOnline:
            guard let userJSON = notificationInfo["from"] as? JSONDictionary,
                let fromUser = UserObject.parseJSON(json: userJSON) else { return }
        
            performOnMainThread {
                let nib = UINib(nibName: "\(FriendOnlineNotificationBanner.self)", bundle: nil)
                let view = nib.instantiate(withOwner: self.window, options: nil).first as! FriendOnlineNotificationBanner
                view.user = fromUser
                
                let banner = NotificationBanner(customView: view)
                
                banner.onTap = {
                    let firebaseChat = FirebaseChat()
                    firebaseChat.signIn { (result, error) in
                        firebaseChat.getChatroom(withUserIds: [signedInUser.identifier, fromUser.identifier], completion: { (chatroom) in
                            
                            guard let chatroom = chatroom else { return }
                            
                            performOnMainThread {
                                if let vc = NavigationManager.topMostViewController() as? ChatViewController, vc.chatroom?.identifier == chatroom.identifier {
                                    // Chat is already presented, stop here
                                    return
                                }
                                
                                let viewController = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: ChatViewController.storyboardIdentifier) as! ChatViewController
                                viewController.chatroom = chatroom
                                NavigationManager.shared.push(viewController)
                            }
                        })
                    }
                }
                
                banner.show()
                
                SoundManager.shared.playSound(.friendOnline)
            }
        }
    }
    
    private func handleIncomingSessionNotification(sessionId: String, title: String?, subtitle: String?, notificationType: AppConstants.PushNotificationType) {
        
        DataCoordinator.shared.getGameSession(withSessionId: sessionId) { [unowned self] (session, error) in
            guard error == nil, let session = session else {
                GGLog.error(error?.localizedDescription ?? "unknown error")
                return
            }
            
            performOnMainThread {
                
                let nib = UINib(nibName: "\(SessionNotificationBanner.self)", bundle: nil)
                let view = nib.instantiate(withOwner: self.window, options: nil).first as! SessionNotificationBanner
                view.titleLabel.text = title ?? "Team session starts in 5 min."
                view.subtitleLabel.text = subtitle ?? "Join your team now!"
                view.configure(withSession: session)

                let banner = NotificationBanner(customView: view)
                banner.bannerHeight = 110
                
                banner.onTap = {
                    self.handleSessionNotificationAction(forSession: session, notificationType: notificationType)
                }
                
                banner.show()
                
                SoundManager.shared.playSound(.friendRequest)
            }
        }
    }
    
    private func handleSessionNotificationAction(forSession session: GameSession, notificationType: AppConstants.PushNotificationType) {
        guard let type = session.sessionType?.type else { return }
        
        switch notificationType {
        case .sessionStartingSoon:
            AnalyticsManager.track(event: .sessionNotificationStartingSoonTapped, withParameters: ["sessionId": session.identifier])
        case .sessionStartingNow:
            AnalyticsManager.track(event: .sessionNotificationStartingNowTapped, withParameters: ["sessionId": session.identifier])
        default: break
        }
        
        switch type {
        case .gameMode:
            let viewController = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: GameLobbyContainerViewController.storyboardIdentifier) as! GameLobbyContainerViewController
            viewController.loadViewIfNeeded()
            viewController.shouldRestoreBookmarkedTags = false
            viewController.game = session.game
            viewController.tagsChatViewController?.selectedTags = session.tags
            NavigationManager.shared.push(viewController)

        case .request:
            guard let chatroomId = session.chatroomId else { break }
            
            // Fetch the chatroom for this game session
            let firebaseChat = FirebaseChat()
            firebaseChat.signIn { (result, error) in
                
                firebaseChat.fetchChatroom(chatroomId, onFetch: { (chatroom) in
                    guard let chatroom = chatroom else { return }
                        
                    performOnMainThread {
                        if let vc = NavigationManager.topMostViewController() as? ChatViewController, vc.chatroom?.identifier == chatroom.identifier {
                            // Chat is already presented, stop here
                            return
                        }
                        
                        let viewController = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: ChatViewController.storyboardIdentifier) as! ChatViewController
                        viewController.chatroom = chatroom
                        NavigationManager.shared.push(viewController)
                    }
                })
            }
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}

extension AppDelegate: AppsFlyerTrackerDelegate {
    
    func configureAppsFlyer() {
        AppsFlyerTracker.shared().appsFlyerDevKey = "nZ3qzsHQB3rNeeQK9ZNbd"
        AppsFlyerTracker.shared().appleAppID = "1434236090"
        
        AppsFlyerTracker.shared().delegate = self
        
        /* Set isDebug to true to see AppsFlyer debug logs */
        AppsFlyerTracker.shared().isDebug = false
    }
    
   //get conversion data and deep linking
    func onConversionDataSuccess(_ installData: [AnyHashable: Any]) {
   
    }

    func onConversionDataFail(_ error: Error?) {

    }

    func onAppOpenAttribution(_ attributionData: [AnyHashable: Any]) {

    }

    func onAppOpenAttributionFailure(_ error: Error?) {
        // NOP
    }
    
    // Reports app open from a Universal Link for iOS 9 or later
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
    AppsFlyerTracker.shared().continue(userActivity, restorationHandler: restorationHandler)
        return true
    }
}
