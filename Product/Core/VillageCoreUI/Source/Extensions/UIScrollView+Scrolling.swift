//
//  UIScrollView+Scrolling.swift
//  VillageCoreUI
//
//  Created by Nikola Angelkovik on 12/21/20.
//  Copyright © 2020 Dynamit. All rights reserved.
//

import UIKit

extension UIScrollView {
    
    func scrollToBottom(animated: Bool = true) {
        let inset = contentInset
        let contentHeight = contentSize.height
        let viewportHeight = bounds.height
        let offset = contentHeight - inset.bottom + inset.top - viewportHeight
        setContentOffset(CGPoint(x: contentOffset.x, y: offset), animated: animated)
    }
}
