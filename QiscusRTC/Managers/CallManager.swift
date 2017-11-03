//
//  CallManager.swift
//  Pods
//
//  Created by Qiscus on 11/2/17.
//
//

import UIKit

class CallManager: NSObject {
    var config : QiscusCallConfig?  = nil
    private var callSession : CallSession?
    var client : QiscusCallClient?  = nil
    
    func setSession(session: CallSession) {
        self.callSession = session
    }
    
    func isRegister() -> Bool {
        return self.client != nil ? true : false
    }
    
    func whoami() -> CallUser? {
        return client
    }
    
    func clearClient() {
        client = nil
    }
    
    func createRoomID(length:Int) -> String {
        
        let randomString:NSMutableString = NSMutableString(capacity: length)
        
        let letters:NSMutableString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        var i: Int = 0
        
        while i < length {
            
            let randomIndex:Int = Int(arc4random_uniform(UInt32(letters.length)))
            randomString.append("\(Character( UnicodeScalar( letters.character(at: randomIndex))!))")
            i += 1
        }
        
        return String(randomString)
    }
    
    func call(withRoomId id: String, callType : CallType, targetUsername: String, targetDisplayName: String = "Person", targetDisplayAvatar: String = "http://", completionHandler: @escaping (UIViewController, NSError?) -> Void) {
        let target = CallingScreenVC()
        var data    = CallData()
        data.callRoomId     = id
        data.targetEmail    = targetUsername
        data.targetName     = targetDisplayName
        data.targetAvatar   = targetDisplayAvatar
        data.myEmailQiscus  = "juang@qiscus.co"
        
        target.callData     = data
        
        completionHandler(target, nil)
    }
}
