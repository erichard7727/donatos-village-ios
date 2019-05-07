//
//  KudosModalView.swift
//  VillageContainerApp
//
//  Created by Russell Stephenson on 4/17/17.
//  Copyright © 2017 Dynamit. All rights reserved.
//

import UIKit

class KudosModalView: UIViewController {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var pointsLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel?
    @IBOutlet private var avatarImageWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var cardView: UIView!
    
    var dismissModal : (() -> ())?
    var avatar: UIImage!
    var kudosTitle: NSAttributedString!
    var kudosDescription: String!
    var points: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if avatar != nil {
            configureAvatarImage(avatar)
        }
        
        if kudosTitle != nil && kudosDescription != nil && points != nil {
            configure(title: kudosTitle, comment: kudosDescription, points: points)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        avatarImageView.layer.cornerRadius = avatarImageWidthConstraint.constant / 2
        avatarImageView?.clipsToBounds = true
        avatarImageView?.backgroundColor = UIColor.vlgGray
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        cardView.layer.cornerRadius = 7.0
        cardView.layer.borderWidth = 1.0
        cardView.layer.borderColor = UIColor.clear.cgColor
        
        cardView.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        cardView.layer.shadowRadius = 2.0
        cardView.layer.shadowOpacity = 1.0
        cardView.layer.masksToBounds = false
        cardView.layer.shadowPath = UIBezierPath(roundedRect: cardView.bounds, cornerRadius: cardView.layer.cornerRadius).cgPath
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        dismiss(animated: true, completion: {
            self.dismissModal!()
        })
    }
    
    func configure(title: NSAttributedString, comment: String, points: Int) {
        titleLabel?.attributedText = title
        descriptionLabel?.text = comment
        pointsLabel?.text = "+\(points.description)\(points == 1 ? "pt" : "pts")"
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
}
