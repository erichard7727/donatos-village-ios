//
//  NoticeStreamView.swift
//  VillageCoreUI
//
//  Created by Jack Miller on 9/23/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit
import VillageCore

class NoticeStreamView: NibView {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var messageLabel: UILabel!
    
    convenience init(notice: Notice) {
        self.init()
        
        titleLabel.text = notice.title
        dateLabel.text = notice.publishDate.longformFormat.uppercased()
        
        // set html content
        messageLabel.setHTMLFromString(text: notice.bodyContent)
    }

}
