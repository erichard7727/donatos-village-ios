//
//  UserSettingsHeaderController.swift
//  VillageCore
//
//  Created by Colin Drake on 3/1/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit
import VillageCore

protocol UserSettingsHeaderControllerDelegate {
    func didSelectNewAvatarImage(_ image: UIImage, controller: UserSettingsHeaderController)
    func didSelectNewCoverImage(_ image: UIImage, controller: UserSettingsHeaderController)
}

/// View controller for the User Settings screen header.
final class UserSettingsHeaderController: UIViewController {
    // MARK: Properties

    @IBOutlet weak var coverImageView: UIImageView?
    @IBOutlet weak var avatarImageView: UIImageView?
    @IBOutlet weak var nameLabel: UILabel?
    @IBOutlet weak var jobTitleLabel: UILabel?
    @IBOutlet weak var avatarImageViewWidthConstraint: NSLayoutConstraint?
    
    var delegate: UserSettingsHeaderControllerDelegate?
    
    var person: Person? {
        didSet {
            guard let person = person else { return }
            configureForPerson(person)
        }
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let avatarImageView = avatarImageView, let avatarImageViewWidthConstraint = avatarImageViewWidthConstraint {
            avatarImageView.layer.cornerRadius = avatarImageViewWidthConstraint.constant / 2.0
            avatarImageView.clipsToBounds = true
        }
        
        if let person = person {
            configureForPerson(person)
        }
    }
    
    // MARK: Helpers
    
    func configureForPerson(_ person: Person) {
        guard isViewLoaded else { return }
        nameLabel?.text = person.displayName
        jobTitleLabel?.text = person.jobTitle
    }
    
    // MARK: Actions
    
    @IBAction func changeProfileButtonPressed(_ sender: UIButton) {
        let alert = UIAlertController.dismissable(title: "Error", message: "Not yet implemented!")
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func changeCoverPhotoButtonPressed(_ sender: UIButton) {
        let alert = UIAlertController.dismissable(title: "Error", message: "Not yet implemented!")
        present(alert, animated: true, completion: nil)
    }
}
