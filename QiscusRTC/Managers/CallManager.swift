//
//  CallManager.swift
//  Garuda
//
//  Created by Qiscus on 10/27/17.
//  Copyright © 2017 qiscus. All rights reserved.
//

import Foundation
import SwiftyJSON
import SwiftyTimer

struct CallData {
    var targetName: String = ""
    var targetAvatar: String = ""
    var targetEmail: String = ""
    var targetEmailQiscus: String = ""
    var myEmailQiscus: String = ""
    var callRoomId: String = ""
    var isVideoCall: Bool = false
}

class CallConfig {
    var signalUrl   : URL
    var appID       : String
    var secretKey   : String
    var username    : String
    
    init(signalUrl : URL, appID: String, secretKey: String, username: String) {
        self.signalUrl  = signalUrl
        self.appID      = appID
        self.secretKey  = secretKey
        self.username   = username
    }
}

class CallManager {
    static let shared = CallManager()
    private lazy var callCenter = CallCenter(delegate: self)
    var callsChangedHandler: (() -> Void)?
    var callSession : Call? // handle only single call
    var callEnggine : CallEnggine?
    var callSignal  : CallSignal?
    var config       : CallConfig?   = nil
    var startTime   : Date? = nil
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
    var callVc: CallingScreenVC? {
        didSet {
            callVc?.endCallAction = {
                self.finishCall()
            }
        }
    }
    
    
    private init() {
        self.callCenter.delegate    = self
        self.callSignal         = CallSignal(delegate: self)
        self.callEnggine        = CallEnggine(delegate: self)
    }
    
    func setup(withConfig config: CallConfig) {
        self.config              = config
    }
    
    func start() {
        if let config = self.config {
            // WSS
            self.callSignal?.setup(url: config.signalUrl , appID: config.appID, secret: config.secretKey, username: config.username)
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
    
    func outgoing(data: CallData) {
        let callingVc = CallingScreenVC()
        callingVc.callData      = data
        callingVc.isReceiving   = false
        
        let callingNav = UINavigationController(rootViewController: callingVc)
        
        UIApplication.currentViewController()?.navigationController?.present(callingNav, animated: true, completion: {
            self.initializeCall(userEmail: data.targetEmail, userType: "callee", callRoomId: data.callRoomId, isVideo: false, callEvent: "incoming") { (result) in

            }
        })
        
        // self.callKit.startCall(name: name, videoEnabled: false)
    }
    
    func incomingCall(name: String, userID: String, roomID: String, isAudio: Bool, callAvatar : URL) {
        self.callSignal?.roomID = roomID
        self.callSignal?.targetUser = userID
        self.callSession = Call(uuid: UUID(), outgoing: false, name: name, room: roomID, isAudio: isAudio, callAvatar: callAvatar)
        // display incoming call UI when receiving incoming voip notification
        self.callCenter.showIncomingCall(of: name)
        self.start()
    }
    
    func finishCall() {
        if let data = self.callSession {
            self.finishTimer()
            self.callEnggine?.end()
            self.callSignal?.leave()
            self.callCenter.endCall(of: data.name)
            self.callSession = nil
        }
    }
    
    // Call Util
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
}

extension CallManager : CallCenterDelegate {
    func callCenter(_ callCenter: CallCenter, startCall session: String) {
//        enableMedia(false)
//        startSession(session)
    }
    
    func callCenter(_ callCenter: CallCenter, answerCall session: String) {
        self.callSignal?.accept()
        self.callEnggine?.configureAudioSession()
        self.callEnggine?.start()
    }
    
    func callCenter(_ callCenter: CallCenter, declineCall session: String) {
        print("call declined")
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
        //
    }
    
    func signalReceiveEventData(TypeOffer value: String, SDP: String) {
        // set peerconnection answer
        self.callEnggine?.setAnswer(dataType: value, sdp: SDP)
    }
    
    func signalReceiveEventData(TypeAnswer value: String, SDP: String) {
        // setSessionDescription
        self.callEnggine?.setSessionDescription(dataType: value, sdp: SDP)
    }
}

extension CallManager : CallEnggineDelegate {
    func didReceiveLocalVideo(view: UIView) {
        //
    }
    
    func callEnggine(connectionChanged newState: CallConnectionState) {
        if newState == .connected {
            // Call Signal send Connected
            self.callSignal?.sendConnect()
            self.startTimer()
        }
    }
    
    func callEnggine(gotCandidate dataMid: String, dataIndex: Int, dataSdp: String) {
        // Call signal send candidate
        self.callSignal?.sendCandidat(dataMid: dataMid, dataIndex: dataIndex, dataSdp: dataSdp)
    }
    
    func callEnggine(createSession type: String, description: String) {
        if (type == "offer") {
            // Tell Call Signal to Send offer and notify local Offer
            self.callSignal?.sendOffer(sdp: description)
            self.callSignal?.sendNotify(state: type, value: "LOCAL_OFFER")
        }else if (type == "answer") {
            // Send Signal answer and notify local answer
            self.callSignal?.sendAnswer(sdp: description)
            self.callSignal?.sendNotify(state: type, value: "LOCAL_ANSWER")
        }
    }
}
