//
//  CaptureViewController.swift
//  Selfiegram
//
//  Created by Yu-Chun Hsu on 2020/8/15.
//  Copyright © 2020 Yu-Chun Hsu. All rights reserved.
//

import UIKit
import AVKit

class CaptureViewController: UIViewController {
    typealias CompletionHandler = (UIImage?) -> Void
    
    @IBOutlet weak var cameraPreview: PreviewView!
    
    var completion: CompletionHandler?
    let captureSession = AVCaptureSession()
    let photoOutput = AVCapturePhotoOutput()
    var currentVideoOrientation : AVCaptureVideoOrientation {
        let orientationMap : [UIDeviceOrientation:AVCaptureVideoOrientation]
        
        orientationMap = [
            .portrait: .portrait,
            .landscapeLeft: .landscapeRight,
            .landscapeRight: .landscapeLeft,
            .portraitUpsideDown: .portraitUpsideDown
        ]
        
        let currentOrientatation = UIDevice.current.orientation
        
        let videoOrientation = orientationMap[currentOrientatation, default: .portrait]
        
        return videoOrientation
    }
    
    override func viewDidLoad() {
        let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.front)
        
        guard let captureDevice = discovery.devices.first else {
            NSLog("No capture devices available.")
            self.completion?(nil)
            return
        }
        
        do
        {
            try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
        }
        catch let error
        {
            NSLog("Failed to add camera to capture session: \(error)")
        }
        
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        captureSession.startRunning()
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        self.cameraPreview.setSession(captureSession)
        
        super.viewDidLoad()
        
    }
   
    override func viewWillLayoutSubviews()
    {
        self.cameraPreview.setCameraOrientation(currentVideoOrientation)
    }

    
    
    
    @IBAction func close(_ sender: Any) {
        self.completion?(nil)
    }
    @IBAction func takeSelfie(_ sender: Any) {
        guard let videoConnection = photoOutput.connection(with: AVMediaType.video) else {
            NSLog("Failed to get camera connection")
            return
        }
        
        videoConnection.videoOrientation = currentVideoOrientation
        
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CaptureViewController: AVCapturePhotoCaptureDelegate
{
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?)
    {
        if let error = error {
            NSLog("Failed to get the photo \(error)")
            return
        }
        
        guard let jpegData = photo.fileDataRepresentation(), let image = UIImage(data: jpegData) else {
            NSLog("Failed to get image from encoded data")
            return
        }
        
        self.completion?(image)
    }
}

class PreviewView: UIView {
    
    var previewLayer : AVCaptureVideoPreviewLayer?

    
    
    func setSession(_ session: AVCaptureSession)
    {
        guard self.previewLayer == nil else {
            NSLog("Warning: \(self.description) attempted to set its"
                + " preview layer more than once. This is not allowed.")
            return
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        self.layer.addSublayer(previewLayer)
        
        self.previewLayer = previewLayer
        
        self.setNeedsLayout()
    }

    override func layoutSubviews()
    {
        previewLayer?.frame = self.bounds
        
    }
    
    func setCameraOrientation(_ orientation: AVCaptureVideoOrientation)
    {
        previewLayer?.connection?.videoOrientation = orientation
    }
    
    
}
