//
//  Image+Named.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 2/9/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit

extension UIImage {
    
    /// Returns an image from the host app's asset catelog if it exists, falling
    /// back to the default value from this bundle's asset catelog if it exists.
    ///
    /// - Parameters:
    ///   - imageName: The name of the image
    ///   - traitCollection: An optional trait collection
    /// - Returns: The image, if it was found
    static func named(_ imageName: String, compatibleWith traitCollection: UITraitCollection? = nil) -> UIImage? {
        if let image = UIImage(named: imageName, in: Bundle.main, compatibleWith: traitCollection) {
            return image
        } else if let image = UIImage(named: imageName, in: Constants.bundle, compatibleWith: traitCollection) {
            return image
        } else {
            return nil
        }
    }
    
}

extension UIImageView {
    
    /// Set's an image from the host app's asset catelog if it exists, falling
    /// back to the default value from this bundle's asset catelog if it exists.
    ///
    /// - Parameters:
    ///   - imageName: The name of the image
    ///   - traitCollection: An optional trait collection
    func setImage(named imageName: String, compatibleWith traitCollection: UITraitCollection? = nil) {
        if let image = UIImage(named: imageName, in: Bundle.main, compatibleWith: traitCollection) {
            self.image = image
        } else if let image = UIImage(named: imageName, in: Constants.bundle, compatibleWith: traitCollection) {
            self.image = image
        } else {
            return
        }
    }
    
}
