//
//  UIBarButtonItem+Badging.swift
//  Donatos
//
//  Created by Rob Feldmann on 7/20/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//
//  Extensions for Rounded UILabel and UIButton, Badged UIBarButtonItem.
//
//  Usage:
//      let label = UILabel(badgeText: "Rounded Label");
//      let button = UIButton(type: .System); button.rounded = true
//      let barButton = UIBarButtonItem(badge: "42", title: "Answer To Life", target: self, action: "answer")
//      let barButton = UIBarButtonItem(badge: "1", image: UIImage(named: "Cart")!, target: self, action: "cart")
//

import UIKit

extension UILabel {
    convenience init(badgeText: String, color: UIColor = #colorLiteral(red: 0.5450980392, green: 0.6039215686, blue: 0.1058823529, alpha: 1), fontSize: CGFloat = UIFont.smallSystemFontSize) {
        self.init()
        text = "\(badgeText)"
        textAlignment = .left
        textColor = UIColor.white
        backgroundColor = color
        
        font = UIFont.systemFont(ofSize: fontSize)
        layer.cornerRadius = fontSize * CGFloat(0.6)
        clipsToBounds = true
        
        translatesAutoresizingMaskIntoConstraints = false
        addConstraint(NSLayoutConstraint(item: self, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: self, attribute: .height, multiplier: 1, constant: 0))
    }
}

extension UIButton {
    /// show background as rounded rect, like mail addressees
    var rounded: Bool {
        get { return layer.cornerRadius > 0 }
        set { roundWithTitleSize(newValue ? titleSize : 0) }
    }
    
    /// removes other title attributes
    var titleSize: CGFloat {
        get {
            let titleFont = attributedTitle(for: .normal)?.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
            return titleFont?.pointSize ?? UIFont.buttonFontSize
        }
        set {
            // TODO: use current attributedTitleForState(.Normal) if defined
            if UIFont.buttonFontSize == newValue || 0 == newValue {
                setTitle(currentTitle, for: .normal)
            }
            else {
                let attrTitle = NSAttributedString(string: currentTitle ?? "", attributes:
                    [NSAttributedString.Key.font: UIFont.systemFont(ofSize: newValue), NSAttributedString.Key.foregroundColor: currentTitleColor]
                )
                setAttributedTitle(attrTitle, for: .normal)
            }
            
            if rounded {
                roundWithTitleSize(newValue)
            }
        }
    }
    
    func roundWithTitleSize(_ size: CGFloat) {
        let padding = size / 4
        layer.cornerRadius = padding + size * 1.2 / 2
        let sidePadding = padding * 1.5
        contentEdgeInsets = UIEdgeInsets(top: padding, left: sidePadding, bottom: padding, right: sidePadding)
        
        if size.isZero {
            backgroundColor = UIColor.clear
            setTitleColor(tintColor, for: .normal)
        }
        else {
            backgroundColor = tintColor
            let currentTitleColor = titleColor(for: .normal)
            if currentTitleColor == nil || currentTitleColor == tintColor {
                setTitleColor(UIColor.white, for: .normal)
            }
        }
    }
    
//    override open func tintColorDidChange() {
//        super.tintColorDidChange()
//        if rounded {
//            backgroundColor = tintColor
//        }
//    }
}

extension UIBarButtonItem {
    convenience init(badge: String?, button: UIButton, target: AnyObject?, action: Selector) {
        button.addTarget(target, action: action, for: .touchUpInside)
        button.sizeToFit()
        
        let badgeLabel = UILabel(badgeText: badge ?? "")
        button.addSubview(badgeLabel)
        button.addConstraint(NSLayoutConstraint(item: badgeLabel, attribute: .top, relatedBy: .equal, toItem: button, attribute: .top, multiplier: 1, constant: -5))
        button.addConstraint(NSLayoutConstraint(item: badgeLabel, attribute: .trailing, relatedBy: .equal, toItem: button, attribute: .trailing, multiplier: 1, constant: 5))
        if nil == badge {
            badgeLabel.isHidden = true
        }
        badgeLabel.tag = UIBarButtonItem.badgeTag
        
        self.init(customView: button)
    }
    
    convenience init(badge: String?, image: UIImage, target: AnyObject?, action: Selector) {
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        button.setBackgroundImage(image, for: .normal)
        
        self.init(badge: badge, button: button, target: target, action: action)
    }
    
    convenience init(badge: String?, title: String, target: AnyObject?, action: Selector) {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: UIFont.buttonFontSize)
        
        self.init(badge: badge, button: button, target: target, action: action)
    }
    
    var badgeLabel: UILabel? {
        return customView?.viewWithTag(UIBarButtonItem.badgeTag) as? UILabel
    }
    
    var badgedButton: UIButton? {
        return customView as? UIButton
    }
    
    var badgeString: String? {
        get { return badgeLabel?.text?.trimmingCharacters(in: CharacterSet.whitespaces) }
        set {
            badgeLabel?.text = " \(newValue ?? "") "
            badgeLabel?.sizeToFit()
            badgeLabel?.isHidden = (newValue == nil)
            badgedButton?.setNeedsLayout()
            badgedButton?.layoutIfNeeded()
        }
    }
    
    var badgedTitle: String? {
        get { return badgedButton?.title(for: .normal) }
        set { badgedButton?.setTitle(newValue, for: .normal); badgedButton?.sizeToFit() }
    }
    
    fileprivate static let badgeTag = 7373
}
