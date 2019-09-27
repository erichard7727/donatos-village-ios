//
//  NoticeStreamView.swift
//  VillageCoreUI
//
//  Created by Jack Miller on 9/23/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit
import VillageCore

protocol NoticeStreamViewDelegate: class {
    func noticeStreamView(_ view: NoticeStreamView, didSelectNotice notice: Notice)
}

class NoticeStreamView: NibView {
    
    // View Model
    var notice: Notice?
    
    // Delegate
    weak var delegate: NoticeStreamViewDelegate?
    
    // Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var messageLabel: UILabel!
    
    
    convenience init(notice: Notice, delegate: NoticeStreamViewDelegate? = nil) {
        self.init()
        
        self.notice = notice
        self.delegate = delegate
        
        titleLabel.text = notice.title
        dateLabel.text = notice.publishDate.longformFormat.uppercased()
        
        // set html content
        messageLabel.setHTMLFromString(text: notice.bodyContent)
    }
    
    override func setupViews() {
        self.applyCardStyle()
    }

    @IBAction func seeDetails() {
        guard let notice = notice else { assertionFailure(); return }
        delegate?.noticeStreamView(self, didSelectNotice: notice)
    }
}
