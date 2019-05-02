//
//  DMConversationSelfMessageCell.swift
//  VillageCore
//
//  Created by Michael Miller on 2/1/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import Foundation
import UIKit
import Nantes
import VillageCore

final class DMConversationSelfMessageCell: UITableViewCell {
    
    @IBOutlet weak var messageContainerView: UIView!
    @IBOutlet weak var messageLabel: NantesLabel!
    
    private var didSelectLink: ((URL) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()

        // Style both messages and avatars.
        self.messageContainerView.layer.masksToBounds = true
        self.messageContainerView.layer.cornerRadius = 18
        
        self.messageLabel.linkAttributes = [
            .foregroundColor: UIColor.vlgGreen,
        ]
        self.messageLabel.enabledTextCheckingTypes = .link
        self.messageLabel.delegate = self
    }
    
    func configureCell(_ message: Message, didSelectLink: @escaping ((URL) -> Void)) {
        messageLabel.text = message.body
        self.didSelectLink = didSelectLink
    }
}

extension DMConversationSelfMessageCell: NantesLabelDelegate {

    func attributedLabel(_ label: NantesLabel, didSelectLink link: URL) {
        didSelectLink?(link)
    }
    
}
