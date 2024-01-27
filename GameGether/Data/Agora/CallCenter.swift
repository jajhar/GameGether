//
//  CallCenter.swift
//  AgoraRTCWithCallKit
//
//  Created by GongYuhua on 2018/1/23.
//  Copyright © 2018年 Agora. All rights reserved.
//

import UIKit
import CallKit
import AVFoundation

protocol CallCenterDelegate: NSObjectProtocol {
    func callCenter(_ callCenter: CallCenter, startCall session: String)
    func callCenter(_ callCenter: CallCenter, answerCall session: String)
    func callCenter(_ callCenter: CallCenter, muteCall muted: Bool, session: String)
    func callCenter(_ callCenter: CallCenter, declineCall session: String)
    func callCenter(_ callCenter: CallCenter, endCall session: String)
    func callCenterDidActiveAudioSession(_ callCenter: CallCenter)
}

class CallCenter: NSObject {
    
    weak var delegate: CallCenterDelegate?
    
    fileprivate let controller = CXCallController()
    private let provider = CXProvider(configuration: CallCenter.providerConfiguration)
    
    private static var providerConfiguration: CXProviderConfiguration {
        let appName = "GameGether"
        let providerConfiguration = CXProviderConfiguration(localizedName: appName)
        providerConfiguration.supportsVideo = false
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.maximumCallGroups = 1
        providerConfiguration.supportedHandleTypes = [.generic]
        
//        if let iconMaskImage = UIImage(named: <#Icon file name#>) {
//            providerConfiguration.iconTemplateImageData = UIImagePNGRepresentation(iconMaskImage)
//        }
//        providerConfiguration.ringtoneSound = <#Ringtone file name#>
        
        return providerConfiguration
    }
    
    fileprivate var sessionPool = [UUID: String]()
    
    init(delegate: CallCenterDelegate) {
        super.init()
        self.delegate = delegate
        provider.setDelegate(self, queue: nil)
    }
    
    deinit {
        provider.invalidate()
    }
    
    func startOutgoingCall(of session: String) {
        
        let controller = CXCallController()
        let transaction = CXTransaction(action: CXStartCallAction(call: UUID(), handle: CXHandle(type: .generic, value: "GameGether")))
        controller.request(transaction) { (error) in
            if let error = error {
                print("startOutgoingSession failed: \(error.localizedDescription)")
            }
        }
    }
    
//    func setCallConnected(of session: String) {
//        let uuid = pairedUUID(of: session)
//        if let call = currentCall(of: uuid), call.isOutgoing, !call.hasConnected, !call.hasEnded {
//            provider.reportOutgoingCall(with: uuid, connectedAt: nil)
//        }
//    }
//
//    func muteAudio(of session: String, muted: Bool) {
//        let muteCallAction = CXSetMutedCallAction(call: pairedUUID(of: session), muted: muted)
//        let transaction = CXTransaction(action: muteCallAction)
//        controller.request(transaction) { (error) in
//            if let error = error {
//                print("muteSession \(muted) failed: \(error.localizedDescription)")
//            }
//        }
//    }
//
//    func endCall(of session: String) {
//        let endCallAction = CXEndCallAction(call: pairedUUID(of: session))
//        let transaction = CXTransaction(action: endCallAction)
//        controller.request(transaction) { error in
//            if let error = error {
//                print("endSession failed: \(error.localizedDescription)")
//            }
//        }
//    }
}

extension CallCenter: CXProviderDelegate {
    
    func providerDidReset(_ provider: CXProvider) {

    }
}
