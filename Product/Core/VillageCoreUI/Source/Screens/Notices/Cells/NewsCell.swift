//
//  NewsCell.swift
//  VillageContainerApp
//
//  Created by Russell Stephenson on 11/11/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit
import AlamofireImage

class NewsCell: UITableViewCell {
    @IBOutlet weak var newsImageView: UIImageView!
    @IBOutlet weak var newsTitleLabel: UILabel!
    @IBOutlet weak var newsAuthorLabel: UILabel!
    @IBOutlet weak var newsDescriptionLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var newsId: String = "-1"
    
    var thumbnailImageURL: URL? {
        didSet {
            if let url = thumbnailImageURL {
                self.newsImageView.af_setImage(
                    withURL: url,
                    placeholderImage: UIImage.named("default-notice-header")!,
                    filter: AspectScaledToFillSizeFilter(
                        size: self.newsImageView.frame.size
                    ),
                    completion: { [weak self] result in
                        self?.activityIndicator.stopAnimating()
                        self?.activityIndicator.alpha = 0
                    }
                )
            } else {
                self.configureCellAttachment(UIImage.named("default-notice-header")!)
                self.activityIndicator.stopAnimating()
                self.activityIndicator.alpha = 0
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        newsImageView.backgroundColor = UIColor.vlgGray
        newsImageView.image = nil
        self.activityIndicator.alpha = 0
    }
    
    func configureCellAttachment(_ attachmentImage: UIImage) {
        UIView.transition(with: newsImageView, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.newsImageView.image = attachmentImage
            self.newsImageView.clipsToBounds = true
            self.newsImageView.backgroundColor = UIColor.vlgGray
            self.activityIndicator.stopAnimating()
            self.activityIndicator.alpha = 0
            self.setNeedsLayout()
        }, completion: nil)
    }
}
