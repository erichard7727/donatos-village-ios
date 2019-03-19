//
//  UIColor+Named.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 3/14/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit

extension UIColor {
    static let vlgGray = UIColor.named("vlgGray")!
    static let vlgGreen = UIColor.named("vlgGreen")!
    static let vlgLightGray = UIColor.named("vlgGray")!
    static let vlgMediumGray = UIColor.named("vlgMediumGray")!
    static let vlgOrange = UIColor.named("vlgOrange")!
    
}

extension UIColor {
    
    /// Returns a color from the host app's asset catelog if it exists, falling
    /// back to the default value from this bundle's asset catelog if it exists.
    ///
    /// - Parameters:
    ///   - colorName: The name of the color
    ///   - traitCollection: An optional trait collection
    /// - Returns: The color, if it was found
    static func named(_ colorName: String, compatibleWith traitCollection: UITraitCollection? = nil) -> UIColor? {
        if let color = UIColor(named: colorName, in: Bundle.main, compatibleWith: traitCollection) {
            return color
        } else if let color = UIColor(named: colorName, in: Constants.bundle, compatibleWith: traitCollection) {
            return color
        } else {
            return nil
        }
    }
    
}
