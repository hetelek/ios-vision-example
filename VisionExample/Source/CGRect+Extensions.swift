//
//  CGRect+Extensions.swift
//  Test
//
//  Created by Hetelekides, Stergios on 6/12/17.
//  Copyright © 2017 Hetelekides, Stergios. All rights reserved.
//

import UIKit

extension CGRect {
    func scaledTo(size: CGSize) -> CGRect {
        let x = self.origin.x * size.width
        let y = (1 - self.origin.y - self.size.height) * size.height
        let width = self.size.width * size.width
        let height = self.size.height * size.height
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
