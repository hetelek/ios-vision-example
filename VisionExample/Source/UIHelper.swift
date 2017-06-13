//
//  UIHelper.swift
//  Test
//
//  Created by Hetelekides, Stergios on 6/12/17.
//  Copyright © 2017 Hetelekides, Stergios. All rights reserved.
//

import UIKit

extension UIViewController {
    public func showAlertController(title: String, message: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }
}
