//
//  CallUser.swift
//  Pods
//
//  Created by Qiscus on 11/2/17.
//
//

import UIKit

public class CallUser {
    public var username    : String = ""
    public var avatarUrl   : String = ""
    public var displayName : String = ""
}

class CallSession {
    var callee  : CallUser?     = nil
    var calleer : CallUser?     = nil
    var roomId  : String    = ""
    var type    : CallType  = .incoming
    var duration    : Int   = 0 // in second
    
}
