//
//  KudoCell.swift
//  VillageContainerApp
//
//  Created by Rob Feldmann on 3/31/17.
//  Copyright © 2017 Dynamit. All rights reserved.
//

import UIKit
import VillageCore

class KudoCell: UITableViewCell {

    @IBOutlet private var kudoStreamView: KudoStreamView!

    func configure(kudo: Kudo, senderAndReceiverInfo: NSAttributedString, delegate: KudoStreamViewDelegate? = nil) {
        kudoStreamView.kudo = kudo
        kudoStreamView.senderAndReceiverInfo = senderAndReceiverInfo
        kudoStreamView.delegate = delegate
    }
    
}
