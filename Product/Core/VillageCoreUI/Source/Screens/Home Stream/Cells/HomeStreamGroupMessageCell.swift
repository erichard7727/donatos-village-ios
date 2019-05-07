//
//  HomeStreamGroupMessageCell.swift
//  VillageCore
//
//  Created by Michael Miller on 1/12/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import Foundation
import UIKit
import Nantes

/// Delegate for home stream group cell objects.
protocol HomeStreamGroupMessageCellDelegate: class {
    func didSelectGroupMessageCell(_ cell: HomeStreamGroupMessageCell)
    func didSelect(link: URL)
}

/// Home stream cell for groups.
final class HomeStreamGroupMessageCell: UITableViewCell {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var notificationLabelCount: UILabel!
    @IBOutlet weak var userAvatarImage: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var postDateLabel: UILabel!
    @IBOutlet weak var postBodyLabel: NantesLabel!
    @IBOutlet weak var morePostsButton: UIButton!
    @IBOutlet weak var notificationLabelWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var userAvatarImageHeightConstraint: NSLayoutConstraint!
    
    weak var delegate: HomeStreamGroupMessageCellDelegate?
    
    var groupName: String = "" {
        didSet {
            groupNameLabel.text = groupName
        }
    }
    var groupPosts: Int = 0 {
        didSet {
            let hide = (groupPosts == 0)
            notificationLabelCount.text = String(groupPosts)
            notificationLabelCount.isHidden = hide
        }
    }
    var userAvatar: UIImage? {
        didSet {
            //userAvatarImage.image = userAvatar
        }
    }
    var userName: String = "" {
        didSet {
            userNameLabel.text = userName
        }
    }
    var postDate: Date = Date() {
        didSet {
            postDateLabel.text = Date.timeAgoSinceDate(postDate, numericDates: true)
        }
    }
    var postBody: String = "" {
        didSet {
            postBodyLabel.text = postBody
        }
    }
    
    var personID: String?
    
    override func awakeFromNib() {
        
        super.awakeFromNib()

        // Drop shadow.
        self.containerView.layer.shadowColor = UIColor.black.cgColor
        self.containerView.layer.shadowRadius = 3.0
        self.containerView.layer.shadowOpacity = 0.1
        self.containerView.layer.shadowOffset = CGSize(width: 0, height: 3);
        
        self.containerView.layer.shouldRasterize = true
        self.containerView.layer.rasterizationScale = UIScreen.main.scale
        
        self.userAvatarImage.backgroundColor = UIColor.vlgGray
        self.userAvatarImage.clipsToBounds = true
        self.userAvatarImage.layer.cornerRadius = self.userAvatarImageHeightConstraint.constant / 2.0

        self.postBodyLabel.linkAttributes = [.foregroundColor: UIColor.vlgGreen]
        self.postBodyLabel.enabledTextCheckingTypes = .link
        self.postBodyLabel.delegate = self
        
        self.selectionStyle = .none
        
        initializeCell()
    }
    
    override func prepareForReuse() {
        initializeCell()
    }
    
    func initializeCell() {
        personID = nil
        groupNameLabel.text = ""
        userNameLabel.text = ""
        postDateLabel.text = ""
        postBodyLabel.text = ""
        userAvatarImage.image = nil
        
        notificationLabelCount.text = ""
        notificationLabelCount.isHidden = true
        notificationLabelCount.layer.cornerRadius = 0.0
        notificationLabelCount.layer.masksToBounds = false
        notificationLabelCount.backgroundColor = UIColor.clear
        
    }
    
    func configureAvatarImage(_ image: UIImage) {
        UIView.transition(with: userAvatarImage, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.userAvatarImage.image = image
            }, completion: nil)
    }
    
    func setUnread(unread: Bool) {
        if unread {
            notificationLabelCount.isHidden = false
            notificationLabelCount.layer.cornerRadius = notificationLabelWidthConstraint.constant / 2.0
            notificationLabelCount.layer.masksToBounds = true
            notificationLabelCount.backgroundColor = UIColor.vlgBlue
        } else {
            notificationLabelCount.isHidden = true
            notificationLabelCount.layer.cornerRadius = 0.0
            notificationLabelCount.layer.masksToBounds = false
            notificationLabelCount.backgroundColor = UIColor.clear
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        guard selected == false else {
            self.setSelected(false, animated: false)
            return
        }
    }
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        delegate?.didSelectGroupMessageCell(self)
    }
}

extension HomeStreamGroupMessageCell: NantesLabelDelegate {
    func attributedLabel(_ label: NantesLabel, didSelectLink link: URL) {
        delegate?.didSelect(link: link)
    }
}
