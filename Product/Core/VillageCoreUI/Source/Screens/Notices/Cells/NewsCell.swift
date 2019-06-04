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
    
    @IBOutlet private var loadingIndicator: UIActivityIndicatorView!
    
    func setLoading(_ isLoading: Bool) {
        let oldValue = loadingIndicator.isAnimating
        if isLoading {
            newsImageView.isHidden = true
            loadingIndicator.startAnimating()
        } else {
            newsImageView.isHidden = false
            loadingIndicator.stopAnimating()
        }
        if oldValue != isLoading {
            _accessibilityElements = nil
            UIAccessibility.post(notification: .layoutChanged, argument: self.contentView)
        }
    }
    
    var newsId: String = "-1"
    
    var thumbnailImageURL: URL? {
        didSet {
            if let url = thumbnailImageURL {
                self.newsImageView.af_setImage(
                    withURL: url,
                    placeholderImage: UIImage.named("default-notice-header")!,
                    filter: AspectScaledToFillSizeFilter(
                        size: self.newsImageView.frame.size
                    )
                )
            } else {
                self.configureCellAttachment(UIImage.named("default-notice-header")!)
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        newsImageView.backgroundColor = UIColor.vlgGray
        newsImageView.image = nil
    }
    
    func configureCellAttachment(_ attachmentImage: UIImage) {
        UIView.transition(with: newsImageView, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.newsImageView.image = attachmentImage
            self.newsImageView.clipsToBounds = true
            self.newsImageView.backgroundColor = UIColor.vlgGray
            self.setNeedsLayout()
        }, completion: nil)
    }
    
    override var accessibilityElements: [Any]? {
        get {
            if _accessibilityElements == nil {
                let element = UIAccessibilityElement(accessibilityContainer: self)
                element.accessibilityFrameInContainerSpace = self.bounds
                
                if loadingIndicator.isAnimating {
                    element.accessibilityLabel = "Loading News"
                    element.accessibilityTraits = [.staticText]
                } else {
                    var author: String?
                    if let name = newsAuthorLabel.text, !name.isEmpty {
                        author = "By \(name)"
                    }
                    element.accessibilityLabel = [newsTitleLabel.text, author]
                        .compactMap({ $0 })
                        .joined(separator: ", ")
                    if isSelected {
                        element.accessibilityTraits.formUnion([.selected])
                    }
                }
                _accessibilityElements = [element]
            }
            return _accessibilityElements!
        }
        set { }
    }
    
    private var _accessibilityElements: [Any]?
    
}
