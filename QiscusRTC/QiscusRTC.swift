//
//  CallKit.swift
//  Pods
//
//  Created by asharijuang on 11/1/17.
//

import Foundation
import WebRTC

public protocol QiscusCallDelegate {
    func callConnected()
}

public struct QiscusCallConfig {
    public var appId       : String                = ""
    public var appSecret   : String                = ""
    public var delegate    : QiscusCallDelegate?   = nil
}

public enum CallType {
    case incoming
    case outgoing
}

public class QiscusRTC: NSObject {
    public static let shared = QiscusRTC()
    private var manager : CallManager   = CallManager()
    
    // initiate
    public class func setup(appId: String, appSecret : String, delegate: QiscusCallDelegate? = nil) {
        let callconfig          = QiscusCallConfig(appId: appId, appSecret: appSecret, delegate: delegate)
        shared.manager.config   = callconfig
    }
    
    public class func isRegister() -> Bool {
        return shared.manager.isRegister()
    }
    
    public class func logout() {
        shared.manager.clearClient()
    }
    
    public class func whoami() -> CallUser? {
        return shared.manager.whoami()
    }
    
    public class func register(username: String, displayName: String, avatarUrl: String = "http://") {
        shared.manager.client   = QiscusCallClient(username: username, displayName: displayName, avatarUrl: avatarUrl)
    }
    
    public class func call(withRoomId id: String, callType : CallType, targetUsername: String, targetDisplayName: String = "Person", targetDisplayAvatar: String = "http://") {
        
    }
    
    public class func startCall(withRoomId id: String = "", withTargetUserName: String, targetDisplayName: String = "Person", targetDisplayAvatar: String = "http://") {
        if id.isEmpty {
            // Generate call room with target
        }else {
            
        }
    }
    
    public class func incomingCall(withRoomId: String, targetUserName: String, targetDisplayName: String = "Person", targetDisplayAvatar: String = "http://") {
        
    }
}
