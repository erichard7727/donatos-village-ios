//
//  JoinGroupCell.swift
//  VillageContainerApp
//
//  Created by Russell Stephenson on 1/11/17.
//  Copyright © 2017 Dynamit. All rights reserved.
//

import UIKit

class JoinGroupCell: UICollectionViewCell {
    
    @IBOutlet weak var exploreGroupsButton: UIButton!
    @IBOutlet weak var exploreButtonHeight: NSLayoutConstraint!
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        exploreGroupsButton.layer.cornerRadius = exploreButtonHeight.constant / 2
        exploreGroupsButton.layer.borderWidth = 0.5
        exploreGroupsButton.layer.borderColor = UIColor.white.cgColor
        exploreGroupsButton.isEnabled = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.borderColor = UIColor.init(red: 224/255.0, green: 224/255.0, blue: 224/255.0, alpha: 1.0).cgColor
        
        let border = CAShapeLayer()
        border.strokeColor = UIColor.white.cgColor
        border.fillColor = nil
        border.lineDashPattern = [2,1]
        
        border.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: 7.0).cgPath
        
        layer.addSublayer(border)
    }
}
