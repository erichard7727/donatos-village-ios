//
//  PIAStreamView.swift
//  VillageCoreUI
//
//  Created by Jack Miller on 9/20/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit
import VillageCore

class PIAStreamView: NibView {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var leftImageView: UIImageView!
    @IBOutlet private weak var rightImageView: UIImageView!
    @IBOutlet private weak var contentLabel: UILabel!
    @IBOutlet private weak var detailsButton: UIButton!
    
    override func setupViews() {
        self.applyCardStyle()
    }

    convenience init(kudo: Kudo) {
        self.init()
        
        titleLabel.text = kudo.achievementTitle
        dateLabel.text = kudo.date.longformFormat.uppercased()
        contentLabel.text = kudo.comment
        
        if let senderImage = kudo.sender.avatarURL {
            leftImageView.af_setImage(withURL: senderImage)
        }
        
        if let receiverImage = kudo.receiver.avatarURL {
            rightImageView.af_setImage(withURL: receiverImage)
        }
        
    }
}
