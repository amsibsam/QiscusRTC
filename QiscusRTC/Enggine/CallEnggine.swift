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

enum CallConnectionState: String {
    case new        = "NEW"
    case connected  = "CONNECTED"
    case failed     = "FAILED"
}

class CallEngineView : UIView {
    
}

protocol CallEnggineDelegate {
    //
    func didReceiveLocalVideo(view: UIView)
    func callEnggine(connectionChanged newState: CallConnectionState)
    func callEnggine(gotCandidate dataMid: String, dataIndex: Int, dataSdp: String)
    func callEnggine(createSession type: String, description: String)
}

class CallEnggine: NSObject {
    // public
    var viewLocalVideo          : UIView?
    var viewRemoteVideo         : UIView?
    var state                   : String    = ""
    
    // webrtc
    var peerConnectionFactory   : RTCPeerConnectionFactory! = RTCPeerConnectionFactory()
    var peerConnection          : RTCPeerConnection!    = nil
    var mediaStream             : RTCMediaStream!       = nil
    var localVideo              : RTCEAGLVideoView!
    let localVideoTAG           : Int = 1
    var localVideoRenderer      : RTCVideoRenderer!
    var remoteVideo             : RTCEAGLVideoView!
    let remoteVideoTAG          : Int = 2
    var localVideoTrack         : RTCVideoTrack!
    var localAudioTrack         : RTCAudioTrack!
    var remoteVideoTrack        : RTCVideoTrack!
    var remoteAudioTrack        : RTCAudioTrack!
    var mediaConstraints        = RTCMediaConstraints (
        mandatoryConstraints: [
            RTCPair(key: "OfferToReceiveAudio", value: "true"),
            RTCPair(key: "OfferToReceiveVideo", value: "true")
        ],optionalConstraints: nil)
    
    internal var delegate : CallEnggineDelegate
    private var isMuted : Bool  = false
    private var activeSpeaker : Bool = false
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
    }
    
    func end() {
        self.peerConnection.close()
        self.localVideo             = nil
        self.remoteVideo            = nil
        self.localAudioTrack        = nil
        self.remoteAudioTrack       = nil
        self.remoteVideoTrack       = nil
        self.localAudioTrack        = nil
        self.peerConnection         = nil
        self.mediaStream            = nil
    }
    
    func setup() {
        self.captureDevice()
        self.preparePeerConnection()
        // set default speaker
        self.activeSpeaker  = false
        self.isLoadSpeaker  = false
    }
    
    func start() {
        
    }
    
    private func muted(value: Bool) {
        if value {
            let localStream = self.peerConnection.localStreams[0] as! RTCMediaStream
            if !localStream.audioTracks.isEmpty {
                let _localAudioTrack = localStream.audioTracks[0] as! RTCAudioTrack;
                localStream.removeAudioTrack(_localAudioTrack)
                self.peerConnection.remove(localStream)
                self.peerConnection.add(localStream)
                self.isMuted = true
            }
        } else {
            if !self.peerConnection.localStreams.isEmpty {
                let localStream = self.peerConnection.localStreams[0] as! RTCMediaStream;
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
    
    func setOffer(dataType: String, sdp: String) {
        self.setSessionDescription(dataType: dataType, sdp: sdp)
        self.peerConnection.createOffer(with: self, constraints: self.mediaConstraints)
    }
    
    func setAnswer(dataType: String, sdp: String) {
        self.setSessionDescription(dataType: dataType, sdp: sdp)
        self.peerConnection.createAnswer(with: self, constraints: self.mediaConstraints)
    }
    
    func setCandidate(dataMid: String, dataIndex: Int, dataCandidate: String) {
        let iceSet = RTCICECandidate(mid: dataMid, index: dataIndex, sdp: dataCandidate)
        self.peerConnection.add(iceSet)
    }
    
    // RTC
    func setSessionDescription(dataType: String, sdp: String) {
        let sdpSet = RTCSessionDescription(type: dataType, sdp: sdp)
        self.peerConnection.setRemoteDescriptionWith(self, sessionDescription: sdpSet)
    }
    
    fileprivate func preparePeerConnection() {
        let googleStunUrl: URL = URL(string: "stun:stun.l.google.com:19302")!
        let qiscusStunUrl: URL = URL(string: "stun:139.59.110.14:3478")!
        let qiscusTurnUrl: URL = URL(string: "turn:139.59.110.14:3478")!
        let icsServers: [RTCICEServer] = [
            RTCICEServer.init(uri: googleStunUrl, username: "", password: ""),
            RTCICEServer.init(uri: qiscusStunUrl, username: "", password: ""),
            RTCICEServer.init(uri: qiscusTurnUrl, username: "sangkil", password: "qiscuslova")
        ]
        var pcConstraints: RTCMediaConstraints! = nil
        let optionalConstraints:NSArray = [RTCPair(key: "DtlsSrtpKeyAgreement", value: "true")]
        pcConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: optionalConstraints as [AnyObject])
        
        self.peerConnection = self.peerConnectionFactory.peerConnection(withICEServers: icsServers, constraints: pcConstraints, delegate: self)
        self.peerConnection.add(self.mediaStream)
    }
    
    fileprivate func captureDevice() {
        var device: AVCaptureDevice! = nil
        
        for captureDevice in AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) {
            if ((captureDevice as AnyObject).position == AVCaptureDevicePosition.front) {
                device = captureDevice as! AVCaptureDevice
            }
        }
        
        if (device != nil) {
            let capturer = RTCVideoCapturer(deviceName: device.localizedName)
            let videoConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
            
            let videoSource = peerConnectionFactory.videoSource(with: capturer, constraints: videoConstraints)
            
            self.localVideo = RTCEAGLVideoView(frame: CGRect(x: 0, y: 0, width: CGFloat.screenWidth, height: CGFloat.screenHeight))
            self.localVideo.tag = self.localVideoTAG
            self.localVideo.delegate = self
            
            self.remoteVideo = RTCEAGLVideoView(frame: CGRect(x: 0, y: 0, width: CGFloat.screenWidth, height: CGFloat.screenHeight))
            self.remoteVideo.tag = self.remoteVideoTAG
            self.remoteVideo.delegate = self
            
            self.localVideoTrack = peerConnectionFactory.videoTrack(withID: VIDEO_TRACK_ID, source: videoSource)
            self.localVideoTrack.add(self.localVideo)
            self.localAudioTrack = peerConnectionFactory.audioTrack(withID: AUDIO_TRACK_ID)
            self.mediaStream = peerConnectionFactory.mediaStream(withLabel: LOCAL_MEDIA_STREAM_ID)
            self.mediaStream.addAudioTrack(self.localAudioTrack)
            self.mediaStream.addVideoTrack(self.localVideoTrack)
            
            /*
            self.viewLocalVideo.insertSubview(self.localVideo, at: 0)
            self.viewLocalVideo.clipsToBounds = true
            // hide local video container when calling
            self.viewLocalVideo.isHidden = true
            // add local video to remote video when calling
            self.viewRemoteVideo.insertSubview(self.localVideo, at: 0)
            self.viewRemoteVideo.clipsToBounds = true
            */
        }
    }
}

extension CallEnggine: RTCEAGLVideoViewDelegate {
    func videoView(_ videoView: RTCEAGLVideoView!, didChangeVideoSize size: CGSize) {
        print("did change video size : \(size), TAG : \(videoView.tag)")
        if(videoView.tag == self.localVideoTAG){
            var targetSize = self.viewLocalVideo?.frame.size
//            if(!self.viewVideoMask.isHidden){
//                targetSize = self.viewRemoteVideo.frame.size
//            }
            
//            let rect = scaleVideo(videoSize: size, targetFrameSize: targetSize)
//
//            self.localVideo.frame = rect
            
        }else{
//            var targetSize = self.viewRemoteVideo.frame.size
//
//            let rect = scaleVideo(videoSize: size, targetFrameSize: targetSize)
//
//            self.remoteVideo.frame = rect
        }
        
    }
}

// MARK: after call preparePeerConnection()
extension CallEnggine: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection!, signalingStateChanged stateChanged: RTCSignalingState) {
        print("[RTC-HUB] Signaling state: \(stateChanged.rawValue)")
        if stateChanged.rawValue == 0 {
            
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, iceConnectionChanged newState: RTCICEConnectionState) {
        if (newState == RTCICEConnectionNew) {
            self.delegate.callEnggine(connectionChanged: CallConnectionState.new)
        } else if (newState == RTCICEConnectionConnected) {
            self.delegate.callEnggine(connectionChanged: CallConnectionState.connected)
        } else if (newState == RTCICEConnectionFailed) {
            self.delegate.callEnggine(connectionChanged: CallConnectionState.failed)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, iceGatheringChanged newState: RTCICEGatheringState) {
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, gotICECandidate candidate: RTCICECandidate!) {
        if (candidate != nil) {
            self.delegate.callEnggine(gotCandidate: candidate.sdpMid, dataIndex: candidate.sdpMLineIndex, dataSdp: candidate.sdp)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, addedStream stream: RTCMediaStream!) {
        if (peerConnection == nil) {
            return
        }
        if (stream.audioTracks.count > 1 || stream.videoTracks.count > 1) {
            print("[RTC-HUB] Weird-looking stream: " + stream.description)
            return
        }
        if (stream.videoTracks.count == 1) {
            remoteVideoTrack = stream.videoTracks[0] as! RTCVideoTrack
            remoteVideoTrack.setEnabled(true)
            remoteVideoTrack.add(self.remoteVideo);
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, removedStream stream: RTCMediaStream!) {
        // remoteVideoTrack = nil
        // stream.videoTracks[0].dispose();
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, didOpen dataChannel: RTCDataChannel!) {
        print("peer connection open")
    }
    
    func peerConnection(onRenegotiationNeeded peerConnection: RTCPeerConnection!) {
    }
}

extension CallEnggine: RTCSessionDescriptionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection!, didCreateSessionDescription sdp: RTCSessionDescription!, error: Error!) {
        if (error == nil) {
            //self.player?.stop()
            peerConnection.setLocalDescriptionWith(self, sessionDescription: sdp)
            print("[RTC-HUB] Got local offer/answer")
            self.delegate.callEnggine(createSession: sdp.type, description: sdp.description)
            
        } else {
            print("[RTC-HUB] SDP creation error: " + error.localizedDescription)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, didSetSessionDescriptionWithError error: Error!) {
    }
}
