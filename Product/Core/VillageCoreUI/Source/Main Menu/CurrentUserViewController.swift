//
//  CurrentUserViewController.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 3/3/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit
import AlamofireImage
import VillageCore

final class CurrentUserViewController: UIViewController {
    
    @IBOutlet private weak var avatarImageView: UIImageView! {
        didSet {
            avatarImageView.layer.masksToBounds = true
            avatarImageView.clipsToBounds = true
        }
    }
    
    @IBOutlet private weak var avatarImageViewHeightConstraint: NSLayoutConstraint!
    
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
            avatarImageView.setImage(named: "default-avatar")
            return
        }
        
        displayNameLabel.text = user.displayName
        usernameLabel.text = user.emailAddress
        
        if let url = user.avatarURL {
            let filter = AspectScaledToFillSizeWithRoundedCornersFilter(
                size: avatarImageView.frame.size,
                radius: avatarImageViewHeightConstraint.constant / 2
            )
            
            avatarImageView.af_setImage(withURL: url, placeholderImage: UIImage.named("default-avatar"), filter: filter)
        }
    }
}

// MARK: - UIViewController Overrides

extension CurrentUserViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UIGestureRecognizer(target: self, action: #selector(onViewSettings(_:)))
        view.addGestureRecognizer(tap)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        avatarImageView.layer.cornerRadius = (avatarImageView.bounds.width / 2.0)
        avatarImageView.layer.borderWidth = 1.0
        avatarImageView.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
    }
    
}

// MARK: - Target/Action

private extension CurrentUserViewController {
    
    @objc func onViewSettings(_ sender: Any? = nil) {
        let settingsVC = UIStoryboard(name: "UserSettings", bundle: Constants.bundle).instantiateViewController(withIdentifier: "EditSettingsController") as! EditSettingsController
        sideMenuController?.setContentViewController(UINavigationController(rootViewController: settingsVC), fadeAnimation: true)
        sideMenuController?.hideMenu()
    }
    
}
