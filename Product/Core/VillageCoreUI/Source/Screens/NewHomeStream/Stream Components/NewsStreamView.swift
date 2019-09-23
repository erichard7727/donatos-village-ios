//
//  NewsStreamView.swift
//  VillageCoreUI
//
//  Created by Jack Miller on 9/20/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit
import VillageCore
import Alamofire
import AlamofireImage

class NewsStreamView: NibView {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var contentLabel: UILabel!
    @IBOutlet private weak var readMoreButton: UIButton!
    
    override func setupViews() {
        self.applyCardStyle()
    }
    
    convenience init(news: Notice) {
        self.init()
        
        titleLabel.text = news.title
        dateLabel.text = news.publishDate.longformFormat.uppercased()
        
        // set html content
        contentLabel.setHTMLFromString(text: news.bodyContent)
        
        if let imageUrl = news.mediaAttachments.first(where: { $0.isThumbnailImage })?.url {
            Alamofire.DataRequest.addAcceptableImageContentTypes(["binary/octet-stream"])
            imageView.af_setImage(withURL: imageUrl)
        }
    }
}

