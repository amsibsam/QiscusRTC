//
//  CallUI.swift
//  Garuda
//
//  Created by Qiscus on 02/02/18.
//  Copyright © 2018 qiscus. All rights reserved.
//

import UIKit
import AlamofireImage

class VideoCallUI: UIViewController {
    
    @IBOutlet weak var localVideoView: UIView!
    @IBOutlet weak var remoteVideoView: UIView!
    @IBOutlet weak var bgCall: UIImageView!
    
    
    @IBOutlet weak var buttonCamera: UIButton!
    @IBOutlet weak var buttonMuted: UIButton!
    @IBOutlet weak var buttonMessage: UIButton!
    @IBOutlet weak var buttonEndcall: UIButton!
    @IBOutlet weak var labelDuration : UILabel!
    @IBOutlet weak var labelName : UILabel!
    
    var presenter : CallUIPresenter  = CallUIPresenter()
    var seconds = 0
    var timer = Timer()
    var panGesture       = UIPanGestureRecognizer()
    
    public init() {
        super.init(nibName: "VideoCallUI", bundle: QiscusRTC.bundle)
    }
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.labelName.text = presenter.getCallName()
        self.labelDuration.text = "00.00"
        self.presenter.attachView(view: self)
        self.setupUI()
        self.runTimer()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let duration = self.presenter.getDuration() {
            self.setupCallTime(currentDuration: duration)
            self.seconds    = duration
        }
    }
    func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(updateTimer)), userInfo: nil, repeats: true)
    }
    @objc func updateTimer() {
        seconds += 1
        self.labelDuration.text = timeString(time: TimeInterval(seconds))
    }
    func timeString(time:TimeInterval) -> String {
        //let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String.init(format:"%02i:%02i", minutes, seconds)
    }
    
    func setupUI() {
        let borderWidth : CGFloat   = 2
        let borderColor             = UIColor.init(red:222/255.0, green:225/255.0, blue:227/255.0, alpha: 1.0).cgColor
        // set Border
        buttonMuted.layer.borderWidth     = borderWidth
        buttonMuted.layer.borderColor     = borderColor
        buttonMessage.layer.borderWidth   = borderWidth
        buttonMessage.layer.borderColor   = borderColor
        buttonCamera.layer.borderWidth   = borderWidth
        buttonCamera.layer.borderColor   = borderColor
        
        buttonEndcall.layer.cornerRadius    = buttonEndcall.frame.height/2
        buttonEndcall.clipsToBounds         = true
        buttonMuted.layer.cornerRadius      = buttonMuted.frame.height/2
        buttonMuted.clipsToBounds           = true
        buttonMessage.layer.cornerRadius    = buttonMessage.frame.height/2
        buttonMessage.clipsToBounds         = true
        buttonCamera.layer.cornerRadius    = buttonCamera.frame.height/2
        buttonCamera.clipsToBounds         = true
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(VideoCallUI.draggedView(_:)))
        localVideoView.isUserInteractionEnabled = true
        localVideoView.addGestureRecognizer(panGesture)
    }
    
    @objc func draggedView(_ sender: UIPanGestureRecognizer) {
        self.view.bringSubview(toFront: localVideoView)
        let translation = sender.translation(in: self.view)
        localVideoView.center = CGPoint(x: localVideoView.center.x + translation.x, y: localVideoView.center.y + translation.y)
        sender.setTranslation(CGPoint.zero, in: self.view)
    }
    
    func setupCallTime(currentDuration: Int) {
        self.labelDuration.text = "00.\(currentDuration)"
    }
    
    @IBAction func clickEndCall(_ sender: Any) {
        self.dismiss(animated: true) {
            self.timer.invalidate()
            self.presenter.finishCall()
        }
    }
    
    @IBAction func clickMessage(_ sender: Any) {
        self.dismiss(animated: true) {
            //
        }
    }
    
    @IBAction func clickMute(_ sender: Any) {
        if self.presenter.isAudioMute {
            self.presenter.isAudioMute = false
        }else {
            self.presenter.isAudioMute = true
        }
    }
    
    @IBAction func clickCamera(_ sender: Any) {

    }
    
}

extension VideoCallUI : CallView {
    func Call(update Duration: Int) {
        self.labelDuration.text = "00.\(Duration)"
    }
    
    func CallStatusChange(state: String) {
        //
    }
    
}

