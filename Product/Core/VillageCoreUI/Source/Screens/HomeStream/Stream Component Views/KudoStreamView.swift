//
//  PIAStreamView.swift
//  VillageCoreUI
//
//  Created by Jack Miller on 9/20/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit
import VillageCore

protocol KudoStreamViewDelegate: class {
    func kudoStreamView(_ view: KudoStreamView, didSelectMoreOptions kudo: Kudo)
    func kudoStreamView(_ view: KudoStreamView, didSelectPerson person: Person)
}

class KudoStreamView: NibView {
    
    // View Model
    var kudo: Kudo? {
        didSet {
            updateViewForKudo()
        }
    }
    
    // Delegate
    weak var delegate: KudoStreamViewDelegate?
    
    // Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var kudoLabel: UILabel! {
        didSet {
            kudoLabel.text = "My \(Constants.Settings.kudosSingularLong)"
        }
    }

    @IBOutlet private weak var leftImageView: UIImageView! {
        didSet {
            leftImageView.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(didSelectAvatar(gesture:)))
            leftImageView.addGestureRecognizer(tap)
        }
    }

    @IBOutlet private weak var rightImageView: UIImageView! {
        didSet {
            rightImageView.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(didSelectAvatar(gesture:)))
            rightImageView.addGestureRecognizer(tap)
        }
    }

    @IBOutlet private weak var contentLabel: UILabel!
    @IBOutlet private weak var detailsButton: UIButton!
    
    override func setupViews() {
        self.applyCardStyle()
    }

    convenience init(kudo: Kudo, delegate: KudoStreamViewDelegate? = nil) {
        self.init()
        
        self.kudo = kudo
        self.delegate = delegate

        updateViewForKudo()
    }
    
    @IBAction func moreOptions() {
        guard let kudo = self.kudo else { assertionFailure(); return }
        delegate?.kudoStreamView(self, didSelectMoreOptions: kudo)
    }

    @objc private func didSelectAvatar(gesture: UITapGestureRecognizer) {
        guard let kudo = self.kudo else {
            return
        }

        switch gesture.view {
        case leftImageView?:
            delegate?.kudoStreamView(self, didSelectPerson: kudo.sender)

        case rightImageView?:
            delegate?.kudoStreamView(self, didSelectPerson: kudo.receiver)

        default:
            break
        }
    }

    private func updateViewForKudo() {
        guard let kudo = kudo else { return }

        titleLabel.text = kudo.achievementTitle
        dateLabel.text = kudo.date.longformFormat.uppercased()
        contentLabel.text = kudo.comment
        if let senderImage = kudo.sender.avatarURL {
            leftImageView.af_setImage(withURL: senderImage)
        }
        if let receiverImage = kudo.receiver.avatarURL {
            rightImageView.af_setImage(withURL: receiverImage)
        }
    }
}
