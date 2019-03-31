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
    func adjustImageRotation() -> UIImage {
        
        var transform: CGAffineTransform = CGAffineTransform.identity
        
        switch imageOrientation {
        case .up:
            break
        case .left:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat(Double.pi / 2))
            break
        case .right:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: CGFloat(-(Double.pi / 2)))
            break
        case .down:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat(Double.pi))
            break
        case .upMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            break
        case .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat(Double.pi / 2))
            transform = transform.translatedBy(x: size.height, y: 0);
            transform = transform.scaledBy(x: -1, y: 1)
            break
        case .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: CGFloat(-(Double.pi / 2)))
            transform = transform.translatedBy(x: size.height, y: 0);
            transform = transform.scaledBy(x: -1, y: 1)
            break
        case .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat(Double.pi))
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            break
        }
        
        if let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: self.cgImage!.bitsPerComponent, bytesPerRow: 0, space: self.cgImage!.colorSpace!, bitmapInfo: self.cgImage!.bitmapInfo.rawValue) {
            context.concatenate(transform)
            
            switch imageOrientation {
            case .left, .leftMirrored, .right, .rightMirrored:
                context.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
            default:
                context.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            }
            
            return UIImage(cgImage: context.makeImage()!)
        } else {
            return self
        }
    }
}
