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
    public class func setup(appId: String, appSecret : String, appName: String, appIcon: UIImage? = nil, host: URL? = nil, delegate: QiscusCallDelegate? = nil) {
        var url = URL(string: "wss://rtc.qiscus.com/signal")
        if let signal = host {
            url = signal
        }
        
        let config = CallConfig(signalUrl: url!, appID: appId, secretKey: appSecret, appName: appName)
        if let icon = appIcon {
            config.appIcon = icon
        }
        
        shared.manager.setup(withConfig: config)
    }
    
    public class func isRegister() -> Bool {
        return shared.manager.isRegister()
    }
    
    public class func isCallActive() -> Bool {
        return shared.manager.isCallActive()
    }
    
    public class func getCallUI() -> UIViewController? {
        return shared.manager.continueCallScreen()
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
    
    public class func startCall(roomId id: String = "", isVideo : Bool, calleeUsername: String, calleeDisplayName: String = "Person", calleeDisplayAvatar: URL = URL(string: "http://")!, completionHandler: @escaping (UIViewController, NSError?) -> Void) {
        shared.manager.isReceiving = false
        if id.isEmpty {
            // Generate call room with target
            let roomID = shared.manager.createRoomID(length: 5)
            shared.manager.call(withRoomId: roomID, callType: .outgoing, isVideo: isVideo, targetUsername: calleeUsername, targetDisplayName: calleeDisplayName, targetDisplayAvatar: calleeDisplayAvatar) { (target , error) in
                completionHandler(target, error)
            }
        }else {
            shared.manager.call(withRoomId: id, callType: .outgoing, isVideo: isVideo, targetUsername: calleeUsername, targetDisplayName: calleeDisplayName, targetDisplayAvatar: calleeDisplayAvatar) { (target , error) in
                completionHandler(target, error)
            }
        }
    }
    
    public class func incomingCall(roomId id: String, isVideo: Bool, calleerUsername: String, calleerDisplayName: String = "Person", calleerDisplayAvatar: URL = URL(string: "http://")!, completionHandler: @escaping (UIViewController, NSError?) -> Void) {
        shared.manager.isReceiving = true
        shared.manager.call(withRoomId: id, callType: .incoming, isVideo: isVideo, targetUsername: calleerUsername, targetDisplayName: calleerDisplayName, targetDisplayAvatar: calleerDisplayAvatar) { (target , error) in
            completionHandler(target, error)
        }
    }
}
