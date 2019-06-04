//
//  NoticeCell.swift
//  VillageContainerApp
//
//  Created by Justin Munger on 9/1/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit

class NoticeCell: UITableViewCell {
    
    var percentageButtonPressed: (() -> Void)?

    @IBOutlet weak var noticeTitleLabel: UILabel!
    @IBOutlet weak var leftSquareView: UIView!
    @IBOutlet weak var leftSquareImageView: UIImageView!
    @IBOutlet weak var content: UIView!
    @IBOutlet weak var actionLabel: UILabel!
    
    @IBOutlet private var loadingIndicator: UIActivityIndicatorView!
    
    func setLoading(_ isLoading: Bool) {
        let oldValue = loadingIndicator.isAnimating
        if isLoading {
            content.isHidden = true
            loadingIndicator.startAnimating()
        } else {
            content.isHidden = false
            loadingIndicator.stopAnimating()
        }
        if oldValue != isLoading {
            _accessibilityElements = nil
            UIAccessibility.post(notification: .layoutChanged, argument: self.contentView)
        }
    }
    
    var noticeId: String = "-1"
    var noticeBody: String = ""
    var acknowledgementRequired: Bool = false
    var acknowledged: Bool = false
    
    let greenColor = UIColor.init(red: 68/255.0, green: 176/255.0, blue: 49/255.0, alpha: 1.0)
    let fadedGreenColor = UIColor.init(red: 68/255.0, green: 176/255.0, blue: 49/255.0, alpha: 0.16)
    let orangeColor = UIColor.init(red: 251/255.0, green: 149/255.0, blue: 50/255.0, alpha: 1.0)
    let fadedOrangeColor = UIColor.init(red: 251/255.0, green: 149/255.0, blue: 50/255.0, alpha: 0.16)
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func markAccepted(_ accepted: Bool) {
        if accepted {
            actionLabel.textColor = greenColor
            actionLabel.text = "Action Accepted"
            let image = UIImage.named("notice-actioned")
            let tintedImage = image?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
            leftSquareImageView.image = tintedImage
            leftSquareImageView.tintColor = UIColor.white
            leftSquareView.backgroundColor = greenColor
            content.backgroundColor = fadedGreenColor
        } else {
            actionLabel.textColor = orangeColor
            actionLabel.text = "Action Needed"
            let image = UIImage.named("notice-needs-action")
            let tintedImage = image?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
            leftSquareImageView.image = tintedImage
            leftSquareImageView.tintColor = UIColor.white
            leftSquareView.backgroundColor = orangeColor
            content.backgroundColor = fadedOrangeColor
        }
    }
    
    func displayPercentage(_ percentage: String, color: UIColor) {
        let percentageButton = UIButton(type: .custom)
        percentageButton.frame = CGRect(x: 0.0, y: 0.0, width: 35.0, height: 35.0)
        
        percentageButton.setTitle("\(Int(round(Double(percentage)!)))%", for: UIControl.State())
        percentageButton.setTitleColor(color, for: UIControl.State())
        percentageButton.titleLabel!.font = UIFont(name: "ProximaNova-Regular", size: 16.0)!
        
        percentageButton.addTarget(self, action: #selector(percentageButtonTapped(_:)), for: .touchUpInside)
        accessoryView = percentageButton
    }
    
    func removePercentage() {
        accessoryView = nil
    }
    
    @objc func percentageButtonTapped(_ button: UIButton) {
        percentageButtonPressed?()
    }
    
    override var accessibilityElements: [Any]? {
        get {
            if _accessibilityElements == nil {
                let element = UIAccessibilityElement(accessibilityContainer: self)
                element.accessibilityFrameInContainerSpace = self.bounds
                
                if loadingIndicator.isAnimating {
                    element.accessibilityLabel = "Loading Notice"
                    element.accessibilityTraits = [.staticText]
                } else {
                    var percentAcknowledged: String?
                    if let percentButton = accessoryView as? UIButton,
                       let percent = percentButton.title(for: .normal) {
                        percentAcknowledged = "\(percent) Acknowledged"
                    }
                    element.accessibilityLabel = [noticeTitleLabel.text, actionLabel.text, percentAcknowledged]
                        .compactMap({ $0 })
                        .joined(separator: ", ")
                    if isSelected {
                        element.accessibilityTraits.formUnion([.selected])
                    }
                }                
                _accessibilityElements = [element]
            }
            return _accessibilityElements!
        }
        set { }
    }
    private var _accessibilityElements: [Any]?
}


