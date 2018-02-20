//
//  ChatManager.swift
//  Example
//
//  Created by QiscusiOS on 13/02/18.
//  Copyright © 2018 qiscus. All rights reserved.
//

import Foundation
import UIKit
// Qiscus wrapper
class CalltManager : NSObject{
    private static let instance = ChatManager()
    
    public static var shared:ChatManager {
        get {
            return instance
        }
    }
    
    
}
