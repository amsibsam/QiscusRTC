//
//  ViewController.swift
//  Example
//
//  Created by asharijuang on 11/1/17.
//  Copyright © 2017 qiscus. All rights reserved.
//

import UIKit
import QiscusRTC

class ViewController: UIViewController {

    @IBOutlet weak var labelUsername: UILabel!
    @IBOutlet weak var buttonLogin: UIButton!
    @IBOutlet weak var fieldUsername: UITextField!
    @IBOutlet weak var fieldRoomID: UITextField!
    @IBOutlet weak var buttonStartCall: UIButton!
    @IBOutlet weak var buttonIncomingCall: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.buttonStartCall.addTarget(self, action: #selector(self.startCall), for: .touchUpInside)
        self.buttonIncomingCall.addTarget(self, action: #selector(self.incomingCall), for: .touchUpInside)
        QiscusRTC.setup(appId: "sample-application-C2", appSecret: "KpPiqKGpoN", signalUrl: URL(string: "wss://rtc.qiscus.com/signal")!)
        QiscusRTC.register(username: "juang", displayName: "juang")
        setupAuth()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func setupAuth() {
        if QiscusRTC.isRegister() {
            buttonLogin.setTitle("Logout", for: UIControlState.normal)
            buttonLogin.addTarget(self, action: #selector(self.logout), for: UIControlEvents.touchUpInside)
            self.buttonStartCall.isEnabled = true
            self.buttonIncomingCall.isEnabled   = true
        }else {
            buttonLogin.setTitle("Login", for: UIControlState.normal)
            buttonLogin.addTarget(self, action: #selector(self.login), for: UIControlEvents.touchUpInside)
            self.buttonStartCall.isEnabled = false
            self.buttonIncomingCall.isEnabled   = false
        }
        
        let user = QiscusRTC.whoami()
        if user != nil {
            self.labelUsername.text = "Hi, \(String(describing: user!.displayName))"
        }else {
            self.labelUsername.text = "Please Login if you can."
        }
    }
    
    @objc func login() {
        let alertController = UIAlertController(title: "Who are you?", message: "", preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Login", style: .default, handler: {
            alert -> Void in
            
            let user = alertController.textFields![0] as UITextField
            let displayName = alertController.textFields![1] as UITextField
            if !(user.text?.isEmpty)! && !(displayName.text?.isEmpty)! {
                QiscusRTC.register(username: user.text!, displayName: displayName.text!)
                self.setupAuth()
            }
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: {
            (action : UIAlertAction!) -> Void in
            
        })
        
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Enter First Name"
        }
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Enter Second Name"
        }
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func logout() {
        QiscusRTC.logout()
        setupAuth()
    }
    
    @objc func startCall() {
        let username = fieldUsername.text
        let roomName = fieldRoomID.text
        
        QiscusRTC.startCall(withRoomId: roomName!, WithtargetUsername: username!) { (target, error) in
            if error != nil {
                self.present(target, animated: true, completion: nil)
                return
            }
            self.present(target, animated: true, completion: nil)
        }
        
    }
    
    @objc func incomingCall() {
        let username = fieldUsername.text
        let roomName = fieldRoomID.text
            QiscusRTC.incomingCall(withRoomId: roomName!, targetUsername: username!) { (target, error) in
                if error != nil {
                    self.present(target, animated: true, completion: nil)
                    return
                }
                self.present(target, animated: true, completion: nil)
            }
    }
    
}

