//
//  DMSearchCell.swift
//  VillageCore
//
//  Created by Michael Miller on 2/9/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit
import VillageCore

final class DMSeachCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        
    }
    
    func configureForPerson(_ person: Person) {
        self.nameLabel.text = person.displayName
    }
    
}
