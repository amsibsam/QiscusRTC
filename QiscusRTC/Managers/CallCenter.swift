//
//  CallCenter.swift
//  Garuda
//
//  Created by Qiscus on 31/01/18.
//  Copyright © 2018 qiscus. All rights reserved.
//

import UIKit
import CallKit
import AVFoundation

protocol CallCenterDelegate {
    func callCenter(_ callCenter: CallCenter, startCall session: String)
    func callCenter(_ callCenter: CallCenter, answerCall session: String)
    func callCenter(_ callCenter: CallCenter, muteCall muted: Bool, session: String)
    func callCenter(_ callCenter: CallCenter, declineCall session: String)
    func callCenter(_ callCenter: CallCenter, endCall session: String)
    func callCenterDidActiveAudioSession(_ callCenter: CallCenter)
}

class CallCenter: NSObject {
    
    var delegate: CallCenterDelegate?
    
    fileprivate let controller = CXCallController()
    private var provider : CXProvider?
    fileprivate var sessionPool = [UUID: String]()
    
    init(delegate: CallCenterDelegate) {
        super.init()
        self.delegate = delegate
    }
    
    deinit {
        provider?.invalidate()
    }
    
    func setup(appName: String, appIcon: UIImage?) {
        var providerConfiguration = CXProviderConfiguration(localizedName: appName)
        providerConfiguration.supportsVideo = false
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.maximumCallGroups = 1
        providerConfiguration.supportedHandleTypes = [.generic]
        
        if let icon = appIcon {
            providerConfiguration.iconTemplateImageData = UIImagePNGRepresentation(icon)
        }
        self.provider = CXProvider(configuration: providerConfiguration)
        provider?.setDelegate(self, queue: nil)
    }
    
    func showIncomingCall(of session: String, isVideo: Bool) {
        let callUpdate = CXCallUpdate()
        callUpdate.remoteHandle = CXHandle(type: .generic, value: session)
        callUpdate.localizedCallerName = session
        callUpdate.hasVideo = isVideo
        callUpdate.supportsDTMF = false
        callUpdate.supportsHolding  = false
        callUpdate.supportsGrouping = false
        
        let uuid = pairedUUID(of: session)
        
        provider?.reportNewIncomingCall(with: uuid, update: callUpdate, completion: { error in
            if let error = error {
                print("reportNewIncomingCall error: \(error.localizedDescription)")
            }
        })
    }
    
    func startOutgoingCall(of session: String, isVideo: Bool) {
        let handle = CXHandle(type: .generic, value: session)
        let uuid = pairedUUID(of: session)
        let startCallAction = CXStartCallAction(call: uuid, handle: handle)
        startCallAction.isVideo = isVideo
        
        let transaction = CXTransaction(action: startCallAction)
        controller.request(transaction) { (error) in
            if let error = error {
                print("startOutgoingSession failed: \(error.localizedDescription)")
            }
        }
    }
    
    func setCallConnected(of session: String) {
        let uuid = pairedUUID(of: session)
        if let call = currentCall(of: uuid), call.isOutgoing, !call.hasConnected, !call.hasEnded {
            provider?.reportOutgoingCall(with: uuid, connectedAt: nil)
        }
    }
    
    func muteAudio(of session: String, muted: Bool) {
        let muteCallAction = CXSetMutedCallAction(call: pairedUUID(of: session), muted: muted)
        let transaction = CXTransaction(action: muteCallAction)
        controller.request(transaction) { (error) in
            if let error = error {
                print("muteSession \(muted) failed: \(error.localizedDescription)")
            }
        }
    }
    
    func endCall(of session: String) {
        let endCallAction = CXEndCallAction(call: pairedUUID(of: session))
        let transaction = CXTransaction(action: endCallAction)
        controller.request(transaction) { error in
            if let error = error {
                print("endSession failed: \(error.localizedDescription)")
            }
        }
    }
}

extension CallCenter: CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        sessionPool.removeAll()
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        guard let session = pairedSession(of:action.callUUID) else {
            action.fail()
            return
        }
        
        let callUpdate = CXCallUpdate()
        callUpdate.remoteHandle = action.handle
        callUpdate.hasVideo = true
        callUpdate.localizedCallerName = session
        callUpdate.supportsDTMF = false
        provider.reportCall(with: action.callUUID, updated: callUpdate)
        
        delegate?.callCenter(self, startCall: session)
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        guard let session = pairedSession(of:action.callUUID) else {
            action.fail()
            return
        }
        
        delegate?.callCenter(self, muteCall: action.isMuted, session: session)
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        guard let session = pairedSession(of:action.callUUID) else {
            action.fail()
            return
        }
        
        delegate?.callCenter(self, answerCall: session)
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        guard let session = pairedSession(of:action.callUUID) else {
            action.fail()
            return
        }
        
        if let call = currentCall(of: action.callUUID) {
            if call.isOutgoing || call.hasConnected {
                delegate?.callCenter(self, endCall: session)
            } else {
                delegate?.callCenter(self, declineCall: session)
            }
        }
        
        sessionPool.removeAll()
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        delegate?.callCenterDidActiveAudioSession(self)
    }
}

extension CallCenter {
    func pairedUUID(of session: String) -> UUID {
        for (u, s) in sessionPool {
            if s == session {
                return u
            }
        }
        
        let uuid = UUID()
        sessionPool[uuid] = session
        return uuid
    }
    
    func pairedSession(of uuid: UUID) -> String? {
        return sessionPool[uuid]
    }
    
    func currentCall(of uuid: UUID) -> CXCall? {
        let calls = controller.callObserver.calls
        if let index = calls.index(where: {$0.uuid == uuid}) {
            return calls[index]
        } else {
            return nil
        }
    }
}
