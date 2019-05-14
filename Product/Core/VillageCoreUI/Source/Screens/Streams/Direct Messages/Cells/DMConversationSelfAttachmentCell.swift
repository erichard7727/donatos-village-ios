//
//  DMConversationSelfAttachmentCell.swift
//  VillageContainerApp
//
//  Created by Justin Munger on 5/19/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import Foundation
import UIKit
import Nantes
import VillageCore

class DMConversationSelfAttachmentCell: UITableViewCell {
    var message: Message?
    
    @IBOutlet weak var messageContainerView: UIView!
    @IBOutlet weak var messageLabel: NantesLabel!
    @IBOutlet weak var attachmentImageView: UIImageView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    var didSelectLink: ((URL) -> Void)?
    
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
        
        self.activityIndicatorView.alpha = 1.0
        self.activityIndicatorView.startAnimating()
        
        initializeCell()
    }
    
    override func prepareForReuse() {
        initializeCell()
        aspectConstraint = nil
    }
    
    func initializeCell() {
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
    
    func configureMessage(_ message: Message, didSelectLink: ((URL) -> Void)?) {
        self.message = message
        if message.body.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty {
            messageContainerView.isHidden = true
        } else {
            messageContainerView.isHidden = false
        }
        //messageLabel.alpha = synced.boolValue ? 1.0 : 0.5
        messageLabel.text = message.body
        
        if let attachment = message.attachment, attachment.width > 0, attachment.height > 0 {
            aspect = CGFloat(attachment.width) / CGFloat(attachment.height)
            aspectConstraint = NSLayoutConstraint(item: attachmentImageView!, attribute: .width, relatedBy: .equal, toItem: attachmentImageView, attribute: .height, multiplier: aspect, constant: 0.0)
        } else {
            aspectConstraint = NSLayoutConstraint(item: attachmentImageView!, attribute: .width, relatedBy: .equal, toItem: attachmentImageView, attribute: .height, multiplier: 1.0, constant: 0.0)
        }

        self.didSelectLink = didSelectLink
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
    
    deinit {
        if attachmentImageView.containsAnimatedImage() {
            attachmentImageView.stopAnimatedImage()
        }
    }
}

extension DMConversationSelfAttachmentCell: NantesLabelDelegate {
    func attributedLabel(_ label: NantesLabel, didSelectLink link: URL) {
        didSelectLink?(link)
    }
}
