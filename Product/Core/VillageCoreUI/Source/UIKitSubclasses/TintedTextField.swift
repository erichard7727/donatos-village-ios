//
//  TintedTextField.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 5/17/18.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit

// MARK: - TintedTextField

/// This is a textField subclass that is able to tint the
/// placeholder text and the clear button image to match the specified
/// UITextField's tintColor.

@IBDesignable
open class TintedTextField: UITextField {

    /// Set the attributes for all placeholder text. Default attributes are
    /// [ NSForegroundColorAttributeName: tintColor ].
    ///
    /// This way you can set placeholder attributes once and then use
    /// self.placeholder instead of setting the placeholder attributes
    /// every single time with self.attributedPlaceholder
    open var placeholderAttributes: [NSAttributedString.Key : AnyObject]? {
        set {
            self.placeholderAttributesPrivate = newValue
        }
        get {
            return placeholderAttributesPrivate ?? [
                NSAttributedString.Key.foregroundColor: tintColor
            ]
        }
    }

    fileprivate var placeholderAttributesPrivate: [NSAttributedString.Key : AnyObject]?

    /// Holds the textField's clear image that is tinted with self.tintColor
    fileprivate var tintedClearImage: UIImage?

    // MARK: - UITextField Overrides

    open override func awakeFromNib() {
        super.awakeFromNib()
        if let text = placeholder {
            attributedPlaceholder = NSAttributedString(string: text, attributes: placeholderAttributes)
        }
    }

    open override var placeholder: String? {
        didSet {
            if let text = placeholder {
                self.attributedPlaceholder = NSAttributedString(string: text, attributes: placeholderAttributes)
            }
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        tintClearImage()
    }

    // MARK: - Private Methods

    fileprivate func tintClearImage() {
        for view in subviews {
            if view is UIButton {
                let button = view as! UIButton
                if let image = button.image(for: .highlighted) {
                    if tintedClearImage == nil {
                        tintedClearImage = tintImage(image, color: tintColor)
                    }
                    button.setImage(tintedClearImage, for: .normal)
                }
            }
        }
    }

    // MARK: - Helper Methods

    fileprivate func tintImage(_ image: UIImage, color: UIColor) -> UIImage {
        let size = image.size

        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        let context = UIGraphicsGetCurrentContext()
        image.draw(at: CGPoint.zero, blendMode: CGBlendMode.normal, alpha: 1.0)

        context!.setFillColor(color.cgColor)
        context!.setBlendMode(CGBlendMode.sourceIn)
        context!.setAlpha(1.0)

        let rect = CGRect(
            x: CGPoint.zero.x,
            y: CGPoint.zero.y,
            width: image.size.width,
            height: image.size.height)
        UIGraphicsGetCurrentContext()!.fill(rect)
        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return tintedImage!
    }
}
