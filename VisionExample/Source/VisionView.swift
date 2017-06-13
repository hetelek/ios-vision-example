//
//  VisionView.swift
//  Test
//
//  Created by Hetelekides, Stergios on 6/12/17.
//  Copyright © 2017 Hetelekides, Stergios. All rights reserved.
//

import UIKit
import Vision
import CoreML

class VisionView: UIView {
    // MARK: - Properties
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    private lazy var modelLabel: UILabel = {
        let modelLabel = UILabel()
        modelLabel.translatesAutoresizingMaskIntoConstraints = false
        return modelLabel
    }()
    public var model: MLModel?
    
    
    // MARK: - Initialization
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        // add image view
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.leftAnchor.constraint(equalTo: leftAnchor),
            imageView.rightAnchor.constraint(equalTo: rightAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // add label above image view
        addSubview(modelLabel)
        NSLayoutConstraint.activate([
            modelLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 5),
            modelLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5)
        ])
    }
    
    
    // MARK: Image processing
    private func getImageBasedRequests(cvPixelBuffer: CVPixelBuffer) -> [VNImageBasedRequest] {
        var requests: [VNImageBasedRequest] = []
        
        // create face request (completion handler draws rectangles where faces are)
        let faceRequest = VNDetectFaceRectanglesRequest { (request, error) in
            guard let faceObservations = request.results as? [VNFaceObservation] else {
                print("invalid results")
                return
            }
            
            // create context and draw original image
            let originalImage = UIImage(ciImage: CIImage(cvPixelBuffer: cvPixelBuffer))
            UIGraphicsBeginImageContext(originalImage.size)
            guard let context = UIGraphicsGetCurrentContext() else {
                print("failed to get context")
                return
            }
            originalImage.draw(at: CGPoint.zero)
            
            // draw rect at face
            for faceObservation in faceObservations {
                let new = faceObservation.boundingBox.scaledTo(size: originalImage.size)
                context.addRect(new)
            }
            
            // stroke rects
            UIColor.red.setStroke()
            context.strokePath()
            
            // create final image and update UI
            if let finalCgImage = context.makeImage() {
                let finalImage = UIImage(cgImage: finalCgImage)
                DispatchQueue.main.async {
                    self.imageView.image = finalImage
                }
            }
            
            UIGraphicsEndImageContext()
        }
        requests.append(faceRequest)
        
        // get core ML model from property
        if let model = model,
            let visionModel = try? VNCoreMLModel(for: model) {
            
            // create vision request and update label when complete
            let visionRequest = VNCoreMLRequest(model: visionModel) { (request, error) in
                if let result = request.results?.first as? VNClassificationObservation {
                    DispatchQueue.main.async {
                        self.modelLabel.text = result.identifier
                    }
                }
            }
            visionRequest.imageCropAndScaleOption = VNImageCropAndScaleOptionCenterCrop
            
            requests.append(visionRequest)
        }
        
        return requests
    }
    
    public func updateImage(pixelBuffer: CVPixelBuffer) throws {
        // make request
        let imageRequest = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try imageRequest.perform(getImageBasedRequests(cvPixelBuffer: pixelBuffer))
    }
}
