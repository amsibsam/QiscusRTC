//
//  QiscusCallClient.swift
//  Pods
//
//  Created by Qiscus on 11/2/17.
//
//

import UIKit

class QiscusCallClient : CallUser {
  
    init(username: String, displayName: String, avatarUrl: String) {
        super.init()
        self.username    = username
        self.displayName = displayName
        self.avatarUrl   = avatarUrl
    }
}
