# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'GameGether' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for GameGether
  pod 'SDWebImage'#, '4.4.7'
  pod 'SDWebImage/GIF'
  pod 'KeychainSwift'#, '16.0.1'
  pod 'SwiftyBeaver'#, '1.7.0'
  pod 'PKHUD'#, '5.3.0'
  pod 'GrowingTextView', '0.7.0'
  pod 'EasyTipView', '~> 2.0.4'
  pod 'BABFrameObservingInputAccessoryView', '~> 0.2.4'
  pod 'JTAppleCalendar', '~> 7.1'
  
  # MarqueeLabel is included in NotificationBannerSwift but leaving this here in case we ever remove
  #  it since other parts of the app still use Marquee Label.
  # pod 'MarqueeLabel', '~> 3.1.6'
  pod 'NotificationBannerSwift', '2.3.0'
  pod 'ALGReversedFlowLayout', '0.1.0'
  pod 'ViewAnimator', '2.5.1'
  pod 'DeepDiff', '2.2.0'

  # Crashlytics
  pod 'Fabric'#, '1.10.2'
  pod 'Crashlytics'#, '3.13.2'

  # AppsFlyer
  pod 'AppsFlyerFramework'

  # Agora Voice Chat
  pod 'AgoraRtcEngine_iOS'#, '2.8.0'

  # Firebase
  pod 'Firebase/Storage'#, '3.2.1'
  pod 'Firebase/Auth'#, '6.1.0'
  pod 'Firebase/Database'#, '6.0.0'
  pod 'Firebase/Core'#, #'6.1.0'
  pod 'Firebase/Messaging'#, '4.0.1'
  pod 'Firebase/Firestore'

  # Segment Analytics
  pod 'Analytics', '~> 3.0'
  pod 'Segment-Amplitude'
  
  # Giphy
  pod 'GiphyCoreSDK'#, '1.4.0'

  # Facebook Login
  pod 'FBSDKLoginKit'
  pod 'FacebookSDK'

  # Google login
  pod 'GoogleSignIn'

  # AWS
  pod 'AWSMobileClient'#, '2.6.35'  # For AWSMobileClient
  pod 'AWSS3'#, '2.6.35'            # For file transfers
  pod 'AWSCognito'#, '2.6.35'       # For data sync
  
  # Urban Airship
  pod 'UrbanAirship-iOS-SDK', '~> 12.0'

  target 'GameGetherTests' do
    inherit! :search_paths
    # Pods for testing
    pod 'WiremockClient', '~> 1.2.1'

  end

  target 'GameGetherUITests' do
    inherit! :search_paths
    # Pods for testing
    pod 'WiremockClient', '~> 1.2.1'

  end

end

target 'UANotificationService' do
  use_frameworks!
  pod 'UrbanAirship-iOS-AppExtensions'
end
