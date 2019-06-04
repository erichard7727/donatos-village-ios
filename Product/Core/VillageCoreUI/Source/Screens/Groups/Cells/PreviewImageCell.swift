//
//  PreviewImageCell.swift
//  VillageContainerApp
//
//  Created by Russell Stephenson on 2/23/17.
//  Copyright © 2017 Dynamit. All rights reserved.
//

import UIKit

class PreviewImageCell: UITableViewCell {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    var previewImageView = UIImageView()
    var longTap: (() -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 6.0
        scrollView.delegate = self
        
        previewImageView.contentMode = .scaleAspectFit
    }
    
    func configureCellAnimatedAttachment(_ attachmentImage: UIImage) {
        UIView.transition(with: scrollView, duration: 0.25, options: .transitionCrossDissolve, animations: {
            
            self.previewImageView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 350)
            self.previewImageView.setAnimatedImage(animatedImage: attachmentImage)
            
            self.scrollView.contentSize = self.previewImageView.frame.size
            self.scrollView.addSubview(self.previewImageView)
            
            self.previewImageView.playAnimatedImage()
        }, completion: nil)
    }
    
    func configureCellAttachment(_ attachmentImage: UIImage, _ contentId: String) {
        UIView.transition(with: scrollView, duration: 0.25, options: .transitionCrossDissolve, animations: {
            let height = (UIScreen.main.bounds.width * attachmentImage.size.height) / attachmentImage.size.width
            
            self.previewImageView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: height)
            self.previewImageView.image = attachmentImage
            self.previewImageView.isUserInteractionEnabled = true
            
            let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.imageHeld(longPressGestureRecognizer:)))
            gestureRecognizer.minimumPressDuration = 0.5
            self.previewImageView.addGestureRecognizer(gestureRecognizer)
            
            self.scrollView.contentSize = self.previewImageView.frame.size
            self.scrollView.addSubview(self.previewImageView)
        }, completion: nil)
    }
    
    @objc func imageHeld(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        longTap?()
    }
}

extension PreviewImageCell: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.previewImageView
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) { }
}
