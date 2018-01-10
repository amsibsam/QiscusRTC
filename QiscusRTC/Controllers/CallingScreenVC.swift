//
//  CallingScreenVC.swift
//  qisme
//
//  Created by Qiscus on 9/25/17.
//  Copyright © 2017 qiscus. All rights reserved.
//

import UIKit
import AlamofireImage
import AVFoundation
import Starscream
import AudioToolbox
import WebRTC

let VIDEO_TRACK_ID = "VIDEO0"
let AUDIO_TRACK_ID = "AUDIO0"
let LOCAL_MEDIA_STREAM_ID = "STREAM0"

let STUNServer  = ["stun:stun.l.google.com:19302", "stun:139.59.110.14:3478"]
let TURNServer  = ["turn:139.59.110.14:3478"]
let WSServer    = "wss://rtc.qiscus.com/signal"


struct CallData {
    var targetName: String = ""
    var targetAvatar: String = ""
    var targetEmail: String = ""
    var targetEmailQiscus: String = ""
    var myEmailQiscus: String = ""
    var callRoomId: String = ""
    var isVideoCall: Bool = false
}

class CallingScreenVC: UIViewController {
    //ui element
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var ivAvatar: UIImageView!
    @IBOutlet weak var btnAccept: UIButton!
    @IBOutlet weak var btnEnd: UIButton!
    @IBOutlet weak var btnSpeaker: UIButton!
    @IBOutlet weak var btnMic: UIButton!
    @IBOutlet weak var viewRipple: UIView!
    @IBOutlet weak var lbTimer: UILabel!
    @IBOutlet weak var viewRemoteVideo: UIView!
    @IBOutlet weak var viewHeader: UIView!
    @IBOutlet weak var lbNameVideo: UILabel!
    @IBOutlet weak var lbTimerVideo: UILabel!
    @IBOutlet weak var viewLocalVideo: UIView!
    @IBOutlet weak var btnSwitchCamera: UIButton!
    @IBOutlet weak var btnVideo: UIButton!
    @IBOutlet weak var viewBtnPannelContainer: UIView!
    @IBOutlet weak var viewVideoMask: UIView!
    @IBOutlet weak var viewVideoDisabled: UIView!
    
    //constrain
    @IBOutlet weak var btnEndCenterPoint: NSLayoutConstraint!
    @IBOutlet weak var btnAcceptCenterPoint: NSLayoutConstraint!
    
    //programmatically ui element
    var backgroundGradient: UIImageView!
    
    //presenter
    var presenter: CallingPresenterInteraction!
    
    //data variable
    var callData: CallData!
    var isReceiving: Bool = false
    var player: AVAudioPlayer?
    var wsReconnectCount: Int = 0
    var timeStart: Int = 0
    
    //button and state variable
    var isSpeakerOn: Bool = false
    var isFrontCamera: Bool = true
    var isCameraOn: Bool = true
    var isMicOn: Bool = true
    var timeoutTimer: Timer?
    var isPendingSendAccept: Bool = false
    var isLoggedin: Bool = false
    
    var isCallAccepted: Bool = false
    var isPanelHidden: Bool = false
    
    var capturer : RTCVideoCapturer?
    
    //signaling
    var socket:WebSocket!
    
    // webrtc
    var peerConnectionFactory: RTCPeerConnectionFactory! = nil
    var peerConnection: RTCPeerConnection! = nil
    var mediaStream: RTCMediaStream!
    var localVideo : RTCEAGLVideoView!
    var remoteVideo : RTCEAGLVideoView!
    var localVideoTrack: RTCVideoTrack!
    var localAudioTrack: RTCAudioTrack!
    var remoteVideoTrack: RTCVideoTrack!
    var remoteAudioTrack: RTCAudioTrack!
    var localRenderer: RTCEAGLVideoView!
    var remoteRenderer: RTCEAGLVideoView!
    var mediaConstraints = RTCMediaConstraints(mandatoryConstraints: [
        "OfferToReceiveAudio" : "true", "OfferToReceiveVideo" : "true"
        ], optionalConstraints: nil)
    
    public init() {
        super.init(nibName: "CallingScreenVC", bundle: QiscusRTC.bundle)
    }
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //setup presenter
        presenter = CallingPresenter(delegate: self)
        
        //setup ui
        self.setupUI()
        
        //setup auto disconnect after 45 seconds and not accepted
        self.disconnectOnTimeout(timeoutInSeconds: 45)
        
        //setup websocket connection for signaling TODO: need to move to presenter or another mechanism to separate from view
        setupWebsocket()
        
        //capture device
        captureDevice()
        
        //setup for peer connection
        preparePeerConnection()
        
        //start call
        presenter.startCalling()
        
        //set active state
        //        presenter.setActive(isActive: true)
        self.capturer = RTCVideoCapturer(delegate: self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = true
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = false
        self.socket.disconnect()
        self.peerConnection.close()
        UIApplication.shared.isIdleTimerDisabled = false
        self.presenter.setActive(isActive: false)
        if self.player != nil {
            self.player?.stop()
        }
        
    }
    
    //btn action
    @IBAction func onEndDidTap(_ sender: Any) {
        let jsonDic = [
            "request": "room_leave",
            "room": self.callData.callRoomId
            ] as [String : Any]
        
        do {
            let jsonObj = try JSONSerialization.data(withJSONObject: jsonDic, options: .prettyPrinted)
            let jsonStr = String(data: jsonObj, encoding: String.Encoding.utf8)
            self.socket.write(string: jsonStr!)
            self.peerConnection.close()
            self.socket.disconnect()
            presenter.endCall()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    @IBAction func onAcceptDidTap(_ sender: Any) {
        //btnAccept after accept call
        self.acceptAnimation()
        self.isCallAccepted = true
        self.lbTimer.text = "Connecting..."
        //self.peerConnection.createOffer(with: self, constraints: self.mediaConstraints)
        
        if self.isLoggedin {
            do {
                let jsonDic = [
                    "request": "room_data",
                    "room": self.callData.callRoomId,
                    "recipient": self.callData.targetEmailQiscus,
                    "data": "{\"event\": \"call_accept\"}"
                    ] as [String : Any]
                let jsonObj = try JSONSerialization.data(withJSONObject: jsonDic, options: .prettyPrinted)
                let jsonStr = String(data: jsonObj, encoding: String.Encoding.utf8)
                self.socket.write(string: jsonStr!)
            } catch {
                print(error.localizedDescription)
            }
            presenter.acceptCall(userEmail: self.callData.targetEmailQiscus, callRoomId: self.callData.callRoomId)
            self.isPendingSendAccept = false
        } else {
            self.isPendingSendAccept = true
            print("[Hub] Client has not logged in yet. Waiting")
            
        }
        
    }
    
    @IBAction func onSwapCameraDidTap(_ sender: UIButton) {
        let localStream = self.peerConnection.localStreams[0] as! RTCMediaStream;
        let _localVideoTrack = localStream.videoTracks[0] as! RTCVideoTrack;
        let _newVideoTrack = self.swapCaptureDevice(front: !isFrontCamera)
        localStream.removeVideoTrack(_localVideoTrack)
        
        if isFrontCamera {
            self.btnSwitchCamera.setImage(UIImage(named: "ic_switch_camera_back"), for: .normal)
        } else {
            self.btnSwitchCamera.setImage(UIImage(named: "ic_switch_camera_front"), for: .normal)
        }
        
        if _newVideoTrack != nil {
            localStream.addVideoTrack(_newVideoTrack)
            _newVideoTrack.add(self.localVideo)
            self.viewLocalVideo.addSubview(self.localVideo)
        }
        
        self.peerConnection.remove(localStream)
        self.peerConnection.add(localStream)
        
        //reverse button state status
        self.isFrontCamera = !isFrontCamera
    }
    
    
    @IBAction func onCameraDidTap(_ sender: UIButton) {
        let localStream = self.peerConnection.localStreams[0] as! RTCMediaStream
        //set button image state
        if isCameraOn {
            self.btnVideo.setImage(UIImage(named: "ic_video_off"), for: .normal)
            let _localVideoTrack = localStream.videoTracks[0] as! RTCVideoTrack
            localStream.removeVideoTrack(_localVideoTrack)
            self.viewVideoDisabled.isHidden = false
        } else {
            self.btnVideo.setImage(UIImage(named: "ic_video_on"), for: .normal)
            localStream.addVideoTrack(self.localVideoTrack)
            self.viewVideoDisabled.isHidden = true
        }
        
        self.peerConnection.remove(localStream)
        self.peerConnection.add(localStream)
        
        //reverse button state status
        self.isCameraOn = !isCameraOn
    }
    
    @IBAction func onSpeakerDidTap(_ sender: Any) {
        //set button image state
        if isSpeakerOn {
            self.btnSpeaker.setImage(UIImage(named: "bt_speaker_off"), for: .normal)
            do {
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
            } catch {
                print(error.localizedDescription)
            }
        } else {
            self.btnSpeaker.setImage(UIImage(named: "bt_speaker_on"), for: .normal)
            do {
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
            } catch {
                print(error.localizedDescription)
            }
            
        }
        
        //reverse button state status
        self.isSpeakerOn = !isSpeakerOn
    }
    
    @IBAction func onMicDidTap(_ sender: Any) {
        //set button image state
        if isMicOn {
            self.btnMic.setImage(UIImage(named: "bt_microphone_off"), for: .normal)
            let localStream = self.peerConnection.localStreams[0] as! RTCMediaStream;
            let _localAudioTrack = localStream.audioTracks[0] as! RTCAudioTrack;
            localStream.removeAudioTrack(_localAudioTrack)
            self.peerConnection.remove(localStream)
            self.peerConnection.add(localStream)
        } else {
            self.btnMic.setImage(UIImage(named: "bt_microphone_on"), for: .normal)
            let localStream = self.peerConnection.localStreams[0] as! RTCMediaStream;
            localStream.addAudioTrack(self.localAudioTrack)
            self.peerConnection.remove(localStream)
            self.peerConnection.add(localStream)
        }
        
        //reverse button state status
        self.isMicOn = !isMicOn
    }
    
    @objc func hidePanel() {
        if self.isPanelHidden {
            self.isPanelHidden = !self.isPanelHidden
            self.viewHeader.isHidden = true
            self.viewBtnPannelContainer.isHidden = true
            self.viewLocalVideo.isHidden = true
        } else {
            self.isPanelHidden = !self.isPanelHidden
            self.viewHeader.isHidden = false
            self.viewBtnPannelContainer.isHidden = false
            self.viewLocalVideo.isHidden = false
        }
    }
}

//presenter delegate
extension CallingScreenVC: CallingPresenterDelegate {
    func onEndCall() {
        self.disconnect()
        self.player?.stop()
    }
    
    func onAcceptCall() {
        
    }
    
    func onTimerTic(duration: String) {
        self.lbTimer.text = duration
        self.lbTimerVideo.text = duration
    }
}

//peer connection delegate
extension CallingScreenVC : RTCPeerConnectionDelegate {
   
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        //
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        //
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        //
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        //
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        if (candidate != nil) {
            sendCandidate(candidate: candidate)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        if (peerConnection == nil) {
            return
        }
        if (stream.audioTracks.count > 1 || stream.videoTracks.count > 1) {
            print("[RTC-HUB] Weird-looking stream: " + stream.description)
            return
        }
        if (stream.videoTracks.count == 1) {
            remoteVideoTrack = stream.videoTracks[0] as! RTCVideoTrack
            remoteVideoTrack.isEnabled  = true;
            remoteVideoTrack.add(self.remoteVideo);
            DispatchQueue.main.async {

                self.viewRemoteVideo.insertSubview(self.remoteVideo, at: 0)
                self.localVideo.frame = CGRect(x: 0, y: 0, width: 100, height: 150)
                self.viewLocalVideo.insertSubview(self.localVideo, at: 0)
                self.viewVideoMask.isHidden = true

                if self.callData.isVideoCall {
                    self.ivAvatar.isHidden = true
                    self.viewLocalVideo.isHidden = false
                }
            }
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        remoteVideoTrack = nil
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        //
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        //
    }
    
}


//session description delegate
//extension CallingScreenVC:  {
//    func peerConnection(_ peerConnection: RTCPeerConnection!, didCreateSessionDescription sdp: RTCSessionDescription!, error: Error!) {
//        if (error == nil) {
//            self.player?.stop()
//            peerConnection.setLocalDescriptionWith(self, sessionDescription: sdp)
//            print("[RTC-HUB] Got local offer/answer")
//            
//            if (sdp.type == "offer") {
//                self.sendOffer(sdp: sdp)
//            } else {
//                self.sendAnswer(sdp: sdp)
//            }
//        } else {
//            print("[RTC-HUB] SDP creation error: " + error.localizedDescription)
//        }
//    }
//    
//    func peerConnection(_ peerConnection: RTCPeerConnection!, didSetSessionDescriptionWithError error: Error!) {
//    }
//}

//function collection
extension CallingScreenVC {
    fileprivate func setupUI() {
        playSound()
        callTypeUI()
        bindContactToView()
        setupBackground()
        setupRippleEffect()
        setupProximity(isOn: !callData.isVideoCall)
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    fileprivate func acceptAnimation() {
        UIView.animate(withDuration: 0.3) {
            self.btnEndCenterPoint.constant -= 60
            self.btnAcceptCenterPoint.constant += 60
            self.view.layoutIfNeeded()
        }
    }
    
    /// determine voice call or video call ui
    fileprivate func callTypeUI() {
        if self.callData.isVideoCall {
            // video call
            self.lbName.isHidden = true
            self.lbTimer.isHidden = true
            self.viewRipple.isHidden = true
            
            //set container action
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(CallingScreenVC.hidePanel))
            self.viewRemoteVideo.isUserInteractionEnabled = true
            self.viewRemoteVideo.addGestureRecognizer(tapGesture)
            self.btnSpeaker.setImage(UIImage(named: "bt_speaker_on"), for: .normal)
        } else {
            // voice call
            self.btnSwitchCamera.isHidden = true
            self.btnVideo.isHidden = true
            self.viewHeader.isHidden = true
            self.viewLocalVideo.isHidden = true
            self.viewRemoteVideo.isHidden = true
            self.btnSpeaker.setImage(UIImage(named: "bt_speaker_off"), for: .normal)
        }
    }
    
    fileprivate func setSpeaker(isOn: Bool) {
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(isOn ? .speaker : .none)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    fileprivate func bindContactToView() {
        //contact data variabel
        let avatar = self.callData.targetAvatar
        let fullname = self.callData.targetName
        
        //bind to view
        self.lbName.text = fullname
        self.lbNameVideo.text = fullname
        //configure avatar to imageView using alamofireImage
        let placeHolderImage: UIImage   = UIImage(named: "avatar", in: QiscusRTC.bundle, compatibleWith: nil)!

        
        //setup af_image filter
        let cellImageLayer: CALayer?    = ivAvatar.layer
        let imageRadius: CGFloat        = CGFloat(cellImageLayer!.frame.size.height / 2)
        let imageSize: CGSize           = CGSize(width: 43, height: 43)
        let imageFilter                 = AspectScaledToFillSizeWithRoundedCornersFilter(size: imageSize, radius: imageRadius)
        cellImageLayer!.cornerRadius    = imageRadius
        cellImageLayer!.masksToBounds   = true
        
        if !avatar.isEmpty {
            self.ivAvatar.af_setImage(withURL: URL(string: avatar)!, placeholderImage: placeHolderImage, filter: imageFilter)
        } else {
            self.ivAvatar.image = placeHolderImage
        }
        
        //btn call state depends on calling type
        btnAccept.isHidden = !isReceiving
        
        if !isReceiving {
            btnEndCenterPoint.constant -= 60
        }
    }
    
    fileprivate func setupProximity(isOn: Bool) {
        UIDevice.current.isProximityMonitoringEnabled = isOn
    }
    
    fileprivate func setupWebsocket() {
        self.socket = WebSocket(url: URL(string: "wss://rtc.qiscus.com/signal")!)
        self.socket.onConnect = {
            print("[Hub] Websocket is connected")
            let jsonDic = [
                "request": "register",
                "data": "{\"username\": \"\(self.callData.myEmailQiscus)\"}"
                ] as [String : Any]
            
            do {
                let jsonObj = try JSONSerialization.data(withJSONObject: jsonDic, options: .prettyPrinted)
                let jsonStr = String(data: jsonObj, encoding: String.Encoding.utf8)
                self.socket.write(string: jsonStr!)
            } catch {
                print(error.localizedDescription)
            }
        }
        self.socket.onDisconnect = { (error: Error?) in
            print("[Hub] Websocket is disconnected: \(error?.localizedDescription)")
            
            self.disconnect()
        }
        self.socket.onText = { (text: String) in
            print("[Hub] Got some text: \(text)")
            
            do {
                let json = self.convertToDictionary(text: text)
                if let dict = json as NSDictionary? {
                    if let response = dict.value(forKey: "response") as? String {
                        let data = dict.value(forKey: "data") as? String
                        let dataObj = self.convertToDictionary(text: data!) as NSDictionary?
                        
                        if response == "register" {
                            if (dataObj?.value(forKey: "success") as? Bool)! {
                                if (!self.isReceiving) {
                                    let jsonDic = [
                                        "request": "room_create",
                                        "room": self.callData.callRoomId,
                                        "data": "{\"max_participant\": 2}"
                                        ] as [String : Any]
                                    let jsonObj = try JSONSerialization.data(withJSONObject: jsonDic, options: .prettyPrinted)
                                    let jsonStr = String(data: jsonObj, encoding: String.Encoding.utf8)
                                    self.socket.write(string: jsonStr!)
                                } else {
                                    let jsonDic = [
                                        "request": "room_join",
                                        "room": self.callData.callRoomId
                                        ] as [String : Any]
                                    let jsonObj = try JSONSerialization.data(withJSONObject: jsonDic, options: .prettyPrinted)
                                    let jsonStr = String(data: jsonObj, encoding: String.Encoding.utf8)
                                    self.socket.write(string: jsonStr!)
                                }
                            } else {
                                let errMsg = dataObj?.value(forKey: "message") as? String
                                print("[Hub] Error: \(errMsg)")
                            }
                        } else if response == "room_create" || response == "room_join" {
                            if (dataObj?.value(forKey: "success") as? Bool)! {
                                self.isLoggedin = true
                                
                                if response == "room_join" {
                                    if self.isPendingSendAccept {
                                        do {
                                            let jsonDic = [
                                                "request": "room_data",
                                                "room": self.callData.callRoomId,
                                                "recipient": self.callData.targetEmailQiscus,
                                                "data": "{\"event\": \"call_accept\"}"
                                                ] as [String : Any]
                                            let jsonObj = try JSONSerialization.data(withJSONObject: jsonDic, options: .prettyPrinted)
                                            let jsonStr = String(data: jsonObj, encoding: String.Encoding.utf8)
                                            self.socket.write(string: jsonStr!)
                                        } catch {
                                            print(error.localizedDescription)
                                        }
                                        self.presenter.acceptCall(userEmail: self.callData.targetEmailQiscus, callRoomId: self.callData.callRoomId)
                                        self.isPendingSendAccept = false
                                    }
                                }
                            } else {
                                let errMsg = dataObj?.value(forKey: "message") as? String
                                print("[Hub] Error: \(errMsg)")
                            }
                            
                        }
                    } else if let event = dict.value(forKey: "event") as? String {
                        let sender = dict.value(forKey: "sender") as? String
                        let data = dict.value(forKey: "data") as? String
                        let dataObj = self.convertToDictionary(text: data!) as NSDictionary?
                        
                        if event == "user_new" {
                            if sender == self.callData.targetEmailQiscus {
                                let jsonDic = [
                                    "request": "room_data",
                                    "room": self.callData.callRoomId,
                                    "recipient": self.callData.targetEmailQiscus,
                                    "data": "{\"event\": \"call_sync\"}"
                                    ] as [String : Any]
                                let jsonObj = try JSONSerialization.data(withJSONObject: jsonDic, options: .prettyPrinted)
                                let jsonStr = String(data: jsonObj, encoding: String.Encoding.utf8)
                                self.socket.write(string: jsonStr!)
                            }
                        } else if event == "user_leave" {
                            if sender == self.callData.targetEmailQiscus {
                                self.disconnect()
                            }
                        } else if event == "room_data_private" {
                            if let dataEvt = dataObj?.value(forKey: "event") as? String {
                                if dataEvt == "call_sync" {
                                    let jsonDic = [
                                        "request": "room_data",
                                        "room": self.callData.callRoomId,
                                        "recipient": self.callData.targetEmailQiscus,
                                        "data": "{\"event\": \"call_ack\"}"
                                        ] as [String : Any]
                                    let jsonObj = try JSONSerialization.data(withJSONObject: jsonDic, options: .prettyPrinted)
                                    let jsonStr = String(data: jsonObj, encoding: String.Encoding.utf8)
                                    self.socket.write(string: jsonStr!)
                                } else if dataEvt == "call_ack" {
                                    // Set state to ringing
                                    self.lbTimer.text = "Ringing..."
                                    self.playSound()
                                } else if dataEvt == "call_accept" {
                                    // Set state to connecting
                                    self.lbTimer.text = "Connecting..."
                                    self.isCallAccepted = true
                                    self.peerConnection.offer(for: self.mediaConstraints, completionHandler: { (sessionDescription, error) in
                                        //
                                    })
                                    
                                } else if dataEvt == "call_reject" {
                                    self.disconnect()
                                    // Rejected
                                } else if dataEvt == "call_cancel" {
                                    // Canceled
                                    self.disconnect()
                                }
                            } else if let dataType = dataObj?.value(forKey: "type") as? String {
                                let dataSDP = dataObj?.value(forKey: "sdp") as? String
                                let dataMid = dataObj?.value(forKey: "sdpMid") as? String
                                let dataIndex = dataObj?.value(forKey: "sdpMLineIndex") as? Int32
                                let dataCandidate = dataObj?.value(forKey: "candidate") as? String
                                
                                if dataType == "offer" {
                                    let sdpSet = RTCSessionDescription(type: RTCSdpType.offer, sdp: dataSDP!)
                                    self.peerConnection.setRemoteDescription(sdpSet, completionHandler: { (error) in
                                        //
                                    })
            
                                    self.peerConnection.answer(for: self.mediaConstraints, completionHandler: { (sessionDescriptoin, error) in
                                        //
                                    })
                                    DispatchQueue.main.async {
                                        self.presenter.startTimer()
                                        self.viewRipple.isHidden = true
                                        do {
                                            try AVAudioSession.sharedInstance().overrideOutputAudioPort(self.callData.isVideoCall ? .speaker : .none)
                                        } catch {
                                            print(error.localizedDescription)
                                        }
                                        
                                    }
                                    print("[Hub] Got remote offer")
                                } else if dataType == "answer" {
                                    let sdpSet = RTCSessionDescription(type: RTCSdpType.answer, sdp: dataSDP!)
                                    self.peerConnection.setRemoteDescription(sdpSet, completionHandler: { (error) in
                                        //
                                    })
                                    
                                    print("[Hub] Got remote answer")
                                    DispatchQueue.main.async {
                                        self.presenter.startTimer()
                                        self.viewRipple.isHidden = true
                                        do {
                                            try AVAudioSession.sharedInstance().overrideOutputAudioPort(self.callData.isVideoCall ? .speaker : .none)
                                        } catch {
                                            print(error.localizedDescription)
                                        }
                                        
                                    }
                                } else if dataType == "candidate" {
                                    let iceSet = RTCIceCandidate(sdp: dataCandidate!, sdpMLineIndex: dataIndex!, sdpMid: dataMid)
//                                    (sdp: dataCandidate!, sdpMLineIndex: dataMid, sdpMid: dataIndex!)
                                    self.peerConnection.add(iceSet)
                                    print("[Hub] Got remote candidate")
                                }
                            } else {
                                print("[Hub] Mbuh")
                            }
                        } else {
                            print("[Hub] Unknown event")
                        }
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        self.socket.onData = { (data: Data) in
            print("[Hub] Got some data: \(data.count)")
        }
        
        self.socket.connect()
    }
    
    fileprivate func sendOffer(sdp: RTCSessionDescription) {
        do {
            let jsonDic = [
                "request": "room_data",
                "room": self.callData.callRoomId,
                "recipient": self.callData.targetEmailQiscus,
                "data": "{\"type\": \"offer\", \"sdp\": \"\(self.escapeString(string: sdp.description as String))\"}"
                ] as [String : Any]
            let jsonObj = try JSONSerialization.data(withJSONObject: jsonDic, options: .prettyPrinted)
            let jsonStr = String(data: jsonObj, encoding: String.Encoding.utf8)
            self.socket.write(string: jsonStr!)
            print("[RTC-HUB] \(jsonStr)")
        } catch {
            print(error.localizedDescription)
        }
    }
    
    fileprivate func sendAnswer(sdp: RTCSessionDescription) {
        do {
            let jsonDic = [
                "request": "room_data",
                "room": self.callData.callRoomId,
                "recipient": self.callData.targetEmailQiscus,
                "data": "{\"type\": \"answer\", \"sdp\": \"\(self.escapeString(string: sdp.description as String))\"}"
                ] as [String : Any]
            let jsonObj = try JSONSerialization.data(withJSONObject: jsonDic, options: .prettyPrinted)
            let jsonStr = String(data: jsonObj, encoding: String.Encoding.utf8)
            self.socket.write(string: jsonStr!)
            print("[RTC-HUB] \(jsonStr)")
        } catch {
            print(error.localizedDescription)
        }
    }
    
    fileprivate func sendCandidate(candidate: RTCIceCandidate) {
        do {
            let jsonDic = [
                "request": "room_data",
                "room": self.callData.callRoomId,
                "recipient": self.callData.targetEmailQiscus,
                "data": "{\"type\": \"candidate\", \"sdpMLineIndex\": \(candidate.sdpMLineIndex), \"sdpMid\": \"\(candidate.sdpMid as! String)\", \"candidate\": \"\(candidate.sdp as String)\"}"
                ] as [String : Any]
            let jsonObj = try JSONSerialization.data(withJSONObject: jsonDic, options: .prettyPrinted)
            let jsonStr = String(data: jsonObj, encoding: String.Encoding.utf8)
            self.socket.write(string: jsonStr!)
            print("[RTC-HUB] \(jsonStr)")
        } catch {
            print(error.localizedDescription)
        }
    }
    
    fileprivate func setupRippleEffect() {
//        let rippleLayer = RippleLayer()
//        print("ripple x: \(viewRipple.frame.origin.x) y: \(viewRipple.frame.origin.y)")
//        rippleLayer.position = CGPoint(x: CGFloat.screenWidth/2, y: self.viewRipple.frame.origin.y - 60)
//
//        self.viewRipple.layer.insertSublayer(rippleLayer, at: 1)
//        rippleLayer.startAnimation()
    }
    
    fileprivate func setupGradient() -> CAGradientLayer {
        let gradient: CAGradientLayer   = CAGradientLayer()
//        gradient.colors     = [UIColor.black, UIColor.white]
//        gradient.locations  = [0.0 , 1.0]
//        gradient.startPoint = CGPoint(x: 0.0, y: 0.0)
//        gradient.endPoint   = CGPoint(x: 0.0, y: 0.85)
//        gradient.frame      = CGRect(x: 0, y: 0, width: CGFloat.screenWidth, height: CGFloat.screenHeight)
        
        return gradient
    }
    
    fileprivate func setupBackground() {
        // Set background with callee avatar
//        let gradientView = UIView(frame: CGRect(x: 0, y: 0, width: CGFloat.screenWidth, height: CGFloat.screenHeight))
        /*self.backgroundGradient.contentMode   = .scaleToFill
         self.backgroundGradient.layer.insertSublayer(setupGradient(), at: 0)
         self.view.addSubview(backgroundGradient)*/
//        let gradient:CAGradientLayer = CAGradientLayer()
//        gradient.frame = CGRect(x: 0, y: 0, width: CGFloat.screenWidth, height: CGFloat.screenHeight)
//        gradient.startPoint = CGPoint(x: 0.0, y: 0.0)
//        gradient.endPoint   = CGPoint(x: 0.0, y: 1)
//        gradient.locations  = [0.0 , 1.0]
//        gradient.colors = [UIColor.baseNavigateColor.cgColor, UIColor.black.cgColor]
//        gradientView.layer.insertSublayer(gradient, at: 0)
//        self.view.insertSubview(gradientView, at: 0)
//        self.view.backgroundColor = UIColor.baseNavigateColor
        
    }
    
    fileprivate func playSound() {
//        var url = Bundle.main.url(forResource: self.isReceiving ? "phone_ring" : "phone_waiting", withExtension: "mp3")
//        
//        if self.player != nil {
//            player?.stop()
//            url = Bundle.main.url(forResource: "phone_ring", withExtension: "mp3")
//        }
//        
//        do {
//            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
//            try AVAudioSession.sharedInstance().setActive(true)
//            
//            self.player = try AVAudioPlayer(contentsOf: url!)
//            self.player?.numberOfLoops = -1
//            guard let player = player else { return }
//            player.play()
//        } catch let error {
//            print(error.localizedDescription)
//        }
    }
    
    fileprivate func captureDevice() {
        var device: AVCaptureDevice! = nil
        
        for captureDevice in AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) {
            if ((captureDevice as AnyObject).position == AVCaptureDevicePosition.front) {
                device = captureDevice as! AVCaptureDevice
            }
        }
        
        self.peerConnectionFactory = RTCPeerConnectionFactory()
        
        if (device != nil) {
            let videoConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
            self.peerConnectionFactory.avFoundationVideoSource(with: videoConstraints)
            let videoSource  = peerConnectionFactory.videoSource()
            
            self.localVideo = RTCEAGLVideoView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height))
            self.remoteVideo = RTCEAGLVideoView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height))
            self.localVideoTrack = peerConnectionFactory.videoTrack(with: videoSource, trackId: VIDEO_TRACK_ID)
            self.localVideoTrack.add(self.localVideo)
            self.localAudioTrack = peerConnectionFactory.audioTrack(withTrackId: AUDIO_TRACK_ID)
            self.mediaStream = peerConnectionFactory.mediaStream(withStreamId: LOCAL_MEDIA_STREAM_ID)
            self.mediaStream.addAudioTrack(self.localAudioTrack)
            self.mediaStream.addVideoTrack(self.localVideoTrack)
            
            self.viewLocalVideo.insertSubview(self.localVideo, at: 0)
            // hide local video container when calling
            self.viewLocalVideo.isHidden = true
            
            // add local video to remote video when calling
            self.viewRemoteVideo.insertSubview(self.localVideo, at: 0)
        }
    }
    
    fileprivate func swapCaptureDevice(front: Bool) -> RTCVideoTrack {
        var device: AVCaptureDevice! = nil
        var _localVideoTrack: RTCVideoTrack! = nil
        
        for captureDevice in AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) {
            if (front) {
                if ((captureDevice as AnyObject).position == AVCaptureDevicePosition.front) {
                    device = captureDevice as! AVCaptureDevice
                }
            } else {
                if ((captureDevice as AnyObject).position == AVCaptureDevicePosition.back) {
                    device = captureDevice as! AVCaptureDevice
                }
            }
        }
        
        if (device != nil) {
            let videoConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
            
            let videoSource = peerConnectionFactory.avFoundationVideoSource(with: videoConstraints)
            _localVideoTrack = peerConnectionFactory.videoTrack(with: videoSource, trackId: VIDEO_TRACK_ID)
        }
        
        return _localVideoTrack
    }
    
    fileprivate func preparePeerConnection() {

        let icsServers: [RTCIceServer] = [
            RTCIceServer.init(urlStrings: STUNServer, username: "", credential: ""),
            RTCIceServer.init(urlStrings: TURNServer, username: "sangkil", credential: "qiscuslova")
        ]
        var pcConstraints: RTCMediaConstraints! = nil
        pcConstraints = RTCMediaConstraints(mandatoryConstraints: nil
            , optionalConstraints: ["DtlsSrtpKeyAgreement" : "true"])
        let config = RTCConfiguration()
        config.iceServers = icsServers
        self.peerConnection = self.peerConnectionFactory.peerConnection(with: config, constraints: pcConstraints, delegate: self)
        
        self.peerConnection.add(self.mediaStream)
    }
    
    fileprivate func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: AnyObject]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    fileprivate func escapeString(string: String) -> String {
        let newString = string.replacingOccurrences(of: "\r", with: "\\r", options: NSString.CompareOptions.literal, range: nil)
        return newString.replacingOccurrences(of: "\n", with: "\\n", options: NSString.CompareOptions.literal, range: nil)
    }
    
    fileprivate func disconnectOnTimeout(timeoutInSeconds: Int) {
        timeoutTimer = Timer.scheduledTimer(timeInterval: TimeInterval(timeoutInSeconds), target: self, selector: #selector(disconnectWithTimeout), userInfo: nil, repeats: false)
        
    }
    
    @objc fileprivate func disconnectWithTimeout() {
        if !self.isCallAccepted {
            self.disconnect()
        }
    }
    
    fileprivate func disconnect() {
        self.navigationController?.popViewController(animated: true)
        self.dismiss(animated: true, completion: nil)
        self.presenter.setActive(isActive: false)
        self.setupProximity(isOn: false)
        self.socket.disconnect()
        self.peerConnection.close()
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    func present(vc: UIViewController, transitionMode: UIModalTransitionStyle) {
        self.modalTransitionStyle = transitionMode
        vc.present(self, animated: true, completion: nil)
    }
}

extension CallingScreenVC : RTCVideoCapturerDelegate {
    func capturer(_ capturer: RTCVideoCapturer, didCapture frame: RTCVideoFrame) {
        //
    }
}


