//
//  UIButton+Loading.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 3/1/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit

fileprivate extension UIImage {
    
    class func vlg_image(color: UIColor, size: CGSize = .init(width: 1, height: 1)) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
}

extension UIButton {
    
    private struct AssociatedKeys {
        static var disabledTitle = "vlg_DisabledTitle"
        static var disabledImage = "vlg_DisabledImage"
    }
    
    var vlg_disabledTitle: String? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.disabledTitle) as? String
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.disabledTitle,
                newValue as NSString?,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
    
    var vlg_disabledImage: UIImage? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.disabledImage) as? UIImage
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.disabledImage,
                newValue as UIImage?,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
    
    func vlg_setLoading(_ isLoading: Bool) {
        let tag = 43215
        if isLoading {
            vlg_disabledTitle = self.title(for: .disabled)
            self.setTitle("", for: .disabled)
            
            vlg_disabledImage = self.image(for: .disabled)
            if let image = vlg_disabledImage {
                self.setImage(UIImage.vlg_image(color: .clear, size: image.size), for: .disabled)
            }

            self.isEnabled = false
            self.alpha = 0.5
            
            let indicator = UIActivityIndicatorView()
            let buttonHeight = self.bounds.size.height
            let buttonWidth = self.bounds.size.width
            indicator.center = CGPoint(x: buttonWidth/2, y: buttonHeight/2)
            indicator.tag = tag
            self.addSubview(indicator)
            indicator.startAnimating()
        } else {
            self.setTitle(vlg_disabledTitle, for: .disabled)
            self.setImage(vlg_disabledImage, for: .disabled)
            self.isEnabled = true
            self.alpha = 1.0
            
            if let indicator = self.viewWithTag(tag) as? UIActivityIndicatorView {
                indicator.stopAnimating()
                indicator.removeFromSuperview()
            }
        }
    }
    
}
