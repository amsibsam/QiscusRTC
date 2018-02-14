//
//  CallCaptureController.swift
//  QiscusRTC
//
//  Created by Qiscus on 14/02/18.
//

import AVFoundation
import WebRTC

class CallCaptureController {
    var capturer : RTCCameraVideoCapturer!
    var frontCamera: Bool = true
    
    init(WithCapturer capture: RTCCameraVideoCapturer) {
        capturer = capture
    }
    
    func stopCapture() {
        capturer.stopCapture()
    }
    
    func startCapture() {
        let position = frontCamera ? AVCaptureDevice.Position.front : AVCaptureDevice.Position.back
        let device : AVCaptureDevice = self.findDevice(position: position)
        let format : AVCaptureDevice.Format = selectFormat(device: device)
        let fps = selectFps(format: format)
        capturer.startCapture(with: device, format: format, fps: fps)
    }
    
    func switchCamera() {
        frontCamera = false
        self.startCapture()
    }
    
    private func findDevice(position: AVCaptureDevice.Position) -> AVCaptureDevice {
        let captureDevices = RTCCameraVideoCapturer.captureDevices()
        for device in captureDevices {
            if device.position  == position {
                return device
            }
        }
        return captureDevices[0]
    }
    
    private func selectFormat(device: AVCaptureDevice) -> AVCaptureDevice.Format {
        let formats = RTCCameraVideoCapturer.supportedFormats(for: device)
        let targetWidth : Int = 640
        let targetHeight : Int = 480
        var selectFormat : AVCaptureDevice.Format? = nil
        var currentDiff = INT_MAX // 2147483647
        for format in formats {
            let dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            let diff : Int = abs(targetWidth - Int(dimension.width)) + abs(targetHeight - Int(dimension.height))
            // diff = 784 (dimention 192 heigh 144)
            // diff = 480 (dimention 352 heigh 288)
            if diff < currentDiff {
                selectFormat = format
                currentDiff = Int32(diff)
            }
        }
        
        return selectFormat!
    }
    
    func selectFps(format : AVCaptureDevice.Format) -> Int {
        var maxFramerate : Float64  = 0
        for fpsRange in format.videoSupportedFrameRateRanges {
            maxFramerate = fmax(maxFramerate, fpsRange.maxFrameRate)
        }
        
        return Int(maxFramerate)
    }
}
