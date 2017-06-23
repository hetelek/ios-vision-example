//
//  NetworkSelectingViewController.swift
//  VisionExample
//
//  Created by Hetelekides, Stergios on 6/22/17.
//  Copyright © 2017 Hetelekides, Stergios. All rights reserved.
//

import UIKit
import CoreML

class NetworkSelectingViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    // MARK: - Properties
    // MARK: Models
    public var modelNames: [String]?
    public var models: [MLModel]?
    public var currentSelectedModel: MLModel?
    
    // MARK: Other
    public var cameraViewController: ViewController?
    
    // MARK: IBOutlets
    @IBOutlet weak var pickerView: UIPickerView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let currentSelectedModel = currentSelectedModel,
            let index = models?.index(of: currentSelectedModel) {
            pickerView.selectRow(index, inComponent: 0, animated: false)
        }
    }
    
    // MARK: - UIPickerView delegate/data source
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return models?.count ?? 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return modelNames?[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        cameraViewController?.model = models?[row]
    }
}
