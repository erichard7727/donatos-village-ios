//
//  UIAlertController+Utilities.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 3/14/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit

public extension UIAlertController {

    /// Creates a simple dismissable alert view controller (modal style).
    ///
    /// - Parameters:
    ///   - title: the title of the alert.
    ///   - message: the message text of the alert.
    ///   - dismissText: the dismiss button text. "Dismiss" by default.
    /// - Returns: a fully configured `UIAlertController`.
    static func dismissable(title: String, message: String, dismissText: String = "Dismiss") -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: dismissText, style: .default, handler: nil))
        return alert
    }
    
}
