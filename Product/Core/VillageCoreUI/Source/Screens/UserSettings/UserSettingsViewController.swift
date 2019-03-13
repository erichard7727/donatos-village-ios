//
//  UserSettingsViewController.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 3/3/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit
import VillageCore

final class UserSettingsViewController: UIViewController {
    
}

// MARK: - UIViewController Overrides

extension UserSettingsViewController {
    
}

// MARK: - Target/Action

private extension UserSettingsViewController {
    
    @IBAction func onLogout(_ sender: Any? = nil) {
        User.current.logout()
    }
    
}
