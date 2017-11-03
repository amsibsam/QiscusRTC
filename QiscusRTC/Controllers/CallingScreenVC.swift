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

struct CallData {
    var targetName: String = ""
    var targetAvatar: String = ""
    var targetEmail: String = ""
    var targetEmailQiscus: String = ""
    var myEmailQiscus: String = ""
    var callRoomId: String = ""
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
    
    
    //programmatically ui element
    var backgroundGradient: UIImageView!
    
    //presenter
    var presenter: CallingPresenterInteraction!
    
    //data variable
    var isVideoCall: Bool = false
    var callData: CallData!
    var isReceiving: Bool = false
    var player: AVAudioPlayer?
    var wsReconnectCount: Int = 0
    
    //button state variable
    var isSpeakerOn: Bool = false
    var isMicOn: Bool = true
    
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
    var mediaConstraints = RTCMediaConstraints(
        mandatoryConstraints: [
//            RTCPair(key: "OfferToReceiveAudio", value: "true"),
//            RTCPair(key: "OfferToReceiveVideo", value: "true")
            :],
        optionalConstraints: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //setup presenter
        presenter = CallingPresenter(delegate: self)
        
        //setup ui
        self.setupUI()
        presenter.startCalling()
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
        self.btnAccept.isHidden = true
        //self.peerConnection.createOffer(with: self, constraints: self.mediaConstraints)
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
    }
    
    @IBAction func onSpeakerDidTap(_ sender: Any) {
        //set button image state
        if isSpeakerOn {
            self.btnSpeaker.setImage(UIImage(named: "bt_speaker_off"), for: .normal)
            try! AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
        } else {
            self.btnSpeaker.setImage(UIImage(named: "bt_speaker_on"), for: .normal)
            try! AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
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
            let _localAudioTrack = localStream.audioTracks[0] as! RTCAudioTrack;
            localStream.addAudioTrack(_localAudioTrack)
            self.peerConnection.remove(localStream)
            self.peerConnection.add(localStream)
        }
        
        //reverse button state status
        self.isMicOn = !isMicOn
    }
}

//presenter delegate
extension CallingScreenVC: CallingPresenterDelegate {
    func onEndCall() {
        self.dismiss(animated: true, completion: nil)
        self.navigationController?.popViewController(animated: true)
        self.setupProximity(isOn: false)
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
extension CallingScreenVC: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        //
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        //
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        //
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        //
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        //
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        //
    }

    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        //
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("[HUB-RTC] Signaling state: \(stateChanged.rawValue)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, addedStream stream: RTCMediaStream!) {
        if (peerConnection == nil) {
            return
        }
        if (stream.audioTracks.count > 1 || stream.videoTracks.count > 1) {
            print("[HUB-RTC] Weird-looking stream: " + stream.description)
            return
        }
        if (stream.videoTracks.count == 1) {
            remoteVideoTrack = stream.videoTracks[0] as! RTCVideoTrack
            remoteVideoTrack.isEnabled = true
            remoteVideoTrack.add(self.remoteVideo);
            self.viewRemoteVideo.addSubview(self.remoteVideo)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, removedStream stream: RTCMediaStream!) {
        remoteVideoTrack = nil
//        stream.videoTracks[0].dispose();
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("peer connection open")
    }
    
    func peerConnection(onRenegotiationNeeded peerConnection: RTCPeerConnection!) {
    }
}

//session description delegate
//extension CallingScreenVC: RTCSessionDescriptionDelegate {
//    func peerConnection(_ peerConnection: RTCPeerConnection!, didCreateSessionDescription sdp: RTCSessionDescription!, error: Error!) {
//        if (error == nil) {
//            DispatchQueue.main.async {
//                self.presenter.startTimer()
//                self.player?.stop()
//                try! AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
//            }
//
//            peerConnection.setLocalDescriptionWith(self, sessionDescription: sdp)
//            print("[RTC-HUB] Got local offer/answer")
//
//            if (sdp.type == "offer") {
//                self.sendOffer(sdp: sdp)
//            } else {
//                self.sendAnswer(sdp: sdp)
//            }
//        } else {
//            print("[HUB-RTC] SDP creation error: " + error.localizedDescription)
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
        setupProximity(isOn: true)
        setupWebsocket()
        captureDevice()
        preparePeerConnection()
    }
    
    
    /// determine voice call or video call ui
    fileprivate func callTypeUI() {
        if self.isVideoCall {
            self.lbName.isHidden = true
            self.lbTimer.isHidden = true
        } else {
            self.viewHeader.isHidden = true
            self.viewLocalVideo.isHidden = true
            self.viewRemoteVideo.isHidden = true
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
        let placeHolderImage: UIImage   = UIImage(named: "avatar")!
        
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
            
            self.navigationController?.popViewController(animated: true)
        }
        self.socket.onText = { (text: String) in
            print("[Hub] Got some text: \(text)")
            print("[]")
            let message = text.data(using: String.Encoding.utf8)
            
            do {
                let json = try JSONSerialization.jsonObject(with: message!, options: JSONSerialization.ReadingOptions.mutableContainers)
                if let dict = json as? NSDictionary {
                    if let response = dict.value(forKey: "response") as? String {
                        let data = dict.value(forKey: "data") as? String
                        let dataObj = try JSONSerialization.jsonObject(with: (data?.data(using: String.Encoding.utf8)!)!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
                        
                        if response == "register" {
                            if let success = dataObj?.value(forKey: "success") as? Bool {
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
                            // start ping
                        }
                    } else if let event = dict.value(forKey: "event") as? String {
                        let sender = dict.value(forKey: "sender") as? String
                        let data = dict.value(forKey: "data") as? String
                        let dataObj = try JSONSerialization.jsonObject(with: (data?.data(using: String.Encoding.utf8)!)!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
                        
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
                                // Close
                            }
                        } else if event == "room_data_private" {
                            let dataEvt = dataObj?.value(forKey: "event") as? String
                            let dataType = dataObj?.value(forKey: "type") as? String
                            
                            if (dataEvt != nil) {
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
                                    self.playSound()
                                } else if dataEvt == "call_accept" {
                                    // Set state to connecting
                                    self.peerConnection.offer(for: self.mediaConstraints, completionHandler: { (sessionDescription, error) in
                                        //
                                    })
                                } else if dataEvt == "call_reject" {
                                    self.navigationController?.popViewController(animated: true)
                                    // Rejected
                                } else if dataEvt == "call_cancel" {
                                    // Canceled
                                    self.navigationController?.popViewController(animated: true)
                                }
                            } else if (dataType != nil) {
                                let dataSDP = dataObj?.value(forKey: "sdp") as? String
                                let dataMid = dataObj?.value(forKey: "sdpMid") as? String
                                let dataIndex = dataObj?.value(forKey: "sdpMLineIndex") as? Int
                                let dataCandidate = dataObj?.value(forKey: "candidate") as? String
                                
                                if dataType == "offer" {
                                    let sdpSet = RTCSessionDescription(type: RTCSdpType.offer, sdp: dataSDP!)
                                    self.peerConnection.setRemoteDescription(sdpSet, completionHandler: { (error) in
                                        //
                                    })
                                    self.peerConnection.answer(for: self.mediaConstraints, completionHandler: { (sessionDescription, error) in
                                        //
                                    })
                                    print("[RTC-HUB] Got remote offer")
                                } else if dataType == "answer" {
                                    let sdpSet = RTCSessionDescription(type: RTCSdpType.answer, sdp: dataSDP!)
                                    self.peerConnection.setRemoteDescription(sdpSet, completionHandler: { (error) in
                                        //
                                    })
                                    print("[RTC-HUB] Got remote answer")
                                } else if dataType == "candidate" {
                                    let iceSet = RTCIceCandidate(sdp: dataCandidate!, sdpMLineIndex: Int32(dataIndex!), sdpMid: dataMid)
                                    self.peerConnection.add(iceSet)
                                    print("[RTC-HUB] Got remote candidate")
                                }
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
                "data": "{\"type\": \"offer\", \"sdp\": \"\(sdp.description as String)\"}"
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
                "data": "{\"type\": \"answer\", \"sdp\": \"\(sdp.description as String)\"}"
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
                "data": "{\"type\": \"candidate\", \"sdpMLineIndex\": \(candidate.sdpMLineIndex), \"sdpMid\": \"\(candidate.sdpMid)\", \"candidate\": \"\(candidate.sdp as String)\"}"
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
        gradient.colors     = [UIColor.black, UIColor.white]
        gradient.locations  = [0.0 , 1.0]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradient.endPoint   = CGPoint(x: 0.0, y: 0.85)
//        gradient.frame      = CGRect(x: 0, y: 0, width: CGFloat.screenWidth, height: CGFloat.screenHeight)
        
        return gradient
    }
    
    fileprivate func setupBackground() {
        // Set background with callee avatar
//        self.backgroundGradient = UIImageView(frame: CGRect(x: 0, y: 0, width: CGFloat.screenWidth, height: CGFloat.screenHeight))
        self.backgroundGradient.contentMode   = .scaleToFill
        self.backgroundGradient.layer.insertSublayer(setupGradient(), at: 0)
        self.view.addSubview(backgroundGradient)
//        self.view.backgroundColor = UIColor.baseNavigateColor
    }
    
    fileprivate func playSound() {
        var url = Bundle.main.url(forResource: self.isReceiving ? "phone_ring" : "phone_waiting", withExtension: "mp3")
        
        if self.player != nil {
            player?.stop()
            url = Bundle.main.url(forResource: "phone_ring", withExtension: "mp3")
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            self.player = try AVAudioPlayer(contentsOf: url!)
            self.player?.numberOfLoops = -1
            guard let player = player else { return }
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    fileprivate func captureDevice() {
        var device: AVCaptureDevice! = nil
        
//        for captureDevice in AVCaptureDevice.devices() {
//            if ((captureDevice as AnyObject).position == AVCaptureDevice.position.front) {
//                device = captureDevice as! AVCaptureDevice
//            }
//        }
        
        self.peerConnectionFactory = RTCPeerConnectionFactory()
        
        if (device != nil) {
            let capturer = RTCVideoCapturer(delegate: self)
            let videoConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
            
            let videoSource = peerConnectionFactory.videoSource()
            self.localVideo = RTCEAGLVideoView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
            self.remoteVideo = RTCEAGLVideoView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
//            self.localVideoTrack = peerConnectionFactory.videoTrack(with: VIDEO_TRACK_ID, trackId: videoSource)
            self.localVideoTrack.add(self.localVideo)
            self.localAudioTrack = peerConnectionFactory.audioTrack(withTrackId: AUDIO_TRACK_ID)
            self.mediaStream = peerConnectionFactory.mediaStream(withStreamId: LOCAL_MEDIA_STREAM_ID)
            self.mediaStream.addAudioTrack(self.localAudioTrack)
            self.mediaStream.addVideoTrack(self.localVideoTrack)
            
            self.viewLocalVideo.addSubview(self.localVideo)
        }
    }
    
    fileprivate func preparePeerConnection() {
        let googleStunUrl: NSURL = NSURL(string: "stun:stun.l.google.com:19302")!
        let qiscusStunUrl: NSURL = NSURL(string: "stun:139.59.110.14:3478")!
        let qiscusTurnUrl: NSURL = NSURL(string: "turn:139.59.110.14:3478")!
        let icsServers: [RTCIceServer] = [
            RTCIceServer.init(urlStrings: ["stun:stun.l.google.com:19302", "stun:139.59.110.14:3478"], username: "", credential: ""),
            RTCIceServer.init(urlStrings: ["turn:139.59.110.14:3478"], username: "sangkil", credential: "qiscuslova")
        ]
        var pcConstraints: RTCMediaConstraints! = nil
        pcConstraints = RTCMediaConstraints(mandatoryConstraints: nil
            , optionalConstraints: ["DtlsSrtpKeyAgreement" : "true"])
        let config = RTCConfiguration()
        config.iceServers = icsServers
        self.peerConnection = self.peerConnectionFactory.peerConnection(with: config, constraints: pcConstraints, delegate: self)
        
        self.peerConnection.add(self.mediaStream)
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
