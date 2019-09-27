//
//  PIAStreamView.swift
//  VillageCoreUI
//
//  Created by Jack Miller on 9/20/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit
import VillageCore

protocol KudoStreamViewDelegate: class {
    func kudoStreamView(_ view: KudoStreamView, didSelectMoreOptions kudo: Kudo)
}

class KudoStreamView: NibView {
    
    // View Model
    var kudo: Kudo?
    
    // Delegate
    weak var delegate: KudoStreamViewDelegate?
    
    // Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var kudoLabel: UILabel!
    @IBOutlet private weak var leftImageView: UIImageView!
    @IBOutlet private weak var rightImageView: UIImageView!
    @IBOutlet private weak var contentLabel: UILabel!
    @IBOutlet private weak var detailsButton: UIButton!
    
    override func setupViews() {
        self.applyCardStyle()
    }

    convenience init(kudo: Kudo, delegate: KudoStreamViewDelegate? = nil) {
        self.init()
        
        self.kudo = kudo
        self.delegate = delegate
        
        titleLabel.text = kudo.achievementTitle
        dateLabel.text = kudo.date.longformFormat.uppercased()
        contentLabel.text = kudo.comment
        
        kudoLabel.text = "My \(Constants.Settings.kudosSingularLong)"
        
        if let senderImage = kudo.sender.avatarURL {
            leftImageView.af_setImage(withURL: senderImage)
        }
        
        if let receiverImage = kudo.receiver.avatarURL {
            rightImageView.af_setImage(withURL: receiverImage)
        }
        
    }
    
    @IBAction func moreOptions() {
        guard let kudo = self.kudo else { assertionFailure(); return }
        delegate?.kudoStreamView(self, didSelectMoreOptions: kudo)
    }
}
