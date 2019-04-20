//
//  UINavigationController+BarStyle.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 4/18/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit

extension UINavigationController {
    
    open override var childForStatusBarStyle : UIViewController? {
        return self.viewControllers.last
    }
    
    /// Allow the status bar style to be dictated by top-most child view controller
    open override var preferredStatusBarStyle : UIStatusBarStyle {
        return self.topViewController?.preferredStatusBarStyle ?? self.preferredStatusBarStyle
    }
    
    override open var prefersStatusBarHidden : Bool {
        // Attempt to proxy down to the top-most view controller.
        if let topController = topViewController {
            return topController.prefersStatusBarHidden
        } else {
            return false
        }
    }
}
