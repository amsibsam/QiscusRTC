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
}
