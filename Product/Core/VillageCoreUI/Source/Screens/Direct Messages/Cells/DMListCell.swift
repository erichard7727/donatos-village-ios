//
//  DirectMessagesCell.swift
//  VillageCore
//
//  Created by Michael Miller on 1/25/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import Foundation
import UIKit

final class DMListCell: UITableViewCell {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var avatarImageViewHeightConstraint: NSLayoutConstraint!
    
    var personID: String?
    
    enum MessageState {
        case unread, read
    }
    var userAvatar: UIImage? = UIImage() {
        didSet {
            avatarImageView?.image = userAvatar
        }
    }
    var username: String = "" {
        didSet {
            usernameLabel?.text = username
        }
    }
    var time: Date? {
        didSet {
            if let time = time {
                let formatter = DateFormatter()
                
                let calendar = Calendar.current
                
                if calendar.isDateInToday(time) {
                    formatter.dateFormat = "h:mm a"
                } else {
                    formatter.dateFormat = "MMM d"
                }
                
                timeLabel?.text = formatter.string(from: time)
            } else {
                timeLabel?.text = ""
            }
        }
    }
    
    var message: String = "" {
        didSet {
            messageLabel?.text = message
        }
    }
    var messageState: MessageState = .unread {
        didSet {
            if messageState == .read {
                containerView?.alpha = 0.5
            } else {
                containerView?.alpha = 1.0
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = avatarImageViewHeightConstraint.constant / 2.0
        avatarImageView.backgroundColor = UIColor.vlgGray
        
        initializeCell()
    }
    
    override func prepareForReuse() {
        initializeCell()
    }
    
    func initializeCell() {
        usernameLabel.text = ""
        timeLabel.text = ""
        messageLabel.text = ""
        avatarImageView.image = nil
        
        personID = nil
    }
    
    func configureCellAvatar(_ image: UIImage) {
        UIView.transition(with: avatarImageView, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.avatarImageView.image = image
            }, completion: nil)
    }
}
