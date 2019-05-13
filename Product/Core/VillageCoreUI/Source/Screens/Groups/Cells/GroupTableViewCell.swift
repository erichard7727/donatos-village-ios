//
//  GroupTableViewCell.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 5/13/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit

class GroupTableViewCell: UITableViewCell {
    
    @IBOutlet var nameLabel: UILabel! {
        didSet {
            _accessibilityElements = nil
        }
    }
    
    @IBOutlet var membersLabel: UILabel! {
        didSet {
            _accessibilityElements = nil
        }
    }
    
    @IBOutlet private var loadingIndicator: UIActivityIndicatorView!
    
    func setLoading(_ isLoading: Bool) {
        let oldValue = loadingIndicator.isAnimating
        if isLoading {
            loadingIndicator.startAnimating()
            selectionStyle = .none
            accessoryType = .none
        } else {
            loadingIndicator.stopAnimating()
            selectionStyle = .gray
            accessoryType = .disclosureIndicator
        }
        if oldValue != isLoading {
            _accessibilityElements = nil
            UIAccessibility.post(notification: .layoutChanged, argument: self.contentView)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        nameLabel.text = nil
        membersLabel.text = nil
        loadingIndicator.stopAnimating()
        selectionStyle = .gray
        _accessibilityElements = nil
    }
    
    override var accessibilityElements: [Any]? {
        get {
            if _accessibilityElements == nil {
                let element = UIAccessibilityElement(accessibilityContainer: self)
                element.accessibilityFrameInContainerSpace = self.bounds
                
                if loadingIndicator.isAnimating {
                    element.accessibilityLabel = "Loading Group"
                    element.accessibilityTraits = [.staticText]
                } else {
                    element.accessibilityLabel = [nameLabel.text, membersLabel.text]
                        .compactMap({ $0 })
                        .joined(separator: ", ")
                    element.accessibilityTraits = [.button]
                    if isSelected {
                        element.accessibilityTraits.formUnion([.selected])
                    }
                    element.accessibilityHint = "Double tap to subscribe"
                }
                
                _accessibilityElements = [element]
            }
            return _accessibilityElements!
        }
        set { }
    }
    private var _accessibilityElements: [Any]?
    
}
