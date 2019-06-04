//
//  TintedSearchBar.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 5/2/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit

/// Tint's various components of a UISearchBar based on its `barTintColor`
/// value. The components that are modified include:
///   - text color
///   - placeholder text color
///   - search icon
///   - clear icon

@IBDesignable
public final class TintedSearchBar: UISearchBar {
    
    private lazy var textFieldInsideSearchBar: UITextField? = {
        return self.value(forKey: "searchField") as? UITextField
    }()
    
    private lazy var textFieldInsideSearchBarLabel: UILabel? = {
        return textFieldInsideSearchBar?.value(forKey: "placeholderLabel") as? UILabel
    }()
    
    override public var barTintColor: UIColor? {
        didSet {
            configureViews()
        }
    }
    
    override public var tintColor: UIColor! {
        didSet {
            configureViews()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        configureViews()
    }
    
    private func configureViews() {
        configureTextField()
        configurePlaceholder()
        configureSearchIcon()
        configureClearImage()
        configureCancelButton()
    }
    
    /// TextField color customization
    private func configureTextField() {
        textFieldInsideSearchBar?.textColor = tintColor
    }
    
    /// Placeholder color customization
    private func configurePlaceholder() {
        textFieldInsideSearchBarLabel?.textColor = tintColor.withAlphaComponent(0.75)
    }
    
    /// Search icon color customization
    private func configureSearchIcon() {
        let glassIconView = textFieldInsideSearchBar?.leftView as? UIImageView
        glassIconView?.image = glassIconView?.image?.withRenderingMode(.alwaysTemplate)
        glassIconView?.tintColor = tintColor
    }
    
    /// Clear button color customization
    private func configureClearImage() {
        guard let clearButton = textFieldInsideSearchBar?.value(forKey: "clearButton") as? UIButton else {
            return
        }
        
        if #available(iOS 11.0, *) {
            // On iOS 11 the clear button’s rendering mode cannot be changed programatically
            clearButton.setImage(UIImage.named("tinted-searchBar-clear"), for: .normal)
            clearButton.tintColor = tintColor
        } else {
            clearButton.setImage(clearButton.imageView?.image?.withRenderingMode(.alwaysTemplate), for: .normal)
            clearButton.tintColor = tintColor
        }
    }
    
    private func configureCancelButton() {
        UIBarButtonItem
            .appearance(whenContainedInInstancesOf: [TintedSearchBar.self])
            .setTitleTextAttributes([
                .foregroundColor : tintColor!
            ], for: .normal)
    }
}
