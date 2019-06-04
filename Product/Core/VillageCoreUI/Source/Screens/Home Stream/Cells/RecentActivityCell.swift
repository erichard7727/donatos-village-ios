//
//  RecentActivityCell.swift
//  VillageContainerApp
//
//  Created by Russell Stephenson on 10/20/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit
import VillageCore

class RecentActivityCell: UICollectionViewCell {
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var firstNameLabel: UILabel!
    @IBOutlet weak var firstTimeLabel: UILabel!
    @IBOutlet weak var firstActivityLabel: UILabel!
    @IBOutlet weak var firstAvatarImageView: UIImageView!
    @IBOutlet weak var messageImageView: UIImageView!
    @IBOutlet weak var messageImageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var firstAvatarImageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var unreadMessageCountHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var unreadNotificationLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    var personID: String?
    var isPanelOpen: Bool = false
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        firstAvatarImageView.backgroundColor = UIColor.vlgGray
        firstAvatarImageView.clipsToBounds = true
        firstAvatarImageView.layer.cornerRadius = self.firstAvatarImageHeightConstraint.constant / 2.0
        firstAvatarImageView.clipsToBounds = true
        
        initializeCell()
    }
    
    override func prepareForReuse() {
        initializeCell()
    }
    
    func initializeCell() {
        personID = nil
        categoryLabel.text = ""
        firstNameLabel.text = ""
        firstTimeLabel.text = ""
        firstActivityLabel.text = ""
        firstAvatarImageView.image = nil
        
        if messageImageView.containsAnimatedImage() {
            messageImageView.stopAnimatedImage()
        }
        
        unreadNotificationLabel.text = ""
        unreadNotificationLabel.isHidden = true
        unreadNotificationLabel.layer.cornerRadius = 0.0
        unreadNotificationLabel.layer.masksToBounds = false
        unreadNotificationLabel.backgroundColor = UIColor.clear
        messageImageViewHeightConstraint.constant = 0
        
        firstActivityLabel.numberOfLines = 0

        showProgressIndicator(false)
    }
    
    func setCell(groupItem: VillageCore.Stream) {
        
        if !isPanelOpen {
            firstActivityLabel.numberOfLines = 1
        } else {
            firstActivityLabel.numberOfLines = 0
        }
        
        categoryLabel.text = groupItem.name
        
        if let messageItem = groupItem.details?.mostRecentMessage {
            firstNameLabel.text = messageItem.author.displayName
            
            if let date = villageCoreAPIDateFormatter.date(from: messageItem.created) {
                formatDate(date: date)
            }
            
            firstActivityLabel.text = messageItem.body
            personID = String(messageItem.author.id)
        }
        
        configureUnreadCount(groupItem.details?.unreadCount ?? 0)
//        setUnread(unread: groupItem.details?.isUnread ?? false)
    }
    
    func formatDate(date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let calendar = NSCalendar.autoupdatingCurrent
        if calendar.isDateInToday(date) {
            dateFormatter.dateFormat = "hh:mma"
        } else {
            dateFormatter.dateFormat = "MMM dd, yyyy"
        }

        firstTimeLabel.text = dateFormatter.string(from: date)
    }
    
    func configureAvatarImage(_ image: UIImage) {
        UIView.transition(with: firstAvatarImageView, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.firstAvatarImageView.image = image
            }, completion: nil)
    }
    
    func configureCellAnimatedAttachment(_ attachmentImage: UIImage) {
        UIView.transition(with: messageImageView, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.messageImageView.setAnimatedImage(animatedImage: attachmentImage)
            self.messageImageView.playAnimatedImage()
        }, completion: nil)
    }
    
    func configureCellAttachment(_ attachmentImage: UIImage) {
        UIView.transition(with: messageImageView, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.messageImageView.image = attachmentImage
            self.messageImageView.clipsToBounds = true
            self.messageImageView.backgroundColor = UIColor.white
            self.setNeedsLayout()
            }, completion: nil)
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
    
    func configureUnreadCount(_ unreadCount: Int) {
        if unreadCount > 0 {
            if unreadCount > 99 {
                unreadNotificationLabel.text = "\(99)" + "+"
            } else {
                unreadNotificationLabel.text = "\(unreadCount)"
            }
            unreadNotificationLabel.isHidden = !isPanelOpen || false
            unreadNotificationLabel.layer.cornerRadius = unreadMessageCountHeightConstraint.constant / 2.0
            unreadNotificationLabel.layer.masksToBounds = true
            unreadNotificationLabel.backgroundColor = UIColor.vlgBlue
        } else {
            unreadNotificationLabel.text = ""
            unreadNotificationLabel.isHidden = !isPanelOpen || true
            unreadNotificationLabel.layer.cornerRadius = 0.0
            unreadNotificationLabel.layer.masksToBounds = false
            unreadNotificationLabel.backgroundColor = UIColor.clear
        }
    }
    
    func setUnread(unread: Bool) {
        unreadNotificationLabel.text = ""
        if unread {
            unreadNotificationLabel.isHidden = false
            unreadNotificationLabel.layer.cornerRadius = unreadMessageCountHeightConstraint.constant / 2.0
            unreadNotificationLabel.layer.masksToBounds = true
            unreadNotificationLabel.backgroundColor = UIColor.vlgGreen
        } else {
            unreadNotificationLabel.isHidden = true
            unreadNotificationLabel.layer.cornerRadius = 0.0
            unreadNotificationLabel.layer.masksToBounds = false
            unreadNotificationLabel.backgroundColor = UIColor.clear
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = 7.0
        layer.borderWidth = 1.0
        
        if !isPanelOpen {
            layer.borderColor = UIColor.clear.cgColor
            layer.shadowOffset = CGSize(width: 0, height: 2.0)
            layer.shadowRadius = 2.0
            layer.shadowOpacity = 1.0
            layer.masksToBounds = false
            layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
        } else {
            layer.borderColor = UIColor.init(red: 224/255.0, green: 224/255.0, blue: 224/255.0, alpha: 1.0).cgColor
            layer.shadowOffset = CGSize(width: 0, height: 0.0)
            layer.shadowRadius = 0.0
            layer.shadowOpacity = 0.0
            layer.masksToBounds = true
            layer.shadowPath = nil
        }
    }
    
    deinit {
        if messageImageView.containsAnimatedImage() {
            messageImageView.stopAnimatedImage()
        }
    }
}
