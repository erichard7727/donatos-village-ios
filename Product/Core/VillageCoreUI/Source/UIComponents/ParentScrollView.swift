//
//  ParentScrollView.swift
//  VillageCoreUI
//
//  Created by Tim Lemaster on 5/22/17.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit

public class ParentScrollView: UIScrollView {
    
    public var childScrollView: UIScrollView? {
        didSet {
            childScrollView?.isScrollEnabled = false
        }
    }
    
    fileprivate var observeContentOffsetChanges = true
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        setupKVO()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupKVO()
    }
    
    deinit {
        removeObserver(self, forKeyPath: #keyPath(UIScrollView.contentOffset))
    }
    
    private func setupKVO() {
        addObserver(self, forKeyPath: #keyPath(UIScrollView.contentOffset), options: [.new, .old], context: nil)
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let scrollView = object as? UIScrollView,
            let childScrollView = childScrollView,
            let new = change?[.newKey] as? CGPoint,
            let old = change?[.oldKey] as? CGPoint,
            observeContentOffsetChanges else { return }
        
        
        let delta = new.y - old.y
        
        var updateChildScrollView = false
        
        let childContentOffset = childScrollView.contentOffset
        
        if new.y + scrollView.bounds.height > scrollView.contentSize.height
            && delta > 0.0
            && childContentOffset.y + delta + childScrollView.bounds.height < childScrollView.contentSize.height {
            updateChildScrollView = true
        } else if childContentOffset.y > 0
            && delta < 0.0
            && new.y + scrollView.bounds.height < scrollView.contentSize.height {
            updateChildScrollView = true
        }
        
        if updateChildScrollView {
            observeContentOffsetChanges = false
            
            let proposedChildScrollViewY = childContentOffset.y + delta
            
            scrollView.contentOffset = old
            
            childScrollView.contentOffset = CGPoint(x: childContentOffset.x, y: proposedChildScrollViewY)
            
            observeContentOffsetChanges = true
        }
    }
}
