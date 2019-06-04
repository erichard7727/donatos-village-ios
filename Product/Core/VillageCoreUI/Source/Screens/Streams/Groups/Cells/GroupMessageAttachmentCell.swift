//
//  GroupMessageAttachmentCell.swift
//  VillageContainerApp
//
//  Created by Justin Munger on 5/19/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import Foundation
import UIKit
import Nantes
import VillageCore

class GroupMessageAttachmentCell: UITableViewCell {
    
    var message: Message?
    var stream: VillageCore.Stream?
    var didSelectLink: ((URL) -> Void)?
    var didSelectPerson:((Person) -> Void)?
    
    @IBOutlet weak var avatarImageView: UIImageView! {
        didSet {
            avatarImageView.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(viewAuthor))
            avatarImageView.addGestureRecognizer(tap)
        }
    }
    
    @IBOutlet weak var avatarImageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageLabel: NantesLabel!
    
    @IBOutlet weak var authorLabel: UILabel! {
        didSet {
            authorLabel.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(viewAuthor))
            authorLabel.addGestureRecognizer(tap)
        }
    }
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var attachmentView: UIImageView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var starCountLabel: UILabel!
    @IBOutlet weak var starButton: UIButton!
    var starOn: Bool = false
    
//    var personID: String?
//    var streamId: String!
//    var messageId: String!
//    var contentId: String!
//    var attachmentType: String!
//    var groupType: String!
    
    internal var aspectConstraint : NSLayoutConstraint? {
        didSet {
            if oldValue != nil {
                attachmentView.removeConstraint(oldValue!)
            }
            if aspectConstraint != nil {
                attachmentView.addConstraint(aspectConstraint!)
            }
        }
    }
    
    @IBOutlet weak var percentageLabel: UILabel!
    
    var aspect: CGFloat = 0

    override func awakeFromNib() {
        super.awakeFromNib()
        
        
        // Configure rounded borders.
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = avatarImageViewWidthConstraint.constant / 2.0
        avatarImageView.backgroundColor = UIColor.vlgGray
        
        self.messageLabel.linkAttributes = [
            .foregroundColor: UIColor.vlgGreen,
        ]
        self.messageLabel.enabledTextCheckingTypes = NSTextCheckingResult.CheckingType.link
        self.messageLabel.delegate = self
        
        // Speed optimizations.
        let rasterize = { (layer: CALayer) in
            layer.shouldRasterize = true
            layer.rasterizationScale = UIScreen.main.scale
        }
        
        let rasterizedComponents: [UIView] = [messageLabel, authorLabel, dateLabel]
        rasterizedComponents.map({$0.layer}).forEach(rasterize)
        
        initializeCellContents()
    }
    
    override func prepareForReuse() {
        initializeCellContents()
        aspectConstraint = nil
    }
    
    func initializeCellContents() {
        messageLabel.text = ""
        authorLabel.text = ""
        dateLabel.text = ""
        starCountLabel.text = ""
        starButton.imageEdgeInsets = UIEdgeInsets(
            top: starButton.frame.height / 4,
            left: 0,
            bottom: starButton.frame.height / 4,
            right: 0
        )
        starButton.imageView?.contentMode = .scaleAspectFit
        self.starButton.setImage(UIImage.named("star-off"), for: .normal)
        if attachmentView.containsAnimatedImage() {
            attachmentView.stopAnimatedImage()
        }
        attachmentView.image = nil
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
    
    func configureCellMessage(_ message: Message) {
        self.message = message

        messageLabel.text = message.body
        authorLabel.text = message.author.displayName
        starCountLabel.text = message.likesCount > 0 ? String(message.likesCount) : nil
        
        if message.isLiked {
            self.starButton.setImage(UIImage.named("star-on"), for: .normal)
            starOn = true
        } else {
            self.starButton.setImage(UIImage.named("star-off"), for: .normal)
            starOn = false
        }
        
        if let lastUpdated = villageCoreAPIDateFormatter.date(from: message.updated) {
            dateLabel.text = Date.timeAgoSinceDate(lastUpdated, numericDates: true)
        } else {
            dateLabel.text = nil
        }
        
        if let attachment = message.attachment, attachment.width > 0, attachment.height > 0 {
            aspect = CGFloat(attachment.width) / CGFloat(attachment.height)
            aspectConstraint = NSLayoutConstraint(item: attachmentView!, attribute: .width, relatedBy: .equal, toItem: attachmentView, attribute: .height, multiplier: aspect, constant: 0.0)
        } else {
            aspectConstraint = NSLayoutConstraint(item: attachmentView!, attribute: .width, relatedBy: .equal, toItem: attachmentView, attribute: .height, multiplier: 1.0, constant: 0.0)
        }
    }
    
    func configureCellAnimatedAttachment(_ attachmentImage: UIImage) {
        UIView.transition(with: attachmentView, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.attachmentView.setAnimatedImage(animatedImage: attachmentImage)
            self.attachmentView.playAnimatedImage()
        }, completion: nil)
    }

    func configureCellAttachment(_ attachmentImage: UIImage, _ contentId: String) {
            UIView.transition(
                with: attachmentView,
                duration: 0.25,
                options: .transitionCrossDissolve,
                animations: {
                    self.attachmentView.image = attachmentImage
                },
                completion: nil
            )
    }
    
    @IBAction func starButtonPressed(_ sender: UIButton) {
        guard let message = self.message else {
            return
        }
        
        if !message.isLiked {
            let orignalValue = self.starCountLabel.text
            UIView.animate(
                withDuration: 0.2,
                animations: {
                    self.starCountLabel.alpha = 0
                },
                completion: { result in
                    sender.setImage(UIImage.named("star-on"), for: .normal)
                    UIView.animate(
                        withDuration: 0.2,
                        animations: {
                            if let starCount = self.starCountLabel.text {
                                if var count = Int(starCount) {
                                    count = count + 1
                                    self.starCountLabel.text = String(count)
                                } else if starCount == "" {
                                    self.starCountLabel.text = "1"
                                }
                            }
                            self.starCountLabel.alpha = 1
                        }
                    )
                }
            )
            
            firstly {
                message.like()
            }.then { likedMessage in
                self.message = likedMessage
            }.catch { error in
                UIView.animate(
                    withDuration: 0.2,
                    animations: {
                        self.starCountLabel.alpha = 0
                    },
                    completion: { result in
                        sender.setImage(UIImage.named("star-off"), for: .normal)
                        UIView.animate(
                            withDuration: 0.2,
                            animations: {
                                self.starCountLabel.text = orignalValue
                                self.starCountLabel.alpha = 1
                            }
                        )
                    }
                )
            }
        } else {
            let orignalValue = self.starCountLabel.text
            UIView.animate(
                withDuration: 0.2,
                animations: {
                    self.starCountLabel.alpha = 0
                },
                completion: { result in
                    sender.setImage(UIImage.named("star-off"), for: .normal)
                    UIView.animate(
                        withDuration: 0.2,
                        animations: {
                            if let starCount = self.starCountLabel.text, var count = Int(starCount) {
                                count = count - 1
                                self.starCountLabel.text = String(count)
                            }
                            if self.starCountLabel.text == "0" {
                                self.starCountLabel.alpha = 0
                            } else {
                                self.starCountLabel.alpha = 1
                            }
                        }
                    )
                }
            )
            
            firstly {
                message.unlike()
            }.then { likedMessage in
                self.message = likedMessage
            }.catch { error in
                UIView.animate(
                    withDuration: 0.2,
                    animations: {
                        self.starCountLabel.alpha = 0
                    },
                    completion: { result in
                        sender.setImage(UIImage.named("star-on"), for: .normal)
                        UIView.animate(
                            withDuration: 0.2,
                            animations: {
                                self.starCountLabel.text = orignalValue
                                self.starCountLabel.alpha = 1
                            }
                        )
                    }
                )
            }
        }
    }
    
    @objc private func viewAuthor() {
        guard let author = message?.author else { return }
        didSelectPerson?(author)
    }

    deinit {
        if self.attachmentView.containsAnimatedImage() {
            self.attachmentView.stopAnimatedImage()
        }
    }
}

extension GroupMessageAttachmentCell: NantesLabelDelegate {
    
    func attributedLabel(_ label: NantesLabel, didSelectLink link: URL) {
        self.didSelectLink?(link)
    }
    
}
