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
    @IBOutlet weak var butonVideo: UIButton!
    @IBOutlet weak var buttonEndcall: UIButton!
    @IBOutlet weak var labelDuration : UILabel!
    @IBOutlet weak var labelName : UILabel!
    var isFront : Bool = true
    var isVideoStreamEnable: Bool = true
    var presenter = CallUIPresenter()
    var seconds = 0
    var timer = Timer()
    var panGesture = UIPanGestureRecognizer()
    var isConnected: Bool = false
 
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
        buttonEndcall.layer.cornerRadius    = buttonEndcall.frame.height/2
        buttonEndcall.clipsToBounds         = true
        buttonMuted.layer.cornerRadius      = buttonMuted.frame.height/2
        buttonMuted.clipsToBounds           = true
        butonVideo.layer.cornerRadius    = butonVideo.frame.height/2
        butonVideo.clipsToBounds         = true
        buttonCamera.layer.cornerRadius    = buttonCamera.frame.height/2
        buttonCamera.clipsToBounds         = true
        
        let cameraIcon = UIImage(named: "call_camera", in: QiscusRTC.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        let muteIcon = UIImage(named: "call_mute", in: QiscusRTC.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        let videoIcon = UIImage(named: "ic_video_off", in: QiscusRTC.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        
        buttonCamera.backgroundColor = UIColor.lightGray.withAlphaComponent(0.4)
        buttonCamera.setImage(cameraIcon, for: .normal)
        buttonCamera.tintColor = .white
        buttonMuted.backgroundColor = UIColor.lightGray.withAlphaComponent(0.4)
        buttonMuted.setImage(muteIcon, for: .normal)
        buttonMuted.tintColor = .gray
        buttonMuted.isEnabled = false
        butonVideo.backgroundColor = UIColor.lightGray.withAlphaComponent(0.4)
        butonVideo.setImage(videoIcon, for: .normal)
        butonVideo.tintColor = .gray
        butonVideo.isEnabled = false
        
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
    
    func activateButton() {
        buttonMuted.tintColor = .white
        buttonMuted.isEnabled = true
        butonVideo.tintColor = .white
        butonVideo.isEnabled = true
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
    
    @IBAction func clickVideo(_ sender: Any) {
        if self.isConnected {
            if isVideoStreamEnable {
                self.butonVideo.backgroundColor = UIColor.white.withAlphaComponent(1.0)
                self.butonVideo.tintColor = .black
                self.presenter.videoStream(enable: !isVideoStreamEnable)
                
                if self.localVideoView.subviews.count > 0 {
                    self.localVideoView.subviews[0].removeFromSuperview()
                    self.localVideoView.backgroundColor = UIColor.black
                }
            } else {
                self.presenter.videoStream(enable: !isVideoStreamEnable)
                self.butonVideo.backgroundColor = UIColor.lightGray.withAlphaComponent(0.4)
                self.butonVideo.tintColor = .white
                self.localVideoView.backgroundColor = UIColor.clear
                
                if let localVideo = self.presenter.getLocalVideo() {
                    self.localVideoView.insertSubview(localVideo, at: 0)
                }
            }
            
            isVideoStreamEnable = !isVideoStreamEnable
        }
    }
    
    @IBAction func clickMute(_ sender: Any) {
        if self.isConnected {
            if self.presenter.isAudioMute {
                self.presenter.isAudioMute = false
                self.buttonMuted.backgroundColor = UIColor.lightGray.withAlphaComponent(0.4)
                self.buttonMuted.tintColor = .white
            }else {
                self.presenter.isAudioMute = true
                self.buttonMuted.backgroundColor = UIColor.white.withAlphaComponent(1.0)
                self.buttonMuted.tintColor = .black
            }
        }
    }
    
    @IBAction func clickCamera(_ sender: Any) {
        if isFront {
            self.presenter.switchCameraBack()
            if isConnected {
                let local = self.localVideoView.subviews[0]
                local.transform = CGAffineTransform(scaleX: 1, y: 1)
                let rect = scaleVideo(videoSize: local.frame.size, targetFrameSize: self.localVideoView.frame.size)
                local.frame = rect
            } else {
                self.remoteVideoView.subviews[0].transform = CGAffineTransform(scaleX: 1, y: 1)
            }
        }else {
            self.presenter.switchCameraFront()
            if isConnected {
                let local = self.localVideoView.subviews[0]
                local.transform = CGAffineTransform(scaleX: -1, y: 1)
                let rect = scaleVideo(videoSize: local.frame.size, targetFrameSize: self.localVideoView.frame.size)
                local.frame = rect
            } else {
                self.remoteVideoView.subviews[0].transform = CGAffineTransform(scaleX: -1, y: 1)
            }
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
        
        self.activateButton()
        self.isConnected = true
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

