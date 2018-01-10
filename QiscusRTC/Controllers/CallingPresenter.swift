//
//  CallingPresenter.swift
//  qisme
//
//  Created by Qiscus on 9/26/17.
//  Copyright © 2017 qiscus. All rights reserved.
//

import Foundation

protocol CallingPresenterDelegate {
    func onAcceptCall()
    func onEndCall()
    
    /// Function for that will give time duration
    ///
    /// - Parameter duration: timer dutation in string mm:ss
    func onTimerTic(duration: String)
}

protocol CallingPresenterInteraction {
    /// Function to interact with rtc to toggle speaker
    ///
    /// - Parameter isOn: state conditio for the speaker
    func toggleSpeaker(isOn: Bool)
    
    /// Function to interact with rtc to toggle mic
    ///
    /// - Parameter isOn: state condition for the microphone
    func toggleMic(isOn: Bool)
    
    /// Function to initiate call
    func startCalling()
    
    // TODO: remove this function from interaction
    func startTimer()
    
    /// Function to accept incoming call
    func acceptCall(userEmail: String, callRoomId: String)
    
    /// Funciton to end call
    func endCall()
    
    /// set condition of call state
    ///
    /// - Parameter isActive: call state
    func setActive(isActive: Bool)
}

class CallingPresenter: CallingPresenterInteraction {
    private let delegate: CallingPresenterDelegate!
    
    //timer variable
    private var timerDuration: Timer?
    private var timerCount: Int = 0
    
    init(delegate: CallingPresenterDelegate) {
        self.delegate = delegate
    }
    
    func setActive(isActive: Bool) {
        //let callManager = (UIApplication.shared.delegate as! AppDelegate).qismeApp?.callManager
        //callManager?.isCallActive = isActive
    }
    
    func startCalling() {
        //        self.startTimer()
    }
    
    func toggleMic(isOn: Bool) {
        
    }
    
    func toggleSpeaker(isOn: Bool) {
        
    }
    
    func acceptCall(userEmail: String, callRoomId: String) {
//        let callManager = (UIApplication.shared.delegate as! AppDelegate).qismeApp?.callManager
//        // do the rtc implementation
//        callManager?.initializeCall(userEmail: userEmail, userType: "caller", callRoomId: callRoomId, isVideo: false, callEvent: "accept") { (response) in
//            self.delegate.onAcceptCall()
//        }
    }
    
    func endCall() {
        // do the rtc implementation
        self.stopTimer()
        self.delegate.onEndCall()
    }
    
    //private func
    func startTimer() {
        self.timerDuration = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(CallingPresenter.onTimerTic), userInfo: nil, repeats: true)
    }
    
    private func stopTimer() {
        if self.timerDuration != nil {
            self.timerDuration?.invalidate()
        }
    }
    
    //selector func
    @objc func onTimerTic() {
        self.timerCount += 1
        var timerString = "00:00"
        
        if self.timerCount < 60 {
            let seconds = String(format: "%02d", timerCount)
            timerString = "00:\(seconds)"
        } else {
            let minutes = String(format: "%02d", UInt8(self.timerCount/60))
            let seconds = String(format: "%02d", (self.timerCount % 60))
            
            timerString = "\(minutes):\(seconds)"
        }
        
        self.delegate.onTimerTic(duration: timerString)
    }
}


