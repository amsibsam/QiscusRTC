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
    var presenter = CallUIPresenter()
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

//        let background = UIImage(named: "bg_call", in: QiscusRTC.bundle, compatibleWith: nil)
//        self.remoteVideoView.backgroundColor = UIColor(patternImage: background!)
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
    
    func scaleVideo(videoSize: CGSize, targetFrameSize: CGSize)->CGRect{
        let widthRatio  = targetFrameSize.width  / videoSize.width
        let heightRatio = targetFrameSize.height / videoSize.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newRect: CGRect
        if(widthRatio < heightRatio) {
            let scaledWidth = videoSize.width * heightRatio
            let scaledHeight = videoSize.height * heightRatio
            let y = (targetFrameSize.height - scaledHeight) / 2
            newRect = CGRect(x: 0, y: y, width: scaledWidth, height:scaledHeight)
        } else {
            let scaledWitdh = videoSize.width * widthRatio
            let scaledHeight = videoSize.height * widthRatio
            let x = (targetFrameSize.width - scaledWitdh) / 2
            newRect = CGRect(x: x, y: 0, width: scaledWitdh,  height: scaledHeight)
        }
        
        return newRect
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
        
        if let localvideo = presenter.getLocalVideo() {
            DispatchQueue.main.async {
                self.localVideoView.isHidden    = true
                localvideo.frame.size           = self.remoteVideoView.frame.size
                localvideo.contentMode          = .scaleAspectFill
                localvideo.transform = CGAffineTransform(scaleX: -1, y: 1)
                self.remoteVideoView.insertSubview(localvideo, at: 0)
                self.remoteVideoView.clipsToBounds = true
            }
        }
        
        if let remoteVideo = presenter.getRemoteVideo() {
            self.remoteVideoView.insertSubview(remoteVideo, at: 0)
            self.remoteVideoView.clipsToBounds = true
        }
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
            self.buttonMuted.backgroundColor = UIColor.clear
        }else {
            self.presenter.isAudioMute = true
            self.buttonMuted.backgroundColor = UIColor.lightGray
        }
    }
    
    @IBAction func clickCamera(_ sender: Any) {
        if isFront {
            self.presenter.switchCameraBack()
            self.buttonCamera.backgroundColor = UIColor.lightGray
        }else {
            self.presenter.switchCameraFront()
            self.buttonCamera.backgroundColor = UIColor.clear
        }
        isFront = !isFront
        
    }
    
}

extension VideoCallUI : CallView {
    func callVideoSizeChanged(videoView: UIView, size: CGSize, local: UIView?, remote: UIView?) {
        if(videoView.tag == 1){
            let targetSize = remoteVideoView.frame.size
            
            let rect = scaleVideo(videoSize: size, targetFrameSize: targetSize)
            if local != nil {
                local?.frame = rect
            }
            
        }else{
            let targetSize = remoteVideoView.frame.size
            let rect = scaleVideo(videoSize: size, targetFrameSize: targetSize)
            remote?.frame = rect
        }
    }
    
    func callReceive(Local video: UIView) {
        self.localVideoView.insertSubview(video, at: 0)
        self.localVideoView.clipsToBounds = true
        video.transform = CGAffineTransform(scaleX: -1, y: 1)
    }
    
    func callReceive(Remote video: UIView, local: UIView) {
        video.frame.size    = self.remoteVideoView.frame.size
        video.contentMode   = .scaleToFill
        self.remoteVideoView.insertSubview(video, at: 0)
        self.remoteVideoView.clipsToBounds = true
        
        // setup small video
        if let smallVideo = self.presenter.getLocalVideo() {
            self.localVideoView.isHidden    = false
            smallVideo.frame.size   = self.localVideoView.frame.size
            smallVideo.contentMode  = .scaleToFill
            self.localVideoView.insertSubview(smallVideo, at: 0)
            self.localVideoView.clipsToBounds   = true
        }
        
//        DispatchQueue.main.async {
//            self.remoteVideoView.insertSubview(video, at: 0)
//        
//            let rect = self.scaleVideo(videoSize: local.frame.size, targetFrameSize: self.localVideoView.frame.size)
//            local.frame = rect
//        
//            self.localVideoView.insertSubview(local, at: 0)
//        }
        
        self.runTimer()
    }
    
    func Call(update Duration: Int) {
        self.labelDuration.text = "00.\(Duration)"
    }
    
    func CallStatusChange(state: CallState) {
        switch state {
        case .conected:
            // Video Call default speakerloud
            self.presenter.isLoadSpeaker = true
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

