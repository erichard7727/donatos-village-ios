//
//  ProgressIndicator.swift
//  VillageCoreUI
//
//  Created by Justin Munger on 7/27/16.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit

class ProgressIndicator: UIView {
    class func progressIndicatorInView(_ view: UIView) -> ProgressIndicator {
        let progressIndicator = ProgressIndicator(frame: view.bounds)
        progressIndicator.isOpaque = false
        
        view.addSubview(progressIndicator)
        view.isUserInteractionEnabled = true
        
        let activityIndicatorWidth: CGFloat = 48.0
        let activityIndicatorHeight: CGFloat = 48.0
        
        let activityIndicatorRect = CGRect(x: round((progressIndicator.bounds.size.width - activityIndicatorWidth) / 2), y: round((progressIndicator.bounds.size.height - activityIndicatorHeight) / 2), width: activityIndicatorWidth, height: activityIndicatorHeight)
        let activityIndicator = UIActivityIndicatorView(frame: activityIndicatorRect)
        activityIndicator.style = .whiteLarge
        activityIndicator.startAnimating()
        
        progressIndicator.addSubview(activityIndicator)
        
        progressIndicator.backgroundColor = UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 0.5)
        progressIndicator.alpha = 0.0
        
        return progressIndicator
    }
    
    class func progressIndicatorWithFrame(_ frame: CGRect, _ view: UIView) -> ProgressIndicator {
        let progressIndicator = ProgressIndicator(frame: frame)
        progressIndicator.isOpaque = false
        
        view.addSubview(progressIndicator)
        view.isUserInteractionEnabled = true
        
        let activityIndicatorWidth: CGFloat = 48.0
        let activityIndicatorHeight: CGFloat = 48.0
        
        let activityIndicatorRect = CGRect(x: round((progressIndicator.bounds.size.width - activityIndicatorWidth) / 2), y: round((progressIndicator.bounds.size.height - activityIndicatorHeight) / 2), width: activityIndicatorWidth, height: activityIndicatorHeight)
        let activityIndicator = UIActivityIndicatorView(frame: activityIndicatorRect)
        activityIndicator.style = .whiteLarge
        activityIndicator.startAnimating()
        
        progressIndicator.addSubview(activityIndicator)
        
        progressIndicator.backgroundColor = UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 0.5)
        progressIndicator.alpha = 0.0
        
        return progressIndicator
    }
    
    override func draw(_ rect: CGRect) {
        let indicatorWidth: CGFloat = 96.0
        let indicatorHeight: CGFloat = 96.0
        
        let indicatorRect = CGRect(x: round((bounds.size.width - indicatorWidth) / 2), y: round((bounds.size.height - indicatorHeight) / 2), width: indicatorWidth, height: indicatorHeight)
        
        let roundedRect = UIBezierPath(roundedRect: indicatorRect, cornerRadius: 10.0)
        
        UIColor(white: 0.3, alpha: 0.8).setFill()
        roundedRect.fill()
    }
    
    func show() {
        alpha = 0.0
        
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 1.0
        })
    }
    
    func hide() {
        alpha = 1.0
        
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0.0
        })
    }
    
    var showing: Bool {
        get {
            return alpha == 1.0
        }
    }
}
