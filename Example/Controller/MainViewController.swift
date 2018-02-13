//
//  MainViewController.swift
//  Example
//
//  Created by QiscusiOS on 13/02/18.
//  Copyright © 2018 qiscus. All rights reserved.
//

import UIKit
import Qiscus

class MainViewController: UIViewController {

    @IBAction func btnSimpleCall(_ sender: Any) {
    }
    @IBOutlet weak var btnChatIntegration: UIButton!
    
    var id: Int = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        btnChatIntegration.addTarget(self, action: #selector(MainViewController.showUser), for: .touchUpInside)
    }
    @objc func showUser(){
        print("show Menu")
        let actionSheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let user1 = UIAlertAction(title: "User1", style: .default) { action -> Void in
                print("user1")
                self.initUser(id: 1)
        }
        actionSheetController.addAction(user1)
        
        let user2 = UIAlertAction(title: "User2", style: .default) { action -> Void in
                print("user2")
                self.initUser(id: 2)
        }
        actionSheetController.addAction(user2)
        
        let cancelActionButton = UIAlertAction(title: "Logout", style: .cancel) { action -> Void in
            if(Qiscus.isLoggedIn){
                Qiscus.clear()
            }
        }
        actionSheetController.addAction(cancelActionButton)
        
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    func initUser(id: Int){
        self.id = id
        if(Qiscus.isLoggedIn==false){
        if id == 1 {
            Qiscus.setup( withAppId: "DragonGo",
                      userEmail: "userdemo1@qiscus.com",
                      userKey: "userdemo1",
                      username: "userdemo1",
                      avatarURL: "",
                      delegate: self
            )
        }else if id == 2 {
            Qiscus.setup( withAppId: "DragonGo",
                          userEmail: "userdemo2@qiscus.com",
                          userKey: "userdemo2",
                          username: "userdemo2",
                          avatarURL: "",
                          delegate: self
                )
            }
        }
    }
}
extension MainViewController : QiscusConfigDelegate{
    func qiscusConnected() {
        if id == 1 {
            let email = "userdemo2@qiscus.com"
            let view = Qiscus.chatView(withUsers: [email])
            view.delegate = self
            self.navigationController?.pushViewController(view, animated: true)
        }else if id == 2{
            let email = "userdemo1@qiscus.com"
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
            print("click \(room)")
    }
    public func chatVC(viewController: QiscusChatVC, willAppear animated: Bool) {
        var roomId = viewController.chatRoomId
        if let room = viewController.chatRoom {
            roomId = room.id
            print("willapp \(roomId)")
        }
        
        let btnVoice = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        let icVoice = UIImage(named: "ic_voice_call_small", in: MainViewController.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        btnVoice.setBackgroundImage(icVoice, for: .normal)
        btnVoice.tintColor = UIColor.darkGray
        btnVoice.addTarget(self, action: #selector(self.onVoiceCallDidTap), for: .touchUpInside)
        let btnVoiceCall = UIBarButtonItem(customView: btnVoice)
        viewController.navigationItem.rightBarButtonItems = [btnVoiceCall]
    }
}


extension MainViewController {
    
    @objc func onVoiceCallDidTap() {
        print("call")
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
