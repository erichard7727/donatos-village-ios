//
//  GroupMenuItem.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 4/23/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit
import VillageCore

protocol GroupMenuItemDelegate: class {
    func groupMenuItem(_ item: GroupMenuItem, didSelectGroup group: VillageCore.Stream)
}

class GroupMenuItem: NibView {
    
    var stream: VillageCore.Stream? {
        didSet {
            nameLabel.text = stream?.name
        }
    }
    
    var unread: Unread.Stream? {
        didSet {
            update(with: unread?.count ?? 0)
        }
    }
    
    weak var delegate: GroupMenuItemDelegate?
    
    @IBOutlet private weak var nameLabel: UILabel!
    
    @IBOutlet private weak var unreadBadgeLabel: UILabel! {
        didSet {
            unreadBadgeLabel.layer.masksToBounds = true
            unreadBadgeLabel.layer.cornerRadius = unreadBadgeLabel.bounds.size.height / 2
            unreadBadgeLabel.isHidden = true
        }
    }
    
    private func update(with count: Int) {
        unreadBadgeLabel.text = String(count)
        unreadBadgeLabel.isHidden = count <= 0
    }
    
    @IBAction private func onTap(_ sender: Any? = nil) {
        guard let stream = self.stream else { return }
        delegate?.groupMenuItem(self, didSelectGroup: stream)
    }
    
}
