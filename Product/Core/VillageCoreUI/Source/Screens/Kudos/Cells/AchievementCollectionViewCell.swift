//
//  AchievementCollectionViewCell.swift
//  VillageContainerApp
//
//  Created by Russell Stephenson on 9/19/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit

class AchievementCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var achievementImage: UIView!
    @IBOutlet weak var achievementTitleLabel: UILabel!
    var achievementImageView: AchievementImageView? = AchievementImageView(frame: CGRect(x: 0, y: 0, width: 87.0, height: 87.0))
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView! {
        didSet {
            activityIndicator.startAnimating()
            activityIndicator.alpha = 0
        }
    }
    
    var points: Int?
    var pointsCap: Int?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if let aIV = achievementImageView {
            achievementImage.addSubview(aIV)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        points = 0
        pointsCap = 0
        achievementTitleLabel.text = ""
        achievementImage.backgroundColor = UIColor.white
        if let aIV = achievementImageView {
            aIV.progress = 0.0
            aIV.imageView.image = nil
            aIV.backgroundColor = UIColor.white
        }
    }
    
    deinit {
        achievementImageView = nil
    }
    
    func configureCellAttachment(_ attachmentImage: UIImage) {
//        if achievementImage.imageView != nil {
//            UIView.transition(with: achievementImage.imageView, duration: 0.25, options: .transitionCrossDissolve, animations: {
//                self.achievementImage.imageView.image = attachmentImage
//                self.achievementImage.imageView.clipsToBounds = true
//                self.achievementImage.imageView.backgroundColor = UIColor.appGray()
//                if let points = self.points, let cap = self.pointsCap, points/cap < 1 {
//                    self.achievementImage.imageView.alpha = 0.6
//                } else {
//                    self.achievementImage.imageView.alpha = 1.0
//                }
//                self.achievementImage.activityIndicator.stopAnimating()
//                self.achievementImage.activityIndicator.alpha = 0
//                self.setNeedsLayout()
//            }, completion: nil)
//        }
    }
}
