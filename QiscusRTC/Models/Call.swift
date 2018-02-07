//
//  Call.swift
//  Garuda
//
//  Created by Qiscus on 18/01/18.
//  Copyright © 2018 qiscus. All rights reserved.
//

class CallConfig {
    var signalUrl   : URL
    var appID       : String
    var secretKey   : String
    
    init(signalUrl : URL, appID: String, secretKey: String) {
        self.signalUrl  = signalUrl
        self.appID      = appID
        self.secretKey  = secretKey
    }
}

enum CallState {
    case connecting
    case active
    case held
    case ended
}

enum ConnectedState {
    case pending
    case complete
}

class Call {
    
    let uuid        : UUID
    let outgoing    : Bool
    let name        : String
    let room        : String
    let isAudio     : Bool
    var duration    : Int   = 0
    let callAvatar  : URL
    
    var state: CallState = .ended {
        didSet {
            stateChanged?()
        }
    }
    
    var connectedState: ConnectedState = .pending {
        didSet {
            connectedStateChanged?()
        }
    }
    
    var stateChanged: (() -> Void)?
    var connectedStateChanged: (() -> Void)?
    
    init(uuid: UUID, outgoing: Bool = false, name: String, room: String, isAudio: Bool, callAvatar: URL) {
        self.uuid       = uuid
        self.outgoing   = outgoing
        self.name       = name
        self.room       = room
        self.isAudio    = isAudio
        self.callAvatar = callAvatar
    }
    
    func start(completion: ((_ success: Bool) -> Void)?) {
        completion?(true)
        
        DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now() + 3) {
            self.state = .connecting
            self.connectedState = .pending
            
            DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now() + 1.5) {
                self.state = .active
                self.connectedState = .complete
            }
        }
    }
    
    func answer() {
        state = .active
    }
    
    func end() {
        state = .ended
    }
    
}

