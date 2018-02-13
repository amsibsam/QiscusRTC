//
//  CallSignal.swift
//  Garuda
//
//  Everything about call signal via Web Socket
//
//  Created by Qiscus on 23/01/18.
//  Copyright © 2018 qiscus. All rights reserved.
//

import Foundation
import Starscream
import SwiftyJSON

enum CallSignalResposne : String {
    case roomCreate = "room_create"
    case roomJoin   = "room_join"
    case register   = "register"
}

enum CallSignalEvent : String {
    case userNew        = "user_new"
    case userLeave      = "user_leave"
    case roomPrivate    = "room_data_private"
}

enum CallSignalEventRoom : String {
    case callSync       = "call_sync"
    case callAck        = "call_ack"
    case callAccept     = "call_accept"
    case callReject     = "call_reject"
    case callCancel     = "call_cancel"
}

enum CallSignalEventDataType : String {
    case offer      = "offer"
    case answer     = "answer"
    case candidate  = "candidate"
}

protocol CallSignalDelegate {
    func signalConnect()
    func signalDisconnect(error: Error?)
    func signalReceiveEvent(value: CallSignalEventRoom)
    func signalReceiveEventData(TypeOffer value: String, SDP: String)
    func signalReceiveEventData(TypeAnswer value: String, SDP: String)
    func signalReceiveCandidate(dataMid: String, dataIndex: Int, dataCandidate: String)
}

// MARK: Call Signal Flow
/*
 Caller : call initiator, if you start call or outgoing
 Callee : call receiver, if got incoming call you are cellee
 */

class CallSignal {
    var APP_ID      : String    = ""
    var APP_SECRET  : String    = ""
    var USERNAME    : String    = ""
    var isIncoming  : Bool      = false
    var token       : String    = ""
    var roomID      : String    = ""
    var targetUser  : String    = ""
    //signaling
    var socket      : WebSocket?
    var delegate    : CallSignalDelegate
    
    init(delegate del: CallSignalDelegate) {
        self.delegate = del
    }
    
    // MARK: STEP 1 Callee or Caller
    func setup(url: URL, appID : String, secret: String, username : String) {
        self.APP_ID         = appID
        self.APP_SECRET     = secret
        self.USERNAME       = username
        self.socket = WebSocket(url: url)
        self.socket?.connect()
        self.socket?.delegate   = self
    }
    
    // Action
    func sendCandidat(dataMid: String, dataIndex: Int, dataSdp: String) {
        if let message = self.payloadCanadidate(id: self.roomID, target: self.targetUser, dataMid: dataMid, dataIndex: dataIndex, dataSdp: dataSdp) {
            print("send candidate \(message)")
            self.socket?.write(string: message)
        }else {
            // MARK: Error parsing payload
        }
    }
    
    func sendConnect() {
        if let message = self.payloadConnect(id: self.roomID) {
            print("connect \(message)")
            self.socket?.write(string: message)
        }else {
            // MARK: Error parsing payload
        }
    }
    
    func sendNotify(state: String, value: String) {
        if let message = self.payloadRoomNotify(id: self.roomID, state: state, value: value) {
            print("answer \(message)")
            self.socket?.write(string: message)
        }else {
            // MARK: Error parsing payload
        }
    }
    
    func sendOffer(sdp: String) {
        if let message = self.payloadSendOffer(id: self.roomID, target: self.targetUser, sdp: sdp) {
            print("offer \(message)")
            self.socket?.write(string: message)
        }else {
            // MARK: Error parsing payload
        }
    }
    
    func sendAnswer(sdp: String) {
        if let message = self.payloadSendAnswer(id: self.roomID, target: self.targetUser, sdp: sdp) {
            print("answer \(message)")
            self.socket?.write(string: message)
        }else {
            // MARK: Error parsing payload
        }
    }
    
    // Triger when call Accept
    func accept() {
        // MARK: Send Call Accept
        if let message = self.payloadCallAccept(id: self.roomID, target: self.targetUser){
            print("accept and room\(message)")
            self.socket?.write(string: message)
        }else {
            // MARK: Error parsing payload
        }
    }
    
    func leave() {
        if let message = self.payloadLeave(id: self.roomID) {
            self.socket?.write(string: message)
            self.socket?.disconnect()
        }else {
            // MARK: Error parsing payload
        }
    }
    
    // Helper
    fileprivate func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: AnyObject]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    fileprivate func escapeString(string: String) -> String {
        let newString = string.replacingOccurrences(of: "\r", with: "\\r", options: NSString.CompareOptions.literal, range: nil)
        return newString.replacingOccurrences(of: "\n", with: "\\n", options: NSString.CompareOptions.literal, range: nil)
    }
    
    private func toJSON(data: String) -> JSON {
        return JSON.init(parseJSON: data)
    }

    // MARK: WSS Response handler
    internal func responseRegister(data: String) {
        let json = self.toJSON(data: data)
        let success = json["success"].bool ?? false
        // save token
        self.token  = json["token"].string ?? ""
        if success {
            if self.isIncoming {
                // MARK: STEP 3 Callee
                if let message = self.payloadJoinRoom(id: self.roomID) {
                    self.socket?.write(string: message)
                }else {
                    // MARK: Error parsing payload
                }
            }else {
                // MARK: STEP 3 Caller
                // Send Room Join
                if let message = self.payloadCreateRoom(id: self.roomID) {
                    self.socket?.write(string: message)
                }else {
                    // MARK: Error parsing payload
                }
            }
        }else {
            // MARK: Todo handle register error
        }
    }
    
    // MARK: STEP 4 Callee
    internal func responseJoin(data: String) {
        let json = self.toJSON(data: data)
        let success = json["success"].bool ?? false
        if success {
            
        }else {
            // MARK: Todo handle register error
        }
    }
    // MARK: WSS Event handler
    internal func eventNewUser(data: String) {
        let json = self.toJSON(data: data)
        let sender = json["sender"].string ?? ""
        if sender == self.targetUser {
            if let message = self.payloadCallSync(id: self.roomID, target: self.targetUser){
                print("[RTC-HUB] \(message)")
                self.socket?.write(string: message)
            }else {
                // MARK: Error parsing payload
            }
        }
    }
    
    internal func eventCallRoomPrivate(data: String) {
        let json = self.toJSON(data: data)
        
        // Handle event type, exm: call_sync, call_ack, accept, etc
        if let event = json["event"].string {
            if event == CallSignalEventRoom.callSync.rawValue {
                // MARK: STEP 5 Callee
                // Send Call ACK
                if let message = self.payloadCallACK(id: self.roomID, target: self.targetUser){
                    print("[RTC-HUB] \(message)")
                    self.socket?.write(string: message)
                }else {
                    // MARK: Error parsing payload
                }
                self.delegate.signalReceiveEvent(value: .callSync)
            }else if event == CallSignalEventRoom.callAccept.rawValue {
                // MARK: Todo Tell RTC to create offer
                self.delegate.signalReceiveEvent(value: .callAccept)
            }else if event == CallSignalEventRoom.callAck.rawValue {
                // MARK: Todo Tell RTC to create offer
                self.delegate.signalReceiveEvent(value: .callAck)
            }else if event == CallSignalEventRoom.callCancel.rawValue {
                // MARK: Todo Tell RTC to create offer
                self.delegate.signalReceiveEvent(value: .callCancel)
            }else if event == CallSignalEventRoom.callReject.rawValue {
                // MARK: Todo Tell RTC to create offer
                self.delegate.signalReceiveEvent(value: .callReject)
            }
        }
        
        // Handle data type, exm: Offer, answer
        if let type = json["type"].string {
            let dataSDP     = json["sdp"].string ?? ""
            let dataMid     = json["sdpMid"].string ?? ""
            let dataIndex   = json["sdpMLineIndex"].int ?? 0
            let dataCandidate   = json["candidate"].string ?? ""
            
            if type == CallSignalEventDataType.offer.rawValue {
                // MARK : TODO Tell RTC to set remote description and create peerCon answer
                self.delegate.signalReceiveEventData(TypeOffer: type, SDP: dataSDP)
                // Send Remote Offer
                if let message = self.payloadRoomNotify(id: self.roomID, state: "callee_sdp", value: "REMOTE_OFFER") {
                    print("[RTC-HUB] \(message)")
                    // send room notify
                    self.socket?.write(string: message)
                }else {
                    // MARK: Error parsing payload
                }
            }else if type == CallSignalEventDataType.answer.rawValue {
                // MARK : TODO Tell RTC to set remote description and create peerCon answer
                self.delegate.signalReceiveEventData(TypeAnswer: type, SDP: dataSDP)
                // Send Remote Offer
                if let message = self.payloadRoomNotify(id: self.roomID, state: "caller_sdp", value: "REMOTE_ANSWER") {
                    print("[RTC-HUB] \(message)")
                    self.socket?.write(string: message)
                }else {
                    // MARK: Error parsing payload
                }
            }else if type == CallSignalEventDataType.candidate.rawValue {
                // MARK : TODO Tell RTC add ICeCandidate
                self.delegate.signalReceiveCandidate(dataMid: dataMid, dataIndex: dataIndex, dataCandidate: dataCandidate)
            }else {
                // MARK: Error parsing type, unknow type or new type
            }
        }
    }
    // MARK: WSS event call data
    func offer() {
        
    }
}

extension CallSignal : WebSocketDelegate {
    // MARK: STEP 2 Callee or Caller
    func websocketDidConnect(socket: WebSocketClient) {
        print("[Call Signal] Websocket is connected")
        self.delegate.signalConnect()
        
        // MARK: After connect register with username, appid, and secret
        // 1. Register wss
        if let message = self.payloadLogin() {
            print("login wss \(message)")
            self.socket?.write(string: message)
        }
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("[Call Signal] Websocket is disconnected: \(String(describing: error?.localizedDescription))")
        self.delegate.signalDisconnect(error: error)
    }
    
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        print("[Call Signal] Got some text: \(text)")
        let json = JSON(parseJSON: text)
        // every response wss, always have data as json string
        let data = json["data"].string ?? ""
        //MARK: after write message you got response
        let response = json["response"].string ?? ""
        if response == CallSignalResposne.register.rawValue {
            if !data.isEmpty {
                self.responseRegister(data: data)
            }
        }else if response == CallSignalResposne.roomCreate.rawValue {
            // call waiting
        }else if response == CallSignalResposne.roomJoin.rawValue {
            if !data.isEmpty {
                self.eventCallRoomPrivate(data: data)
            }
        }
        
        //MARK: Someone in the room write message and other got event
        let event = json["event"].string ?? ""
        if event == CallSignalEvent.userNew.rawValue {
            if !data.isEmpty {
                self.eventNewUser(data: data)
            }
        }else if event == CallSignalEvent.userLeave.rawValue {
            self.delegate.signalDisconnect(error: nil)
            self.leave()
        }else if event == CallSignalEvent.roomPrivate.rawValue {
            if !data.isEmpty {
                self.eventCallRoomPrivate(data: data)
            }
        }
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        //
    }
}

extension CallSignal : WebSocketPongDelegate {
    func websocketDidReceivePong(socket: WebSocketClient, data: Data?) {
        //
    }
}
