//
//  CallUIPresenter.swift
//  Garuda
//
//  Created by Qiscus on 05/02/18.
//  Copyright © 2018 qiscus. All rights reserved.
//

import Foundation

protocol CallView {
    func CallStatusChange(state: String)
    func Call(update Duration: Int)
}

class CallUIPresenter {
    private let manager = QiscusRTC.shared.manager
    private var viewPresenter   : CallView?
    
    var isAudioMute : Bool {
        get {
            return manager.isAudioMute
        }
        set{
            self.manager.isAudioMute = newValue
        }
    }
    var isLoadSpeaker : Bool {
        get {
            return self.manager.isLoadSpeaker
        }
        set{
            self.manager.isLoadSpeaker = newValue
        }
    }
    
    init() {
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
        
        return URL(string: "http://")!
    }
    
    func getDuration() -> Int? {
        return manager.getDuration()
    }
}
