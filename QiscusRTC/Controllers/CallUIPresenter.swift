//
//  CallUIPresenter.swift
//  Garuda
//
//  Created by Qiscus on 05/02/18.
//  Copyright © 2018 qiscus. All rights reserved.
//

import Foundation

protocol CallView {
    func CallStatusChange(state: CallState)
    func Call(update Duration: Int)
    func CallFinished()
    func callReceive(Local video: UIView)
    func callReceive(Remote video: UIView, local: UIView)
    func callVideoSizeChanged(videoView: UIView, size: CGSize, local: UIView?, remote: UIView?)
}

class CallUIPresenter {
    private let manager = QiscusRTC.shared.manager

    var viewPresenter   : CallView?
    
    var appName : String {
        get {
            return manager.config?.appName ?? ""
        }
    }
    var isAudioMute : Bool {
        get {
            return manager.isAudioMute
        }
        set {
            self.manager.isAudioMute = newValue
        }
    }
    var isLoadSpeaker : Bool {
        get {
            return self.manager.isLoadSpeaker
        }
        set {
            self.manager.isLoadSpeaker = newValue
        }
    }
    var isReceiving : Bool {
        get {
            return self.manager.isReceiving
        }
    }
    
    var isCallActive : Bool {
        get {
            return self.manager.isCallActive()
        }
    }
    
    init() {
        manager.callDelegate(self)
    }
    
    func attachView(view : CallView){
        viewPresenter = view
    }
    
    func detachView() {
        viewPresenter = nil
    }
    
    func finishCall() {
        self.manager.finishCall()
    }
    
    func getCallName() -> String {
        return manager.callSession?.name ?? "Unknown"
    }
    
    func getCallAvatar() -> URL {
        if let avatarUrl = manager.callSession?.callAvatar {
            return avatarUrl
        }
        
        return URL(string: "http://")!
    }
    
    func getDuration() -> Int? {
        return manager.getDuration()
    }
    
    func getLocalVideo() -> UIView? {
        return manager.getLocalVideo()
    }
    
    func getRemoteVideo() -> UIView? {
        return manager.getRemoteVideo()
    }
    
    func switchCameraBack(){
        manager.switchCameraBack()
    }
    
    func switchCameraFront(){
        manager.switchCameraFront()
    }
    
    func videoStream(enable: Bool) {
        manager.videoStream(enable: enable)
    }
}

extension CallUIPresenter : CallDelegate {
    func callVideoSizeChange(videoView: UIView, size: CGSize, local: UIView, remote: UIView) {
        self.viewPresenter?.callVideoSizeChanged(videoView: videoView, size: size, local: local, remote: remote)
    }
    
    func callReceive(Local video: UIView) {
        DispatchQueue.main.async {
            self.viewPresenter?.callReceive(Local: video)
        }
        print("receive local video")
    }
    
    func callReceive(Remote video: UIView, local: UIView) {
        DispatchQueue.main.async {
            self.viewPresenter?.callReceive(Remote: video, local: local)
        }
    }
    
    func callChange(state: CallState) {
        self.viewPresenter?.CallStatusChange(state: state)
    }
    
    func callConnect() {
        //
    }
    
    func callDisconnect(error: NSError?) {
        self.viewPresenter?.CallFinished()
    }
}
