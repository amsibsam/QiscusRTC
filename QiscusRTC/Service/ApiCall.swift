//
//  ApiCall.swift
//  Garuda
//
//  Created by Qiscus on 10/27/17.
//  Copyright © 2017 qiscus. All rights reserved.
//

import Foundation
import Alamofire
class ApiCall {
    static func initCall(userEmail: String, userType: String, callRoomId: String, isVideo: Bool, callEvent: String, completion: @escaping (ApiResponse)->()) {
        let params = ["user_email": userEmail,
                      "user_type": userType,
                      "call_room_id": callRoomId,
                      "is_video": "\(isVideo)",
                      "call_event": callEvent] as [String : Any]
        Alamofire.request("\(Helper.BASE_URL)\(ApiCallEndpoint.call)", method: .post, parameters: params, headers: nil).responseJSON { (response) in
            
        }
    }
}
