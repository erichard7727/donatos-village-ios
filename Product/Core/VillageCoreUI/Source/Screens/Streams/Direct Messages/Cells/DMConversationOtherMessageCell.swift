//
//  DMConversationOtherMessageCell.swift
//  VillageContainerApp
//
//  Created by Justin Munger on 5/19/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import Foundation
import UIKit
import Nantes
import VillageCore

class DMConversationOtherMessageCell: UITableViewCell {
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var messageContainerView: UIView!
    @IBOutlet weak var messageLabel: NantesLabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var avatarImageViewWidthConstraint: NSLayoutConstraint!
    
    var personID: String?
    var didSelectLink: ((URL) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Style both messages and avatars.
        self.messageContainerView.layer.masksToBounds = true
        self.messageContainerView.layer.cornerRadius = 18
        
        avatarImageView.layer.masksToBounds = true
        avatarImageView.layer.cornerRadius = avatarImageViewWidthConstraint.constant / 2.0
        avatarImageView.backgroundColor = UIColor.vlgGray
        
        self.messageLabel.linkAttributes = [
            .foregroundColor: UIColor.vlgGreen,
        ]
        self.messageLabel.enabledTextCheckingTypes = .link
        self.messageLabel.delegate = self
        
        initializeCell()
    }
    
    override func prepareForReuse() {
        initializeCell()
    }
    
    func initializeCell() {
        authorLabel.text = ""
        dateLabel.text = ""
        messageLabel.text = ""
        avatarImageView.image = nil
        personID = nil
        didSelectLink = nil
    }
    
    func configureCell(_ message: Message, didSelectLink: ((URL) -> Void)?) {
        authorLabel.text = message.authorDisplayName
        messageLabel.text = message.body

        if let date = villageCoreAPIDateFormatter.date(from: message.updated) {
            dateLabel.text = Date.timeAgoSinceDate(date, numericDates: true)
        } else {
            dateLabel.text = ""
        }
        
        personID = String(message.author.id)
        
        self.didSelectLink = didSelectLink
    }
    
    func configureAvatar(_ image: UIImage) {
        UIView.transition(with: avatarImageView, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.avatarImageView.image = image
            }, completion: nil)
    }
}

extension DMConversationOtherMessageCell: NantesLabelDelegate {
    func attributedLabel(_ label: NantesLabel, didSelectLink link: URL) {
        didSelectLink?(link)
    }
}
