//
//  ApiCall.swift
//  Garuda
//
//  Created by Qiscus on 10/27/17.
//  Copyright © 2017 qiscus. All rights reserved.
//

import Foundation
import Alamofire

public enum ApiResponse {
    case succeed(value: Any?)
    case failed(value: String)
    case revoked()
    case onProgress(progress: Double)
}

public enum RequestResult<T>{
    case done(T)
    case failed(message: String)
}

class ApiCall {
    static func initCall(userEmail: String, userType: String, callRoomId: String, isVideo: Bool, callEvent: String, completion: @escaping (ApiResponse)->()) {
        let params = ["user_email": userEmail,
                      "user_type": userType,
                      "call_room_id": callRoomId,
                      "is_video": "\(isVideo)",
                      "call_event": callEvent] as [String : Any]
        Alamofire.request("", method: .post, parameters: params, headers: nil).responseJSON { (response) in
            
        }
    }
}

