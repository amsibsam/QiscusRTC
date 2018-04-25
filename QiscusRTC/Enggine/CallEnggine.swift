//
//  File.swift
//  Garuda
//
//  Everything about WebRTC Here
//
//  Created by Qiscus on 23/01/18.
//  Copyright © 2018 qiscus. All rights reserved.
//

import Foundation
import AVFoundation
import WebRTC

enum CallConnectionState: String {
    case new        = "NEW"
    case connected  = "CONNECTED"
    case failed     = "FAILED"
}

enum CallSDPType : String {
    case answer = "answer"
    case offer  = "offer"
}

class CallEngineView : UIView {
    
}

protocol CallEnggineDelegate {
    //
    func didReceive(Local video: UIView)
    func didReceive(Remote video: UIView, local: UIView)
    func didChangedVideoSize(videoView: UIView, size: CGSize, local: UIView, remote: UIView)
    func callEnggine(connectionChanged newState: CallConnectionState)
    func callEnggine(gotCandidate dataMid: String, dataIndex: Int, dataSdp: String)
    func callEnggine(createSession type: CallSDPType, description: String)
}

let VIDEO_TRACK_ID = "VIDEO0"
let AUDIO_TRACK_ID = "AUDIO0"
let LOCAL_MEDIA_STREAM_ID = "STREAM0"

let STUNServer  = ["stun:stun.l.google.com:19302", "stun:139.59.110.14:3478"]
let TURNServer  = ["turn:139.59.110.14:3478"]
let WSServer    = "wss://rtc.qiscus.com/signal"

class CallEnggine: NSObject {
    // public
    var state                   : String    = ""
    
    // webrtc
    var peerConnectionFactory   : RTCPeerConnectionFactory! = RTCPeerConnectionFactory()
    var peerConnection          : RTCPeerConnection!    = nil
    var mediaStream             : RTCMediaStream!       = nil
    var localVideo              : RTCEAGLVideoView!     = nil
    let localVideoTAG           : Int = 1
    var localVideoRenderer      : RTCVideoRenderer!     = nil
    var remoteVideo             : RTCEAGLVideoView!     = nil
    let remoteVideoTAG          : Int = 2
    var localVideoTrack         : RTCVideoTrack!    = nil
    var localAudioTrack         : RTCAudioTrack!    = nil
    var remoteVideoTrack        : RTCVideoTrack!    = nil
    var remoteAudioTrack        : RTCAudioTrack!    = nil
    var videoSource             : RTCAVFoundationVideoSource! = nil
    var mediaConstraints = RTCMediaConstraints(mandatoryConstraints: [
        "OfferToReceiveAudio" : "true", "OfferToReceiveVideo" : "true"
        ], optionalConstraints: nil)
    
    internal var delegate : CallEnggineDelegate
    private var isMuted         : Bool = false
    private var activeSpeaker   : Bool = false
    
    // Call Action
    var isAudioMute : Bool  {
        get {
            return self.isMuted
        }
        set {
            // Do Something
            self.muted(value: newValue)
        }
    }
    
    var isLoadSpeaker : Bool {
        get {
            return activeSpeaker
        }
        set {
            // Do Something
            self.loadspeaker(value: newValue)
        }
    }
    
    var isVideoMute : Bool {
        get {
            return false
        }
        set {
            // Do Something
        }
    }
    
    init(delegate del: CallEnggineDelegate) {
        self.delegate   = del
        RTCInitializeSSL()
    }
    
    func end() {
        self.peerConnection.close()
        self.videoSource            = nil
        self.peerConnection         = nil
        self.localVideo             = nil
        self.remoteVideo            = nil
        self.localAudioTrack        = nil
        self.remoteAudioTrack       = nil
        self.remoteVideoTrack       = nil
        self.localVideoTrack        = nil
        self.peerConnection         = nil
        self.mediaStream            = nil
    }
    
    func setup() {
        self.captureDevice()
        
        // set default speaker
        self.activeSpeaker  = false
        self.isLoadSpeaker  = false
    }
    
    func start() {
        
    }
    
    private func muted(value: Bool) {
        if value {
            let localStream = self.peerConnection.localStreams[0] 
            if !localStream.audioTracks.isEmpty {
                let _localAudioTrack = localStream.audioTracks[0] ;
                localStream.removeAudioTrack(_localAudioTrack)
                self.peerConnection.remove(localStream)
                self.peerConnection.add(localStream)
                self.isMuted = true
            }
        } else {
            if !self.peerConnection.localStreams.isEmpty {
                let localStream = self.peerConnection.localStreams[0] ;
                localStream.addAudioTrack(self.localAudioTrack)
                self.peerConnection.remove(localStream)
                self.peerConnection.add(localStream)
                self.isMuted = false
            }
        }
    }
    
    func loadspeaker(value: Bool) {
        if value {
            do {
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
                self.activeSpeaker = true
            } catch {
                print(error.localizedDescription)
            }
        }else {
            do {
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
                self.activeSpeaker = false
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func configureAudioSession() {
        // See https://forums.developer.apple.com/thread/64544
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        try? session.setMode(AVAudioSessionModeVoiceChat)
        try? session.setPreferredSampleRate(44100.0)
        try? session.setPreferredIOBufferDuration(0.005)
    }
    
    func setOffer() {
        self.peerConnection.offer(for: self.mediaConstraints) { (description, err) in
            if let e = err {
                print("failed to create offer", e)
            }
            
            if let d = description {
                self.peerConnection.setLocalDescription(d, completionHandler: { (error) in
                    // nothing todo
                    if error != nil {
                        print("error set local description \(String(describing: error?.localizedDescription))")
                        return
                    }
                    self.delegate.callEnggine(createSession: .offer, description: d.sdp)
                })
            }
        }
    }
    
    func setAnswer(dataType: String, sdp: String) {
        let d = RTCSessionDescription(type: .offer, sdp: sdp)
        self.peerConnection.setRemoteDescription(d) { (err) in
            if let err = err {
                print("failed to set remote offer", err)
            } else {
                self.peerConnection.answer(for: self.mediaConstraints, completionHandler: { (description, err) in
                    if let e = err {
                        print("failed to create offer", e)
                    }
                    
                    if let d = description {
                        self.peerConnection.setLocalDescription(d, completionHandler: { (error) in
                            // nothing todo
                            if error != nil {
                                print("error set local description \(String(describing: error?.localizedDescription))")
                                return
                            }
                            self.delegate.callEnggine(createSession: .answer, description: d.sdp)
                        })
                    }
                })
            }
        }
    }
    
    func setCandidate(dataMid: String, dataIndex: Int, dataCandidate: String) {
        let iceSet = RTCIceCandidate(sdp: dataCandidate, sdpMLineIndex: Int32(dataIndex), sdpMid: dataMid)
        self.peerConnection.add(iceSet)
    }
    
    // RTC
    func setRemoteDescription(sdp: String) {
        let d = RTCSessionDescription(type: .answer, sdp: sdp)
        self.peerConnection.setRemoteDescription(d) { (err) in
            if let err = err {
                print("failed to set remote offer", err)
            } else {
                // Start Call timer
                self.delegate.callEnggine(connectionChanged: CallConnectionState.connected)
            }
        }
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
    
    fileprivate func captureDevice() {
        let device = UIDevice.string(for: UIDevice.deviceType())
        self.peerConnectionFactory = RTCPeerConnectionFactory()
        if (device != nil) {
            self.localVideo = RTCEAGLVideoView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height))
            self.localVideo.tag = self.localVideoTAG
            self.localVideo.delegate = self
            self.remoteVideo = RTCEAGLVideoView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height))
            self.remoteVideo.tag = self.remoteVideoTAG
            self.remoteVideo.delegate = self
            
            let videoConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
            videoSource = self.peerConnectionFactory.avFoundationVideoSource(with: videoConstraints)
            videoSource.useBackCamera = false
            self.localVideoTrack = self.peerConnectionFactory.videoTrack(with: videoSource, trackId: VIDEO_TRACK_ID)
            self.localVideoTrack.add(self.localVideo)
            
            self.localAudioTrack = peerConnectionFactory.audioTrack(withTrackId: AUDIO_TRACK_ID)
            self.mediaStream = peerConnectionFactory.mediaStream(withStreamId: LOCAL_MEDIA_STREAM_ID)
            self.mediaStream.addAudioTrack(self.localAudioTrack)
            self.mediaStream.addVideoTrack(self.localVideoTrack)
            self.localVideo.backgroundColor = UIColor.black
            localVideo.renderFrame(nil)
            self.delegate.didReceive(Local: localVideo)
            
            if self.peerConnection == nil {
                self.preparePeerConnection()
            }
        }
    }
    
    func switchCameraBack() {
        videoSource.useBackCamera   = true
        let localStream = self.peerConnection.localStreams[0]
        self.peerConnection.remove(localStream)
        self.peerConnection.add(localStream)
    }
    
    func switchCameraFront() {
        videoSource.useBackCamera   = false
        let localStream = self.peerConnection.localStreams[0]
        self.peerConnection.remove(localStream)
        self.peerConnection.add(localStream)
    }
}

extension CallEnggine: RTCEAGLVideoViewDelegate {
    func videoView(_ videoView: RTCEAGLVideoView, didChangeVideoSize size: CGSize) {
        print("did change video size : \(size), TAG : \(videoView.tag)")
        if self.localVideo != nil && self.remoteVideo != nil {
            self.delegate.didChangedVideoSize(videoView: videoView, size: size, local: self.localVideo, remote: self.remoteVideo)
        }
    }
}

// MARK: after call preparePeerConnection()
extension CallEnggine: RTCPeerConnectionDelegate {
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        //
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        if (newState == .new) {
            self.delegate.callEnggine(connectionChanged: CallConnectionState.new)
        } else if (newState == .connected) {
            self.delegate.callEnggine(connectionChanged: CallConnectionState.connected)
        } else if (newState == .failed) {
            self.delegate.callEnggine(connectionChanged: CallConnectionState.failed)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("[RTC-HUB] Signaling state: \(stateChanged.rawValue)")
        if stateChanged.rawValue == 0 {
            
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        //
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        self.delegate.callEnggine(gotCandidate: candidate.sdpMid!, dataIndex: Int(candidate.sdpMLineIndex), dataSdp: candidate.sdp)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        if (stream.audioTracks.count > 1 || stream.videoTracks.count > 1) {
            print("[RTC-HUB] Weird-looking stream: " + stream.description)
            return
        }
        if (stream.videoTracks.count == 1) {
            remoteVideoTrack            = stream.videoTracks[0] 
            remoteVideoTrack.isEnabled  = true;
            remoteVideoTrack.add(self.remoteVideo)
            
            self.delegate.didReceive(Remote: self.remoteVideo, local: self.localVideo)
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

extension CallEnggine : RTCVideoCapturerDelegate {
    func capturer(_ capturer: RTCVideoCapturer, didCapture frame: RTCVideoFrame) {
        
    }
}
