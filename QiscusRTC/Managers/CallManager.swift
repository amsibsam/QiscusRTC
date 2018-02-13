//
//  CallManager.swift
//  Garuda
//
//  Created by Qiscus on 10/27/17.
//  Copyright © 2017 qiscus. All rights reserved.
//

import Foundation
import SwiftyJSON

struct CallData {
    var targetName: String = ""
    var targetAvatar: String = ""
    var targetEmail: String = ""
    var targetEmailQiscus: String = ""
    var myEmailQiscus: String = ""
    var callRoomId: String = ""
    var isVideoCall: Bool = false
}

protocol CallDelegate {
    func callChange(state: CallState)
    func callConnect()
    func callDisconnect(error: NSError?)
}

class CallManager {
    private lazy var callCenter = CallCenter(delegate: self)
    var callsChangedHandler: (() -> Void)?
    var callSession : Call? // handle only single call
    var callEnggine : CallEnggine?
    var callSignal  : CallSignal?
    var config       : CallConfig?   = nil
    var startTime   : Date? = nil
    var client      : QiscusCallClient?  = nil
    var delegate    : CallDelegate? = nil
    
    var isAudioMute : Bool {
        get {
            return (self.callEnggine?.isAudioMute)!
        }
        set{
            self.callEnggine?.isAudioMute = newValue
        }
    }
    var isLoadSpeaker : Bool {
        get {
            return (self.callEnggine?.isLoadSpeaker)!
        }
        set{
            self.callEnggine?.isLoadSpeaker = newValue
        }
    }
    
    init() {
        self.callCenter.delegate    = self
        self.callSignal         = CallSignal(delegate: self)
        self.callEnggine        = CallEnggine(delegate: self)
    }
    
    func isRegister() -> Bool {
        return self.client != nil ? true : false
    }
    
    func whoami() -> CallUser? {
        return client
    }
    
    func clearClient() {
        client = nil
    }
    
    func setup(withConfig config: CallConfig) {
        self.config              = config
    }
    
    func call(withRoomId id: String, callType : CallType, targetUsername: String, targetDisplayName: String = "Person", targetDisplayAvatar: String = "http://", completionHandler: @escaping (UIViewController, NSError?) -> Void) {
        let target = self.getCall()
        completionHandler(target, nil)
        
        if callType == .incoming {
            self.start(room: id, isIncoming: true, targetUser: targetUsername)
            self.callSession = Call(uuid: self.callCenter.pairedUUID(of: targetDisplayName), outgoing: false, name: targetDisplayName, room: id, isAudio: true, callAvatar: URL(string: targetDisplayAvatar)!)
            // display incoming call UI when receiving incoming voip notification
            self.callCenter.showIncomingCall(of: targetDisplayName)
        }else {
            self.start(room: id, isIncoming: false, targetUser: targetUsername)
            self.callSession = Call(uuid: self.callCenter.pairedUUID(of: targetDisplayName), outgoing: true, name: targetDisplayName, room: id, isAudio: true, callAvatar: URL(string: targetDisplayAvatar)!)
            // display incoming call UI when receiving incoming voip notification
            self.callCenter.startOutgoingCall(of: targetDisplayName)
            self.callEnggine?.configureAudioSession()
            self.callEnggine?.start()
        }
    }
    
    func start(room: String, isIncoming: Bool, targetUser: String) {
        if let config = self.config {
            // WSS
            self.callSignal?.roomID = room
            self.callSignal?.targetUser = targetUser
            self.callSignal?.isIncoming = isIncoming
            self.callSignal?.setup(url: config.signalUrl , appID: config.appID, secret: config.secretKey, username: (client?.username)!)
            // RTC
            self.callEnggine?.setup()
        }
    }
    
    func initializeCall(userEmail: String, userType: String, callRoomId: String, isVideo: Bool, callEvent: String, completion: @escaping(RequestResult<Void>)->()) {
        ApiCall.initCall(userEmail: userEmail, userType: userType, callRoomId: callRoomId, isVideo: isVideo, callEvent: callEvent) { (response) in
            
        }
    }
    
    func isCallActive() -> Bool {
        if callSession != nil {
            return true
        }else {
            return false
        }
    }
    
    func getCall() -> UIViewController {
        let callScreen = CallUI()
        return callScreen
    }
    
    func didReceiveIncomingCall(userInfo: [AnyHashable: Any]) {
        // MARK : before handle payload from pushkit
        // change handle callkit
    }
    
    func finishCall() {
        if let data = self.callSession {
            self.finishTimer()
            self.callEnggine?.end()
            self.callSignal?.leave()
            self.callCenter.endCall(of: data.name)
            self.delegate?.callDisconnect(error: nil)
            self.callSession = nil
        }
    }
    
    func callDelegate(_ del: CallDelegate) {
        self.delegate = del
    }
    
    // Call Util
    internal func updateState(value: CallState) {
        self.callSession?.state = value
        self.delegate?.callChange(state: value)
    }
    
    func startTimer() {
        self.startTime = Date()
    }
    
    func finishTimer() {
        if self.startTime != nil {
            self.startTime = nil
        }
    }
    
    func getDuration() -> Int? {
        if self.startTime != nil {
            let calendar    = NSCalendar.current
            let seconds = calendar.component(.second, from: self.startTime!)
            return seconds
        }else {
            return nil
        }
    }
    
    func createRoomID(length:Int) -> String {
        
        let randomString:NSMutableString = NSMutableString(capacity: length)
        
        let letters:NSMutableString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        var i: Int = 0
        
        while i < length {
            
            let randomIndex:Int = Int(arc4random_uniform(UInt32(letters.length)))
            randomString.append("\(Character( UnicodeScalar( letters.character(at: randomIndex))!))")
            i += 1
        }
        
        return String(randomString)
    }
}

extension CallManager : CallCenterDelegate {
    func callCenter(_ callCenter: CallCenter, startCall session: String) {
//        enableMedia(false)
//        startSession(session)
    }
    
    func callCenter(_ callCenter: CallCenter, answerCall session: String) {
        self.callSignal?.accept()
        self.callEnggine?.configureAudioSession()
    }
    
    func callCenter(_ callCenter: CallCenter, declineCall session: String) {
        print("call declined")
        self.updateState(value: .ended)
        self.callSignal?.leave()
    }
    
    func callCenter(_ callCenter: CallCenter, muteCall muted: Bool, session: String) {
        self.callEnggine?.isAudioMute = muted
    }
    
    func callCenter(_ callCenter: CallCenter, endCall session: String) {
        self.finishCall()
    }
    
    func callCenterDidActiveAudioSession(_ callCenter: CallCenter) {
//        enableMedia(true)
        self.callEnggine?.configureAudioSession()
    }
}

extension CallManager : CallSignalDelegate {
    func signalReceiveCandidate(dataMid: String, dataIndex: Int, dataCandidate: String) {
        self.callEnggine?.setCandidate(dataMid: dataMid, dataIndex: dataIndex, dataCandidate: dataCandidate)
    }
    
    func signalConnect() {
        //
    }
    
    func signalDisconnect(error: Error?) {
        // End call
        self.finishCall()
    }
    
    func signalReceiveEvent(value: CallSignalEventRoom) {
        switch value {
        case .callAck:
            self.updateState(value: .ringing)
            break
        case .callAccept:
            // call enggine create offer
            self.callEnggine?.setOffer()
            break
        case .callReject:
            self.finishCall()
            break
        case .callCancel:
            self.updateState(value: .ended)
            break
        default:
            break
        }
    }
    
    func signalReceiveEventData(TypeOffer value: String, SDP: String) {
        // set peerconnection offer
        self.callEnggine?.setAnswer(dataType: value, sdp: SDP)
    }
    
    func signalReceiveEventData(TypeAnswer value: String, SDP: String) {
        // setSessionDescription
        self.callEnggine?.setRemoteDescription(sdp: SDP)
    }
}

extension CallManager : CallEnggineDelegate {
    func didReceiveLocalVideo(view: UIView) {
        //
    }
    
    func callEnggine(connectionChanged newState: CallConnectionState) {
        switch newState {
        case .new:
            self.updateState(value: .connecting)
            break
        case .connected:
            // Call Signal send Connected
            self.callSignal?.sendConnect()
            self.startTimer()
            self.delegate?.callConnect()
            self.updateState(value: .conected)
            break
        case .failed:
            self.updateState(value: .ended)
            break
        default:
            break
        }
    }
    
    func callEnggine(gotCandidate dataMid: String, dataIndex: Int, dataSdp: String) {
        // Call signal send candidate
        self.callSignal?.sendCandidat(dataMid: dataMid, dataIndex: dataIndex, dataSdp: dataSdp)
    }
    
    func callEnggine(createSession type: CallSDPType, description: String) {
        var value : String = ""
        if (type == .offer) {
            // Tell Call Signal to Send offer and notify local Offer
            self.callSignal?.sendOffer(sdp: description)
            value = "LOCAL_OFFER"
        }else if (type == .answer) {
            // Send Signal answer and notify local answer
            self.callSignal?.sendAnswer(sdp: description)
            value = "LOCAL_ANSWER"
        }
        self.callSignal?.sendNotify(state: type.rawValue, value: value)
    }
}
