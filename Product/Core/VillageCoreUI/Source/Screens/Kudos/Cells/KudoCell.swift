//
//  KudoCell.swift
//  VillageContainerApp
//
//  Created by Rob Feldmann on 3/31/17.
//  Copyright © 2017 Dynamit. All rights reserved.
//

import UIKit

class KudoCell: UITableViewCell {
    
    // MARK: - Public
    var personID: String?
    var displayDateLabel: Bool = false
    
    func configure(title: NSAttributedString, comment: String, points: Int, date: String) {
        titleLabel?.attributedText = title
        commentLabel?.text = comment
        pointsLabel?.text = "+\(points.description)\(points == 1 ? "pt" : "pts")"
        dateLabel?.text = date
        
        if !displayDateLabel {
            dateLabelConstraint.constant = 0
        }
    }
    
    func configureAvatarImage(_ image: UIImage) {
        guard let avatarImageView = self.avatarImageView else { return }
        
        UIView.transition(
            with: avatarImageView,
            duration: 0.25,
            options: .transitionCrossDissolve,
            animations: {
                [weak avatarImageView] in
                avatarImageView?.image = image
            }, completion: nil
        )
    }
    
    // MARK: - Private Outlets
    
    @IBOutlet private weak var boarderView: UIView? {
        didSet {
            // Apply cell border
            boarderView?.layer.borderColor = UIColor.vlgLightGray.cgColor
            boarderView?.layer.borderWidth = 1.0
            
//            // Apply cell shaddow
//            boarderView?.layer.shadowOffset = CGSize(width: 0, height: -3)
//            boarderView?.layer.shadowRadius = 1.0
//            boarderView?.layer.shadowOpacity = 0.20
//            boarderView?.layer.masksToBounds = false
        }
    }
    
    @IBOutlet weak var avatarImageView: UIImageView? {
        didSet {
            avatarImageView?.clipsToBounds = true
            avatarImageView?.backgroundColor = UIColor.vlgGray
        }
    }
    
    @IBOutlet private var avatarImageWidthConstraint: NSLayoutConstraint? {
        didSet {
            if let avatarImageWidthConstraint = self.avatarImageWidthConstraint {
                avatarImageView?.layer.cornerRadius = avatarImageWidthConstraint.constant / 2.0
            }
        }
    }
    
    @IBOutlet private weak var titleLabel: UILabel?
    @IBOutlet private weak var pointsLabel: UILabel?
    @IBOutlet private weak var commentLabel: UILabel?
    @IBOutlet private weak var dateLabel: UILabel?
    @IBOutlet weak var dateLabelConstraint: NSLayoutConstraint!

    // MARK: - UITableViewCell
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initializeCell()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        initializeCell()
    }
    
    func initializeCell() {
        avatarImageView?.image = nil
        titleLabel?.text = nil
        commentLabel?.text = nil
        pointsLabel?.text = nil
    }
    
}
