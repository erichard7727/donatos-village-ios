//
//  UIImage+Scaling.swift
//  VillageCoreUI
//
//  Created by Justin Munger on 5/26/16.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    func scaleImage(_ scale: CGFloat) -> UIImage {
        let newImageSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        UIGraphicsBeginImageContext(newImageSize)
        draw(in: CGRect(x: 0.0, y: 0.0, width: newImageSize.width, height: newImageSize.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
    
    func resizeImage(imageSize: CGSize, image: UIImage) -> NSData {
        UIGraphicsBeginImageContext(imageSize)
        image.draw(in: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        let resizedImage = newImage!.pngData()
        UIGraphicsEndImageContext()
        return resizedImage! as NSData
    }
}
