//
//  PersonProfileHeaderViewController.swift
//  VillageCore
//
//  Created by Colin on 12/9/15.
//  Copyright © 2015 Dynamit. All rights reserved.
//

import UIKit
import AlamofireImage
import VillageCore

/// View controller to display the person profile header.
/// This includes name, kudo count, etc.
final class PersonProfileHeaderViewController: UIViewController {

    var person: Person!
    
    /// Profile image view.
    @IBOutlet var profileImageView: UIImageView!
    
    /// Width constraint on profile image.
    @IBOutlet var profileImageWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet var fullNameLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet weak var kudosLabel: UILabel!
    @IBOutlet weak var kudosButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = profileImageWidthConstraint.constant / 2.0
        profileImageView.backgroundColor = UIColor.vlgGray
        
        fullNameLabel.text = person.displayName
        titleLabel.text = person.jobTitle
        kudosLabel.text = (person.kudos.points > 0) ? "- \(person.kudos.points) Kudos -" : ""
        
        if let url = person.avatarURL {
            profileImageView.af_setImage(
                withURL: url,
                filter: AspectScaledToFillSizeWithRoundedCornersFilter(
                    size: profileImageView.frame.size,
                    radius: profileImageView.frame.size.height / 2
            ))
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        kudosButton.layer.cornerRadius = 32/2
    }
    
    @IBAction func kudosButtonAction(_ sender: UIButton) {
        assertionFailure("Unhandled method")
    }
    
}
