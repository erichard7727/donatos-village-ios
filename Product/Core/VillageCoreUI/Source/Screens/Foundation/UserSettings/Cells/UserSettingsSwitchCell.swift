//
//  UserSettingsSwitchCell.swift
//  VillageCore
//
//  Created by Colin Drake on 3/1/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import Foundation
import UIKit

/// Generic user setting cell.
final class UserSettingsSwitchCell: UITableViewCell {
    /// Descriptive label for the cell.
    @IBOutlet weak var descriptiveLabel: UILabel!
    
    /// Switch outlet.
    @IBOutlet weak var enabledSwitch: UISwitch!
}
