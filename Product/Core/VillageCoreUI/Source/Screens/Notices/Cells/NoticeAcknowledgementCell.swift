//
//  NoticeAcknowledgementCell.swift
//  VillageContainerApp
//
//  Created by Justin Munger on 9/1/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit

class NoticeAcknowledgementCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var acknowledgedLabel: UILabel!
    
    @IBOutlet weak var avatarImageViewHeightConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        // Configure appearance.
        avatarImageView.layer.cornerRadius = avatarImageViewHeightConstraint.constant / 2.0
        avatarImageView.clipsToBounds = true
        avatarImageView.backgroundColor = UIColor.vlgGray
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        avatarImageView.image = nil
    }

    func markAcknowledged(_ read: Bool) {
        if read {
            contentView.alpha = 0.5
            
            let checkImage = UIImage.named("checkmark")!.withRenderingMode(.alwaysTemplate)
            
            let checkAccessoryButtonSize = checkImage.size
            
            let checkAccessoryButton = UIButton(type: .custom)
            checkAccessoryButton.frame = CGRect(x: 0.0, y: 0.0, width: checkAccessoryButtonSize.width, height: checkAccessoryButtonSize.height)
            
            checkAccessoryButton.setBackgroundImage(checkImage, for: UIControl.State())
            checkAccessoryButton.tintColor = UIColor.vlgGreen
            
            accessoryView = checkAccessoryButton
            
            acknowledgedLabel.isHidden = false
        } else {
            contentView.alpha = 1.0
            accessoryView = nil
            acknowledgedLabel.isHidden = true
        }
    }
    
    func displayPercentage(_ percentage: Double) {
        let percentageButton = UIButton(type: .custom)
        percentageButton.frame = CGRect(x: 0.0, y: 0.0, width: 35.0, height: 35.0)
        
        percentageButton.setTitle("\(Int(round(Double(percentage))))%", for: UIControl.State())
        percentageButton.setTitleColor(UIColor.vlgGreen, for: UIControl.State())
        percentageButton.titleLabel!.font = UIFont(name: "ProximaNova-Regular", size: 16.0)!

        accessoryView = percentageButton
    }
    
    func configureAvatarImage(_ image: UIImage) {
        UIView.transition(with: avatarImageView, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.avatarImageView.image = image
        }, completion: nil)
    }
}
