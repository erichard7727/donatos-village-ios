//
//  DMConversationOtherAttachmentCell.swift
//  VillageContainerApp
//
//  Created by Justin Munger on 5/19/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import Foundation
import UIKit
import Nantes
import VillageCore

class DMConversationOtherAttachmentCell: UITableViewCell {
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var messageContainerView: UIView!
    @IBOutlet weak var messageLabel: NantesLabel!
    @IBOutlet weak var avatarImageView: UIImageView! {
        didSet {
            avatarImageView.layer.masksToBounds = true
            avatarImageView.backgroundColor = UIColor.vlgGray

            let tap = UITapGestureRecognizer(target: self, action: #selector(_didSelectAvatar))
            avatarImageView?.addGestureRecognizer(tap)
        }
    }
    @IBOutlet weak var avatarImageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var attachmentImageView: UIImageView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    var message: Message?
    var didSelectLink: ((URL) -> Void)?
    private var didSelectAvatar: () -> Void = { }
    
    internal var aspectConstraint : NSLayoutConstraint? {
        didSet {
            if oldValue != nil {
                attachmentImageView.removeConstraint(oldValue!)
            }
            if aspectConstraint != nil {
                attachmentImageView.addConstraint(aspectConstraint!)
            }
        }
    }
    
    var aspect: CGFloat = 0
    @IBOutlet weak var percentageLabel: UILabel!
    
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

        avatarImageView.layer.cornerRadius = avatarImageViewWidthConstraint.constant / 2.0

        initializeCell()
    }
    
    override func prepareForReuse() {
        initializeCell()
        aspectConstraint = nil
    }
    
    func initializeCell() {
        authorLabel.text = ""
        dateLabel.text = ""
        messageLabel.text = ""
        
        if attachmentImageView.containsAnimatedImage() {
            attachmentImageView.stopAnimatedImage()
        }

        attachmentImageView.image = nil
        
        showProgressIndicator(true)
        didSelectLink = nil
    }
    
    func showProgressIndicator(_ show: Bool) {
        if show {
            self.activityIndicatorView.alpha = 1.0
            self.activityIndicatorView.startAnimating()
        } else {
            self.activityIndicatorView.alpha = 0.0
            self.activityIndicatorView.stopAnimating()
        }
    }
    
    func configureMessage(_ message: Message, didSelectLink: ((URL) -> Void)?, didSelectAvatar: @escaping () -> Void) {
        self.message = message
        
        authorLabel.text = message.authorDisplayName
        
        messageLabel.text = message.body
        if message.body.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty {
            messageContainerView.isHidden = true
        } else {
            messageContainerView.isHidden = false
        }
        
        if let date = villageCoreAPIDateFormatter.date(from: message.updated) {
            dateLabel.text = Date.timeAgoSinceDate(date, numericDates: true)
        } else {
            dateLabel.text = ""
        }
        
        if let attachment = message.attachment, attachment.width > 0, attachment.height > 0 {
            aspect = CGFloat(attachment.width) / CGFloat(attachment.height)
            aspectConstraint = NSLayoutConstraint(item: attachmentImageView!, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: attachmentImageView, attribute: NSLayoutConstraint.Attribute.height, multiplier: aspect, constant: 0.0)
        } else {
            aspectConstraint = NSLayoutConstraint(item: attachmentImageView!, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: attachmentImageView, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1.0, constant: 0.0)
        }
        
        self.didSelectLink = didSelectLink
        self.didSelectAvatar = didSelectAvatar
    }
    
    func configureAnimatedAttachment(_ attachmentImage: UIImage) {
        self.showProgressIndicator(false)
        UIView.transition(with: attachmentImageView, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.attachmentImageView.setAnimatedImage(animatedImage: attachmentImage)
            self.attachmentImageView.playAnimatedImage()
        }, completion: nil)
    }
    
    func configureAttachment(_ attachmentImage: UIImage) {
        self.showProgressIndicator(false)
        UIView.transition(with: attachmentImageView, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.attachmentImageView.image = attachmentImage
        }, completion: nil)
    }
    
    func configureAvatar(_ image: UIImage) {
        UIView.transition(with: avatarImageView, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.avatarImageView.image = image
            }, completion: nil)
    }

    @objc private func _didSelectAvatar() {
        didSelectAvatar()
    }
    
    deinit {
        if attachmentImageView.containsAnimatedImage() {
            attachmentImageView.stopAnimatedImage()
        }
    }
}

extension DMConversationOtherAttachmentCell: NantesLabelDelegate {
    func attributedLabel(_ label: NantesLabel, didSelectLink link: URL) {
        didSelectLink?(link)
    }
}
