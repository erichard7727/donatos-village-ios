//
//  PersonCell.swift
//  VillageCore
//
//  Created by Justin Munger on 5/3/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit
import VillageCore

class PersonCell: UITableViewCell {
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    
    @IBOutlet var avatarImageView: UIImageView!
    @IBOutlet var avatarImageViewHeightConstraint: NSLayoutConstraint!
    
    var person: Person?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Configure appearance.
        avatarImageView.layer.cornerRadius = avatarImageViewHeightConstraint.constant / 2.0
        avatarImageView.clipsToBounds = true
        avatarImageView.backgroundColor = UIColor.vlgGray
        
        initializeCell()
    }
    
    override func prepareForReuse() {
        initializeCell()
    }
    
    func initializeCell() {
        nameLabel.text = ""
        titleLabel.text = ""
        
        avatarImageView.image = nil
        
        person = nil
    }
    
    func configureForPerson(_ person: Person) {
        self.person = person
        nameLabel.text = person.displayName
        titleLabel.text = person.jobTitle
    }
    
    func configureAvatarImage(_ image: UIImage) {
        UIView.transition(
            with: avatarImageView,
            duration: 0.25,
            options: .transitionCrossDissolve,
            animations: {
                self.avatarImageView.image = image
            },
            completion: nil
        )
    }
    
}
