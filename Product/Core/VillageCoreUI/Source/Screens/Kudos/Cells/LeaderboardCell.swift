//
//  LeaderboardCell.swift
//  VillageContainerApp
//
//  Created by Russell Stephenson on 9/27/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit

class LeaderboardCell: UITableViewCell {
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var pointLabel: UILabel!
    @IBOutlet weak var greenView: UIView!
    @IBOutlet weak var avatarImageViewWidthConstraint: NSLayoutConstraint!
    
    var personID: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = avatarImageViewWidthConstraint.constant / 2.0
        avatarImageView.backgroundColor = UIColor.vlgGray
    }
    
    func setCell() {
        greenView.layer.masksToBounds = true
        greenView.layer.cornerRadius = 8
    }
    
    func configureCellAvatar(_ image: UIImage) {
        UIView.transition(with: avatarImageView, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.avatarImageView.image = image
        }, completion: nil)
    }
}
