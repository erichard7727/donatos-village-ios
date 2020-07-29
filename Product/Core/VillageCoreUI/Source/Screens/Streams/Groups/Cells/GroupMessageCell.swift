//
//  GroupMessageCell.swift
//  VillageCore
//
//  Created by Colin on 12/10/15.
//  Copyright © 2015 Dynamit. All rights reserved.
//

import UIKit
import SafariServices
import Nantes
import Promises
import VillageCore
import AlamofireImage

final class GroupMessageCell: UITableViewCell {
    
    var message: Message?
    var stream: VillageCore.Stream?
    var isDirectMessage = false {
        didSet {
            starButton.alpha = isDirectMessage ? 0 : 1
            starButton.isEnabled = !isDirectMessage
            starCountLabel.alpha = isDirectMessage ? 0 : 1
            
            authorLabel.textColor = UIColor.white
            messageLabel.textColor = UIColor.white
            starCountLabel.textColor = UIColor.white
            backgroundColor = UIColor.clear

        }
    }
    var didSelectLink: ((URL) -> Void)?
    var didSelectPerson:((Person) -> Void)?
    var showMoreOptions: () -> Void = { }
    
    
    @IBOutlet private var avatarImageView: UIImageView! {
        didSet {
            avatarImageView.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(viewAuthor))
            avatarImageView.addGestureRecognizer(tap)
        }
    }
    
    @IBOutlet private var avatarImageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet private var messageLabel: NantesLabel!
    
    @IBOutlet private var authorLabel: UILabel! {
        didSet {
            authorLabel.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(viewAuthor))
            authorLabel.addGestureRecognizer(tap)
        }
    }
    
    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private weak var starCountLabel: UILabel!
    @IBOutlet weak var starButton: UIButton!
   
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.messageLabel.linkAttributes = [NSAttributedString.Key.foregroundColor: UIColor.vlgGreen]
        self.messageLabel.enabledTextCheckingTypes = NSTextCheckingResult.CheckingType.link
        self.messageLabel.delegate = self
        
        // Configure rounded borders.
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = avatarImageViewWidthConstraint.constant / 2.0
        avatarImageView.backgroundColor = UIColor.vlgGray

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
    }
    
    func initializeCellContents() {
        authorLabel.text = ""
        dateLabel.text = ""
        messageLabel.text = ""
        avatarImageView.image = nil
        starCountLabel.text = ""
        starButton.imageEdgeInsets = UIEdgeInsets(top: starButton.frame.height / 4, left: 0, bottom: starButton.frame.height / 4, right: 0)
        starButton.imageView?.contentMode = .scaleAspectFit
        self.starButton.setImage(UIImage.named("star-off"), for: .normal)
    }
    
    func configureCellAvatar(_ image: UIImage) {
        UIView.transition(with: avatarImageView, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.avatarImageView.image = image
            }, completion: nil)
    }
    
    func configureCell(_ message: Message) {
        self.message = message
        messageLabel.text = message.body
        authorLabel.text = message.author.displayName
        starCountLabel.text = message.likesCount > 0 ? String(message.likesCount) : ""
        
        if message.isLiked {
            self.starButton.setImage(UIImage.named("star-on"), for: .normal)
        } else {
            self.starButton.setImage(UIImage.named("star-off"), for: .normal)
        }

        if let lastUpdated = villageCoreAPIDateFormatter.date(from: message.updated) {
            dateLabel.text = Date.timeAgoSinceDate(lastUpdated, numericDates: true)
        } else {
            dateLabel.text = nil
        }
        
        if let url = message.author.avatarURL {
            let filter = AspectScaledToFillSizeWithRoundedCornersFilter(
                size: avatarImageView.frame.size,
                radius: avatarImageView.frame.size.height / 2
            )
            avatarImageView.af_setImage(withURL: url, filter: filter)
        }
        setNeedsLayout()
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

    @IBAction private func moreOptions(_ sender: Any? = nil) {
        showMoreOptions()
    }
    
}

extension GroupMessageCell: NantesLabelDelegate {

    func attributedLabel(_ label: NantesLabel, didSelectLink link: URL) {
        self.didSelectLink?(link)
    }
    
}
