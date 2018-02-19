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

public enum CallType {
    case incoming
    case outgoing
}

public class QiscusRTC: NSObject {
    public static let shared = QiscusRTC()
    internal var manager : CallManager   = CallManager()
    
    class var bundle:Bundle{
        get{
            let podBundle   = Bundle(for: QiscusRTC.self)
            
            if let bundleURL = podBundle.url(forResource: "QiscusRTC", withExtension: "bundle") {
                return Bundle(url: bundleURL)!
            }else{
                return podBundle
            }
        }
    }
    
    // initiate
    public class func setup(appId: String, appSecret : String, signalUrl: URL, delegate: QiscusCallDelegate? = nil) {
        let config              = CallConfig(signalUrl: signalUrl, appID: appId, secretKey: appSecret)
        shared.manager.config   = config
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
    
    public class func register(username: String!, displayName: String!, avatarUrl: String = "http://") {
        shared.manager.client   = QiscusCallClient(username: username, displayName: displayName, avatarUrl: avatarUrl)
    }
    
    public class func startCall(withRoomId id: String = "", isVideo : Bool, WithtargetUsername username: String, targetDisplayName: String = "Person", targetDisplayAvatar: String = "http://", completionHandler: @escaping (UIViewController, NSError?) -> Void) {
        shared.manager.isReceiving = false
        if id.isEmpty {
            // Generate call room with target
            let roomID = shared.manager.createRoomID(length: 5)
            shared.manager.call(withRoomId: roomID, callType: .outgoing, isVideo: isVideo, targetUsername: username, targetDisplayName: targetDisplayName, targetDisplayAvatar: targetDisplayAvatar) { (target , error) in
                completionHandler(target, error)
            }
        }else {
            shared.manager.call(withRoomId: id, callType: .outgoing, isVideo: isVideo, targetUsername: username, targetDisplayName: targetDisplayName, targetDisplayAvatar: targetDisplayAvatar) { (target , error) in
                completionHandler(target, error)
            }
        }
    }
    
    public class func incomingCall(withRoomId id: String, isVideo: Bool, targetUsername: String, targetDisplayName: String = "Person", targetDisplayAvatar: String = "http://", completionHandler: @escaping (UIViewController, NSError?) -> Void) {
        shared.manager.isReceiving = true
        shared.manager.call(withRoomId: id, callType: .incoming, isVideo: isVideo, targetUsername: targetUsername, targetDisplayName: targetDisplayName, targetDisplayAvatar: targetDisplayAvatar) { (target , error) in
            completionHandler(target, error)
        }
    }
}
