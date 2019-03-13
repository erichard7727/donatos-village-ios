//
//  CurrentUserViewController.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 3/3/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit
import VillageCore

final class CurrentUserViewController: UIViewController {
    
    @IBOutlet private weak var avatarImageView: UIImageView! {
        didSet {
            avatarImageView.layer.masksToBounds = true
            avatarImageView.clipsToBounds = true
        }
    }
    
    @IBOutlet private weak var displayNameLabel: UILabel!
    @IBOutlet private weak var usernameLabel: UILabel!

}

// MARK: Public Methods

extension CurrentUserViewController {
    
    func configure(with user: User) {
        loadViewIfNeeded()
        
        guard !user.isGuest else {
            displayNameLabel.text = nil
            usernameLabel.text = nil
            return
        }
        
        displayNameLabel.text = user.displayName
        usernameLabel.text = user.emailAddress
    }
}

// MARK: - UIViewController Overrides

extension CurrentUserViewController {
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        avatarImageView.layer.cornerRadius = (avatarImageView.bounds.width / 2.0)
        avatarImageView.layer.borderWidth = 1.0
        avatarImageView.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
    }
    
}

// MARK: - Target/Action

private extension CurrentUserViewController {
    
    @IBAction func onViewSettings(_ sender: Any? = nil) {
        let settingsVC = UIStoryboard(name: "UserSettingsViewController", bundle: Constants.bundle).instantiateInitialViewController()!
        sideMenuController?.setContentViewController(settingsVC, fadeAnimation: true)
        sideMenuController?.hideMenu()
    }
    
}
