//
//  KudosModalView.swift
//  VillageContainerApp
//
//  Created by Russell Stephenson on 4/17/17.
//  Copyright © 2017 Dynamit. All rights reserved.
//

import UIKit
import VillageCore

class KudosModalView: UIViewController {

    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var pointsLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel?
    @IBOutlet private var avatarImageWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var cardView: UIView!
    @IBOutlet private var moreButton: UIButton!
    
    var dismissModal : (() -> ())?

    private var kudo: Kudo?
    private var showMoreOptions: () -> Void = { }

    func configure(with kudo: Kudo, avatar: UIImage?) {
        self.kudo = kudo

        loadViewIfNeeded()

        if let image = avatar, let avatarImageView = self.avatarImageView {
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

        let regAttributes: [NSAttributedString.Key: Any] = [.font: UIFont(name: "ProximaNova-Regular", size: 15.0)!]
        let boldAttributes: [NSAttributedString.Key: Any] = [.font: UIFont(name: "ProximaNova-SemiBold", size: 15.0)!]
        let receiver = NSAttributedString(string: kudo.receiver.displayName ?? "Recipient", attributes: boldAttributes)
        let sender = NSAttributedString(string: kudo.sender.displayName ?? "Sender", attributes: boldAttributes)

        let title = NSMutableAttributedString()
        title.append(receiver)
        title.append(NSAttributedString(string: " received a \(Constants.Settings.kudosSingularShort) for \(kudo.achievementTitle) from ", attributes: regAttributes))
        title.append(sender)

        configure(
            title: title,
            comment: kudo.comment,
            points: kudo.points,
            showMoreOptions: { [weak self] in
                guard let kudo = self?.kudo else { return }

                let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(
                    title: "Report as Inappropriate",
                    style: .destructive,
                    handler: { [weak self] (_) in
                        let confirm = UIAlertController(
                            title: "Confirm Report as Inappropriate",
                            message: "Are you sure you want to report this \(Constants.Settings.kudosSingularShort) as inappropriate? It will be removed immedaitely and your name will be recorded as the reporter.",
                            preferredStyle: .alert
                        )
                        confirm.addAction(UIAlertAction(
                            title: "Report as Inappropriate",
                            style: .destructive,
                            handler: { (_) in
                                kudo.flag().then({ [weak self] (flaggedKudo) in
                                    self?.dismiss(animated: true, completion: {
                                        self?.dismissModal?()
                                    })
                                })
                            }
                        ))
                        confirm.addAction(UIAlertAction(
                            title: "Cancel",
                            style: .cancel,
                            handler: nil
                        ))
                        self?.present(confirm, animated: true, completion: nil)
                    }
                ))
                alert.addAction(UIAlertAction(
                    title: "Cancel",
                    style: .cancel,
                    handler: nil
                ))
                self?.present(alert, animated: true, completion: nil)
            }
        )
        
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
    
    func configure(title: NSAttributedString, comment: String, points: Int, showMoreOptions: @escaping () -> Void) {
        titleLabel?.attributedText = title
        descriptionLabel?.text = comment
        pointsLabel?.text = "+\(points.description)\(points == 1 ? "pt" : "pts")"
        self.showMoreOptions = showMoreOptions
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

    @IBAction private func moreOptions(_ sender: Any? = nil) {
        showMoreOptions()
    }
}
