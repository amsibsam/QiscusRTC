//
//  CallUI.swift
//  Garuda
//
//  Created by Qiscus on 02/02/18.
//  Copyright © 2018 qiscus. All rights reserved.
//

import UIKit
import AlamofireImage

class CallUI: UIViewController {

    @IBOutlet weak var imageAvatar: UIImageView!
    @IBOutlet weak var imageBgAvatar: UIImageView!
    @IBOutlet weak var buttonSpeaker: UIButton!
    @IBOutlet weak var buttonMuted: UIButton!
    @IBOutlet weak var buttonMessage: UIButton!
    @IBOutlet weak var buttonEndcall: UIButton!
    @IBOutlet weak var labelDuration : UILabel!
    @IBOutlet weak var labelName : UILabel!
    @IBOutlet weak var labelInfo : UILabel!
    var presenter : CallUIPresenter  = CallUIPresenter()
    var seconds = 0
    var timer = Timer()
    
    public init() {
        super.init(nibName: "CallUI", bundle: QiscusRTC.bundle)
    }
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.labelInfo.text = "\(presenter.appName) Audio Call"
        self.labelName.text = presenter.getCallName()
        let placeholder = UIImage(named: "avatar")
        self.imageAvatar.af_setImage(withURL: presenter.getCallAvatar(), placeholderImage: placeholder)
        self.imageBgAvatar.af_setImage(withURL: presenter.getCallAvatar(), placeholderImage: placeholder)
        self.labelDuration.text = "00.00"
        self.presenter.attachView(view: self)
        self.setupUI()
        if presenter.isReceiving {
            self.runTimer()
        }
        if let localvideo = presenter.getLocalVideo() {
             self.view.insertSubview(localvideo, at: 0)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("call active \(presenter.isCallActive)")
        if !presenter.isCallActive {
            self.dismiss(animated: true, completion: nil)
        }
        
        if let duration = self.presenter.getDuration() {
            self.setupCallTime(currentDuration: duration)
            self.seconds    = duration
        }
    }
    
    override func viewWillLayoutSubviews() {
        imageAvatar.layer.cornerRadius      = imageAvatar.frame.size.height/2
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
        buttonSpeaker.layer.borderWidth   = borderWidth
        buttonSpeaker.layer.borderColor   = borderColor
        // set Circle
        imageAvatar.layer.cornerRadius      = imageAvatar.frame.size.height/2
        imageAvatar.clipsToBounds           = true
        buttonEndcall.layer.cornerRadius    = buttonEndcall.frame.height/2
        buttonEndcall.clipsToBounds         = true
        buttonMuted.layer.cornerRadius      = buttonMuted.frame.height/2
        buttonMuted.clipsToBounds           = true
        buttonMessage.layer.cornerRadius    = buttonMessage.frame.height/2
        buttonMessage.clipsToBounds         = true
        buttonSpeaker.layer.cornerRadius    = buttonSpeaker.frame.height/2
        buttonSpeaker.clipsToBounds         = true
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.regular)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.alpha = 0.8
        blurEffectView.frame = self.imageBgAvatar.frame
        
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight] // for supporting device rotation
        self.imageBgAvatar.addSubview(blurEffectView)
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
    
    @IBAction func clickSpeaker(_ sender: Any) {
        if self.presenter.isLoadSpeaker {
            self.presenter.isLoadSpeaker = false
        }else {
            self.presenter.isLoadSpeaker = true
        }
    }
    
}

extension CallUI : CallView {
    func callReceive(Local video: UIView) {

    }
    
    func callReceive(Remote video: UIView) {
        self.view.insertSubview(video, at: 0)
    }
    
    func Call(update Duration: Int) {
        self.labelDuration.text = "00.\(Duration)"
    }
    
    func CallStatusChange(state: CallState) {
        if state == .conected {
            self.runTimer()
        } else {
            self.labelDuration.text = state.rawValue
        }
    }
    
    func CallFinished() {
        self.dismiss(animated: true, completion: nil)
        self.navigationController?.popViewController(animated: true)
    }
    
}
