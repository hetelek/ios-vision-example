//
//  ViewController.swift
//  Test
//
//  Created by Hetelekides, Stergios on 6/9/17.
//  Copyright © 2017 Hetelekides, Stergios. All rights reserved.
//

import UIKit
import AVFoundation
import Vision
import CoreGraphics

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    // MARK: - Properties
    // MARK: Video capture
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "videoOutputQueue")
    private var videoDevice: AVCaptureDevice?
    private var videoInput: AVCaptureDeviceInput?
    private lazy var videoOutput: AVCaptureVideoDataOutput = {
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
        return videoOutput
    }()
    
    // MARK: Model
    private let modelNames = [
        "Resnet",
        "Inceptionv3"
    ]
    private let models = [
        Resnet50().model,
        Inceptionv3().model
    ]
    public var model: MLModel? {
        get {
            return visionView.model
        }
        set {
            visionView.model = newValue
        }
    }
    
    // MARK: IBOutlets
    @IBOutlet weak var visionView: VisionView!
    
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        model = models.first
        attemptToStartCamera()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "NetworkSelectingSegue",
            let destinationController = segue.destination as? NetworkSelectingViewController {
            destinationController.cameraViewController = self
            
            // set list info
            destinationController.currentSelectedModel = model
            destinationController.models = models
            destinationController.modelNames = modelNames
        }
    }
    
    
    // MARK: - Camera Logic
    func attemptToStartCamera() {
        guard self.session.isRunning == false else {
            print("session already running")
            return
        }
        
        // get input device
        guard let videoDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: .video, position: AVCaptureDevice.Position.back),
            let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
                showAlertController(title: "No Camera", message: "Capturing video on this device is not supported.")
                return
        }
        
        self.videoInput = videoInput
        self.videoDevice = videoDevice
        
        // add input and output to session
        guard session.canAddInput(videoInput), session.canAddOutput(videoOutput) else {
            showAlertController(title: "Camera Error", message: "Could not add both input and output device.")
            return
        }
        session.addInput(videoInput)
        session.addOutput(self.videoOutput)
        
        AVCaptureDevice.requestAccess(for: .video) { granted in
            guard granted else {
                self.showAlertController(title: "Camera Access", message: "You must allow camera access.")
                return
            }
            
            self.session.startRunning()
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("no pixels")
            return
        }
        
        // set image and update orientation
        try? visionView.updateImage(pixelBuffer: pixelBuffer)
        updateConnectionOrientation()
    }
    
    private func updateConnectionOrientation() {
        let DEVICE_TO_VIDEO_ORIENTATION_MAPPING: [UIDeviceOrientation: AVCaptureVideoOrientation] = [
            .portrait: .portrait,
            .portraitUpsideDown: .portraitUpsideDown,
            .landscapeLeft: .landscapeRight,
            .landscapeRight: .landscapeLeft
        ]
        
        // update video orientation
        if let videoOrientation = DEVICE_TO_VIDEO_ORIENTATION_MAPPING[UIDevice.current.orientation] {
            videoOutput.connections.first?.videoOrientation = videoOrientation
        }
    }
}
