//
//  UserSettingsGenericCell.swift
//  VillageCore
//
//  Created by Colin Drake on 2/29/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import Foundation
import UIKit

/// Generic user setting cell.
final class UserSettingsGenericCell: UITableViewCell {
    /// Descriptive label for the cell.
    @IBOutlet weak var descriptiveLabel: UILabel!
    
    /// Text field to edit in the cell.
    @IBOutlet weak var textField: UITextField!
}
