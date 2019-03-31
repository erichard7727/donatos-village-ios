//
//  AchievementHeaderCell.swift
//  VillageContainerApp
//
//  Created by Russell Stephenson on 5/3/17.
//  Copyright © 2017 Dynamit. All rights reserved.
//

import UIKit

class AchievementHeaderCell: UITableViewCell {
    
    @IBOutlet weak var achievementImage: UIView!
    var achievementImageView = AchievementImageView(frame: CGRect(x: 0, y: 0, width: 150.0, height: 150.0))
    @IBOutlet weak var pointsLabel: UILabel!
    @IBOutlet weak var achievementTitle: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    var points: Int?
    var pointsCap: Int?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        achievementImageView.radius = 60.0
        achievementImageView.layer.cornerRadius = 30.0
        achievementImageView.backgroundColor = UIColor.white
        achievementImage.addSubview(achievementImageView)
    }
    
    func configureCellAttachment(_ attachmentImage: UIImage) {
        UIView.transition(with: achievementImageView.imageView, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.achievementImageView.imageView.image = attachmentImage
            self.achievementImageView.imageView.clipsToBounds = true
            self.achievementImageView.imageView.backgroundColor = UIColor.appGray()
            if let points = self.points, let cap = self.pointsCap, points/cap < 1 {
                self.achievementImageView.imageView.alpha = 0.6
            } else {
                self.achievementImageView.imageView.alpha = 1.0
            }
            //self.achievementImage.activityIndicator.stopAnimating()
            //self.achievementImage.activityIndicator.alpha = 0
            self.setNeedsLayout()
        }, completion: nil)
    }
}

