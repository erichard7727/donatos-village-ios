//
//  KudosHomeCell.swift
//  VillageContainerApp
//
//  Created by Russell Stephenson on 10/25/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit

class KudosHomeCell: UICollectionViewCell {
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var pointLabel: UILabel!
    @IBOutlet weak var avatarWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIView!
    
    var personID: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.avatarImageView.backgroundColor = UIColor.vlgGray
        self.avatarImageView.clipsToBounds = true
        self.avatarImageView.layer.cornerRadius = self.avatarWidthConstraint.constant / 2.0
        
        self.initializeCellContents()
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
    
    func initializeCellContents() {
        avatarImageView.image = nil
        nameLabel.text = ""
        titleLabel.text = ""
        pointLabel.text = ""
    }
    
    func configureAvatarImage(_ image: UIImage) {
        guard let avatarImageView = self.avatarImageView else { return }
        
        UIView.transition(
            with: avatarImageView,
            duration: 0.25,
            options: .transitionCrossDissolve,
            animations: {
                [weak avatarImageView] in
                avatarImageView?.image = image
            }, completion: nil
        )
    }
}
