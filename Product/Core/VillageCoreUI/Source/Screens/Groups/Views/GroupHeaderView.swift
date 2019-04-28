//
//  GroupHeaderView.swift
//  VillageContainerApp
//
//  Created by Justin Munger on 8/16/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit

protocol GroupHeaderViewDelegate: class {
    func inviteButtonPressed()
}

class GroupHeaderView: UIView {    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var inviteButton: UIButton!
    
    weak var delegate: GroupHeaderViewDelegate?
    
    override func awakeFromNib() {
        let inviteAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "ProximaNova-Semibold", size: 17.0)!,
            .foregroundColor: UIColor.vlgGreen
        ]
        
        let inviteAttributedString = NSMutableAttributedString(string: "Invite People Now", attributes: inviteAttributes)
        inviteButton.setAttributedTitle(inviteAttributedString, for: .normal)
    }
    
    @IBAction func inviteButtonPressed(_ sender: UIButton) {
        delegate?.inviteButtonPressed()
    }
}
