//
//  UIImage+Rotation.swift
//  VillageCoreUI
//
//  Created by Justin Munger on 7/27/16.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation

import UIKit

extension UIImage {
    
    /// Ensures the image is correctly oriented if taken/selected from a
    /// a device, such as the Camera.
    ///
    /// Source: https://stackoverflow.com/a/26579689
    ///
    /// - Returns: The correctly oriented image
    func vlg_orientedUp() -> UIImage {
        guard self.imageOrientation != .up else {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return normalizedImage ?? self;
    }
    
}
