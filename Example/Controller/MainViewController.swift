//
//  MainViewController.swift
//  Example
//
//  Created by QiscusiOS on 13/02/18.
//  Copyright © 2018 qiscus. All rights reserved.
//

import UIKit
import Qiscus
import QiscusRTC
import SwiftyJSON

class MainViewController: UIViewController {

    @IBAction func btnSimpleCall(_ sender: Any) {
    }
    @IBOutlet weak var btnChatIntegration: UIButton!
    
    var id: Int = 0
    var username :String = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        QiscusCommentClient.sharedInstance.roomDelegate = self
        //initcall
        QiscusRTC.setup(appId: "sample-application-C2", appSecret: "KpPiqKGpoN", signalUrl: URL(string: "wss://rtc.qiscus.com/signal")!)
        btnChatIntegration.addTarget(self, action: #selector(MainViewController.showUser), for: .touchUpInside)
    }
    
    @IBAction func goSimpleCall(_ sender: Any) {
        self.navigationController?.pushViewController(ViewController(), animated: true)
    }
    
    
    @objc func showUser(){
        print("show Menu")
        let actionSheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let user1 = UIAlertAction(title: "User1", style: .default) { action -> Void in
            self.id = 1
            self.initUser(id: "sdksample",userEmail: "user1_sample_call@example.com",userKey: "123",userName: "User 1 Sample Call",avatar: "")
        }
        actionSheetController.addAction(user1)
        
        let user2 = UIAlertAction(title: "User2", style: .default) { action -> Void in
            self.id = 2
            self.initUser(id: "sdksample",userEmail: "user2_sample_call@example.com",userKey: "123",userName: "User 2 Sample Call",avatar: "")
        }
        actionSheetController.addAction(user2)
        
        let cancelActionButton = UIAlertAction(title: "Logout", style: .cancel) { action -> Void in
            if(Qiscus.isLoggedIn){
                Qiscus.clear()
                QiscusRTC.logout()
            }
        }
        actionSheetController.addAction(cancelActionButton)
        
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    func initUser(id: String, userEmail: String,userKey: String, userName: String, avatar: String){
            //login sdk
            Qiscus.setup( withAppId: id,
                      userEmail: userEmail,
                      userKey: userKey,
                      username: userName,
                      avatarURL: avatar,
                      delegate: self
            )
            //login rtc
             QiscusRTC.register(username: userEmail, displayName: userEmail)
            self.username = userName
    }
}
extension MainViewController : QiscusConfigDelegate{
    func qiscusConnected() {
        if id == 1 {
            let email = "user2_sample_call@example.com"
            let view = Qiscus.chatView(withUsers: [email])
            view.delegate = self
            self.navigationController?.pushViewController(view, animated: true)
        }else if id == 2{
            let email = "user1_sample_call@example.com"
            let view = Qiscus.chatView(withUsers: [email])
            view.delegate = self
            self.navigationController?.pushViewController(view, animated: true)
        }
     
    }
    
    func qiscusFailToConnect(_ withMessage: String) {
        print(withMessage)
    }
}

extension MainViewController : QiscusChatVCDelegate{
    func chatVC(enableForwardAction viewController: QiscusChatVC) -> Bool {
        return true
    }
    
    func chatVC(enableInfoAction viewController: QiscusChatVC) -> Bool {
        return false
    }
    
    func chatVC(overrideBackAction viewController: QiscusChatVC) -> Bool {
        return true
    }
    
    public func chatVC(titleAction viewController: QiscusChatVC, room: QRoom?, data: Any?) {
        
    }
    public func chatVC(viewController: QiscusChatVC, willAppear animated: Bool) {
        let btnVoice = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        let icVoice = UIImage(named: "ic_voice_call_small", in: MainViewController.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        btnVoice.setBackgroundImage(icVoice, for: .normal)
        btnVoice.tintColor = UIColor.darkGray
        btnVoice.addTarget(self, action: #selector(self.onVoiceCallDidTap), for: .touchUpInside)
        let btnVoiceCall = UIBarButtonItem(customView: btnVoice)
        viewController.navigationItem.rightBarButtonItems = [btnVoiceCall]
    }
}


extension MainViewController : QiscusRoomDelegate {
    @objc func startCall(user : String, room : String, video : Bool) {
        // Start Call
        QiscusRTC.startCall(withRoomId: room, isVideo: video, WithtargetUsername: user) { (target, error) in
            if error == nil {
                self.present(target, animated: true, completion: nil)
            }
        }
    }
    
    func incomingCall(roomName : String, video : Bool, username: String, displayName: String, displayAvatar : String){
        QiscusRTC.incomingCall(withRoomId: roomName, isVideo: video, targetUsername: username, targetDisplayName: username, targetDisplayAvatar: displayAvatar) { (target, error) in
            if error == nil {
                self.present(target, animated: true, completion: nil)
            }
        }
    }
    
    func gotNewComment(_ comments: QComment) {
        if comments.senderName == "System" && !comments.data.isEmpty{
            let dataJson = JSON(parseJSON: comments.data)
            print("json data \(dataJson)")
            let type = dataJson["payload"]["type"].stringValue
            print("type comment \(type)")
         
            if type == "call"{
                let callEvent = dataJson["payload"]["call_event"].stringValue
                let username = dataJson["payload"]["call_caller"]["username"].stringValue
                let displayName = dataJson["payload"]["call_caller"]["name"].stringValue
                let avatarUrl = dataJson["payload"]["call_caller"]["avatar"].stringValue
                let roomname = dataJson["payload"]["call_room_id"].stringValue
                let video = dataJson["payload"]["call_is_video"].boolValue
                if  callEvent == "incoming" {
                    incomingCall(roomName: roomname,video: video,username: username,displayName: displayName,displayAvatar: avatarUrl)
                }
            }
        }
    }
    
    func didFinishLoadRoom(onRoom room: QRoom) {
        
    }
    
    func didFailLoadRoom(withError error: String) {
        
    }
    
    func didFinishUpdateRoom(onRoom room: QRoom) {
        
    }
    
    func didFailUpdateRoom(withError error: String) {
        
    }
    
    
    @objc func onVoiceCallDidTap() {
      
        callIncoming()
    }
    
    func callIncoming(){
//        QiscusRTC.startCall(withRoomId: "QWERTY123", WithtargetUsername: self.username) { (target, error) in
//            if error != nil {
//                self.present(target, animated: true, completion: nil)
//                return
//            }
//            self.present(target, animated: true, completion: nil)
//        }
    }
    
    class var bundle:Bundle{
        get{
            let podBundle   = Bundle(for: self)
            
            if let bundleURL = podBundle.url(forResource: "QChat", withExtension: "bundle") {
                return Bundle(url: bundleURL)!
            }else{
                return podBundle
            }
        }
    }
    
}
