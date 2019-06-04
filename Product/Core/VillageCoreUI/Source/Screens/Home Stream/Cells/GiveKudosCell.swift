//
//  GiveKudosCell.swift
//  VillageContainerApp
//
//  Created by Russell Stephenson on 5/2/17.
//  Copyright © 2017 Dynamit. All rights reserved.
//

import UIKit

class GiveKudosCell: UICollectionViewCell {
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var giveLabel: UILabel! {
        didSet {
            giveLabel.text = "Give a \(Constants.Settings.kudosSingularShort)"
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        containerView.layer.cornerRadius = 7.0
        containerView.layer.borderWidth = 1.0
        containerView.layer.borderColor = UIColor.clear.cgColor
        
        layer.cornerRadius = 7.0
        layer.borderWidth = 1.0
        layer.borderColor = UIColor.clear.cgColor
        
        layer.shadowOffset = CGSize(width: 0, height: 2.0)
        layer.shadowRadius = 2.0
        layer.shadowOpacity = 1.0
        layer.masksToBounds = false
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
    }
}
