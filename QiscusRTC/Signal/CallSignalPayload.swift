//
//  CallSignalPayload.swift
//  Garuda
//
//  Created by Qiscus on 26/01/18.
//  Copyright © 2018 qiscus. All rights reserved.
//

import Foundation

extension CallSignal {
    
    internal func toString(data :[String : Any]) -> String? {
        do {
            let jsonObj = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            let jsonStr = String(data: jsonObj, encoding: String.Encoding.utf8)
            return jsonStr
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    fileprivate func escapeString(string: String) -> String {
        let newString = string.replacingOccurrences(of: "\r", with: "\\r", options: NSString.CompareOptions.literal, range: nil)
        return newString.replacingOccurrences(of: "\n", with: "\\n", options: NSString.CompareOptions.literal, range: nil)
    }
    
    // JSON String Generator, just like params in HTTP
    internal func payloadLeave(id: String) -> String? {
        let jsonDic = [
            "request": "room_leave",
            "room": id
            ] as [String : Any]
        return self.toString(data: jsonDic)
    }
    
    internal func payloadLogin() -> String? {
        let jsonDic = [
            "request": "register",
            "data": "{\"app_id\": \"\(APP_ID)\", \"app_secret\": \"\(APP_SECRET)\", \"username\": \"\(USERNAME)\"}"
            ] as [String : Any]
        return self.toString(data: jsonDic)
    }
    
    internal func payloadCreateRoom(id: String) -> String? {
        let jsonDic = [
            "request": "room_create",
            "room": id,
            "data": "{\"max_participant\": 2, \"token\": \"\(self.token)\"}"
            ] as [String : Any]
        return self.toString(data: jsonDic)
    }
    
    internal func payloadJoinRoom(id: String) -> String? {
        let jsonDic = [
            "request": "room_join",
            "room": id,
            "data": "{\"token\": \"\(self.token)\"}"
            ] as [String : Any]
        return self.toString(data: jsonDic)
    }
    
    internal func payloadConnect(id: String) -> String? {
        let jsonDic = [
            "request": "room_notify",
            "room": id,
            "data": "{\"event\": \"notify_connect\"}"
            ] as [String : Any]
        return self.toString(data: jsonDic)
    }
    
    internal func payloadCallAccept(id: String, target: String) -> String? {
        let jsonDic = [
            "request": "room_data",
            "room": id,
            "recipient": target,
            "data": "{\"event\": \"call_accept\"}"
            ] as [String : Any]
        return self.toString(data: jsonDic)
    }
    
    internal func payloadSendOffer(id: String, target: String, sdp: String) -> String? {
        let jsonDic = [
            "request": "room_data",
            "room": id,
            "recipient": target,
            "data": "{\"type\": \"offer\", \"sdp\": \"\(self.escapeString(string: sdp))\"}"
            ] as [String : Any]
        return self.toString(data: jsonDic)
    }
    
    internal func payloadSendAnswer(id: String, target: String, sdp: String) -> String? {
        let jsonDic = [
            "request": "room_data",
            "room": id,
            "recipient": target,
            "data": "{\"type\": \"answer\", \"sdp\": \"\(self.escapeString(string: sdp))\"}"
            ] as [String : Any]
        return self.toString(data: jsonDic)
    }
    
    internal func payloadCallACK(id: String, target: String) -> String? {
        let jsonDic = [
            "request": "room_data",
            "room": id,
            "recipient": target,
            "data": "{\"event\": \"call_ack\"}"
            ] as [String : Any]
        return self.toString(data: jsonDic)
    }
    
    internal func payloadCallSync(id: String, target: String) -> String? {
        let jsonDic = [
            "request": "room_data",
            "room": id,
            "recipient": target,
            "data": "{\"event\": \"call_sync\"}"
            ] as [String : Any]
        return self.toString(data: jsonDic)
    }
    
    internal func payloadRoomNotify(id: String, state: String, value: String) -> String? {
        let jsonDic = [
            "request": "room_notify",
            "room": id,
            "data": "{\"event\": \"notify_\(state)\" , \"message\": \"\(value)\"}"
            ] as [String : Any]
        return self.toString(data: jsonDic)
    }
    
    internal func payloadCanadidate(id: String, target: String, dataMid: String, dataIndex: Int, dataSdp: String) -> String? {
        let jsonDic = [
            "request": "room_data",
            "room": id,
            "recipient": target,
            "data": "{\"type\": \"candidate\", \"sdpMLineIndex\": \(dataIndex), \"sdpMid\": \"\(dataMid)\", \"candidate\": \"\(dataSdp)\"}"
            ] as [String : Any]
        return self.toString(data: jsonDic)
    }
    
}
