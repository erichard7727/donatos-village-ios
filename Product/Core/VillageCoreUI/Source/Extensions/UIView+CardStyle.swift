//
//  UIView+CardStyle.swift
//  VillageCoreUI
//
//  Created by Jack Miller on 9/23/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit

extension UIView {
    
    func applyCardStyle() {
        self.layer.cornerRadius = 5.0
        
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        self.layer.shadowRadius = 3.0
        self.layer.shadowOpacity = 0.2
        self.layer.masksToBounds = false
        
        if let nibSelf = self as? NibView {
            nibSelf.view.layer.cornerRadius = 5.0
            nibSelf.view.layer.masksToBounds = true
        }
    }
}


class CardStyleView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configureView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configureView()
    }
    
    private func configureView() {
        self.applyCardStyle()
    }
}
