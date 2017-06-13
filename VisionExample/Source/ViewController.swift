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

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
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
    
    let modelNames = [
        "Resnet",
        "Inceptionv3"
    ]
    let models = [
        Resnet50().model,
        Inceptionv3().model
    ]
    
    // MARK: IBOutlets
    @IBOutlet weak var visionView: VisionView!
    @IBOutlet weak var pickerView: UIPickerView!
    
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        visionView.model = models.first
        
        // hide picker view when vision view tapped
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hidePickerView))
        visionView.addGestureRecognizer(tapGesture)
        
        attemptToStartCamera()
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
    
    // MARK: - IBActions
    @IBAction func changeNetworkButtonTapped(_ sender: Any) {
        // show / hide picker view
        if pickerView.isHidden {
            showPickerView()
        }
        else {
            hidePickerView()
        }
    }
    
    private func showPickerView() {
        self.pickerView.alpha = 0
        self.pickerView.isHidden = false
        
        UIView.animate(withDuration: 0.2, animations: {
            self.pickerView.alpha = 1
        }) { completed in
            self.pickerView.isHidden = false
        }
    }
    
    @objc private func hidePickerView() {
        UIView.animate(withDuration: 0.2, animations: {
            self.pickerView.alpha = 0
        }) { completed in
            self.pickerView.isHidden = true
        }
    }
    
    
    // MARK: - UIPickerView delegate/data source
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return models.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return modelNames[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        visionView.model = models[row]
    }
}
