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

    @IBOutlet weak var buttonCamera: UIButton!
    @IBOutlet weak var buttonMuted: UIButton!
    @IBOutlet weak var buttonMessage: UIButton!
    @IBOutlet weak var buttonEndcall: UIButton!
    @IBOutlet weak var labelDuration : UILabel!
    @IBOutlet weak var labelName : UILabel!
    var isFront : Bool = true
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
        
        if let localvideo = presenter.getLocalVideo() {
            DispatchQueue.main.async {
                localvideo.frame.size   = self.localVideoView.frame.size
                localvideo.contentMode  = .scaleAspectFill
                self.localVideoView.insertSubview(localvideo, at: 0)
                self.localVideoView.clipsToBounds   = true
            }
        }
        
        if let remoteVideo = presenter.getRemoteVideo() {
            self.remoteVideoView.insertSubview(remoteVideo, at: 0)
        }
        let background = UIImage(named: "bg_call", in: QiscusRTC.bundle, compatibleWith: nil)
        self.remoteVideoView.backgroundColor = UIColor(patternImage: background!)
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
        let translation = sender.translation(in: self.view)
        var positionX = localVideoView.center.x + translation.x
        var positionY = localVideoView.center.y + translation.y
        
        if (positionX + (localVideoView.frame.width/2)) > UIScreen.main.bounds.width {
            positionX = UIScreen.main.bounds.width - (localVideoView.frame.width/2)
        } else if (positionX - (localVideoView.frame.width/2)) < 0 {
            positionX =  localVideoView.frame.width/2
        }
        
        if (positionY + (localVideoView.frame.height/2)) > UIScreen.main.bounds.height {
            positionY = UIScreen.main.bounds.height - (localVideoView.frame.height/2)
        } else if (positionY - (localVideoView.frame.height/2)) < 0 {
            positionY = localVideoView.frame.height/2
        }
        
        localVideoView.center = CGPoint(x: positionX, y: positionY)
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
        if isFront {
            self.presenter.switchCameraBack()
        }else {
            self.presenter.switchCameraFront()
        }
        isFront = false
    }
    
}

extension VideoCallUI : CallView {
    func callReceive(Local video: UIView) {
        self.localVideoView.insertSubview(video, at: 0)
        self.localVideoView.clipsToBounds   = true
    }
    
    func callReceive(Remote video: UIView) {
        self.remoteVideoView.insertSubview(video, at: 0)
        self.remoteVideoView.clipsToBounds = true
    }
    
    func Call(update Duration: Int) {
        self.labelDuration.text = "00.\(Duration)"
    }
    
    func CallStatusChange(state: CallState) {
        switch state {
        case .conected:
            self.runTimer()
            break
        default:
            self.labelDuration.text = state.rawValue
            break
        }
        
    }
    
    func CallFinished() {
        self.timer.invalidate()
        self.labelDuration.text = "Hangup"
        let deadlineTime = DispatchTime.now() + .seconds(3)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: {
            self.dismiss(animated: true, completion: nil)
            self.navigationController?.popViewController(animated: true)
        })
        
    }
}

