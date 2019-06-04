//
//  GroupHeaderVIew.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 5/15/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit

protocol GroupHeaderViewDelegate: class {
    func inviteButtonPressed()
}

final class GroupHeaderViewCell: UITableViewCell {
 
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var inviteButton: UIButton! {
        didSet {
            let inviteAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "ProximaNova-Semibold", size: 17.0)!,
                .foregroundColor: UIColor.vlgGreen
            ]
            
            let inviteAttributedString = NSMutableAttributedString(string: "Invite People Now", attributes: inviteAttributes)
            inviteButton.setAttributedTitle(inviteAttributedString, for: .normal)
        }
    }
    
    weak var delegate: GroupHeaderViewDelegate?
    
    @IBAction func inviteButtonPressed(_ sender: UIButton) {
        delegate?.inviteButtonPressed()
    }
    
}
