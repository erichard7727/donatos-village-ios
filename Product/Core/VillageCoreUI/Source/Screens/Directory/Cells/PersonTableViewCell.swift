//
//  PersonTableViewCell.swift
//  VillageCore
//
//  Created by Colin on 12/3/15.
//  Copyright © 2015 Dynamit. All rights reserved.
//

import UIKit
import VillageCore

final class PersonTableViewCell: UITableViewCell {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    
    @IBOutlet var avatarImageView: UIImageView!
    @IBOutlet var avatarImageViewHeightConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        // Configure appearance.
        avatarImageView.backgroundColor = UIColor.vlgGray
        avatarImageView.layer.cornerRadius = avatarImageViewHeightConstraint.constant / 2.0
        avatarImageView.clipsToBounds = true
        
        initializeCell()
    }
    
    override func prepareForReuse() {
        initializeCell()
    }
    
    func initializeCell() {
        nameLabel.text = ""
        titleLabel.text = ""
        avatarImageView.setImage(named: "default-avatar")
    }
    
    func configureForPerson(_ person: Person) {
        nameLabel.text = [person.firstName, person.lastName]
            .compactMap({ $0 })
            .joined(separator: " ")
        titleLabel.text = person.jobTitle
    }
    
    func configureAvatarImage(_ image: UIImage) {
        UIView.transition(with: avatarImageView, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.avatarImageView.image = image
        }, completion: nil)
    }
}
