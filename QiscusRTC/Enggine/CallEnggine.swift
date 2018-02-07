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

class CallEngineView : UIView {
    
}

protocol CallEnggineDelegate {
    //
    func didReceiveLocalVideo(view: UIView)
    func callEnggine(connectionChanged newState: CallConnectionState)
    func callEnggine(gotCandidate dataMid: String, dataIndex: Int, dataSdp: String)
    func callEnggine(createSession type: String, description: String)
}

let VIDEO_TRACK_ID = "VIDEO0"
let AUDIO_TRACK_ID = "AUDIO0"
let LOCAL_MEDIA_STREAM_ID = "STREAM0"

let STUNServer  = ["stun:stun.l.google.com:19302", "stun:139.59.110.14:3478"]
let TURNServer  = ["turn:139.59.110.14:3478"]
let WSServer    = "wss://rtc.qiscus.com/signal"

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
    var mediaConstraints = RTCMediaConstraints(mandatoryConstraints: [
        "OfferToReceiveAudio" : "true", "OfferToReceiveVideo" : "true"
        ], optionalConstraints: nil)
    
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
        self.setSessionDescription(dataType: .offer, sdp: sdp)
        self.peerConnection.createOffer(with: self, constraints: self.mediaConstraints)
    }
    
    func setAnswer(dataType: String, sdp: String) {
        self.setSessionDescription(dataType: .answer, sdp: sdp)
        self.peerConnection.createAnswer(with: self, constraints: self.mediaConstraints)
        self.peerConnection.answer(for: self.mediaConstraints, completionHandler: { (sessionDescriptoin, error) in
            //
        })
    }
    
    func setCandidate(dataMid: String, dataIndex: Int, dataCandidate: String) {
        let iceSet = RTCIceCandidate(sdp: dataCandidate, sdpMLineIndex: Int32(dataIndex), sdpMid: dataMid)
        self.peerConnection.add(iceSet)
    }
    
    // RTC
    func setSessionDescription(dataType: RTCSdpType, sdp: String) {
        let sdpSet = RTCSessionDescription(type: dataType, sdp: sdp)
        self.peerConnection.setRemoteDescriptionWith(self, sessionDescription: sdpSet)
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
            
            //self.viewLocalVideo.insertSubview(self.localVideo, at: 0)
            // hide local video container when calling
            //self.viewLocalVideo.isHidden = true
            
            // add local video to remote video when calling
            //self.viewRemoteVideo.insertSubview(self.localVideo, at: 0)
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
        if (candidate != nil) {
            self.delegate.callEnggine(gotCandidate: candidate.sdpMid!, dataIndex: Int(candidate.sdpMLineIndex), dataSdp: candidate.sdp)
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
            remoteVideoTrack            = stream.videoTracks[0] as! RTCVideoTrack
            remoteVideoTrack.isEnabled  = true;
            remoteVideoTrack.add(self.remoteVideo)
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

//extension CallEnggine: RTCSessionDescriptionDelegate {
//    func peerConnection(_ peerConnection: RTCPeerConnection!, didCreateSessionDescription sdp: RTCSessionDescription!, error: Error!) {
//        if (error == nil) {
//            //self.player?.stop()
//            peerConnection.setLocalDescriptionWith(self, sessionDescription: sdp)
//            print("[RTC-HUB] Got local offer/answer")
//            self.delegate.callEnggine(createSession: sdp.type, description: sdp.description)
//
//        } else {
//            print("[RTC-HUB] SDP creation error: " + error.localizedDescription)
//        }
//    }
//
//    func peerConnection(_ peerConnection: RTCPeerConnection!, didSetSessionDescriptionWithError error: Error!) {
//    }
//}

