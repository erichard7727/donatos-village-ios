//
//  UIViewController+SimpleTransition.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 2/10/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func transition(to child: UIViewController, completion: ((Bool) -> Void)? = nil) {
        let duration = 0.3
        
        let current = children.last
        addChild(child)
        
        let newView = child.view!
        newView.translatesAutoresizingMaskIntoConstraints = true
        newView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        newView.frame = view.bounds
        
        if let existing = current {
            existing.willMove(toParent: nil)
            
            transition(from: existing, to: child, duration: duration, options: [.transitionCrossDissolve], animations: { }, completion: { done in
                existing.removeFromParent()
                child.didMove(toParent: self)
                completion?(done)
            })
            
        } else {
            view.addSubview(newView)
            
            UIView.animate(withDuration: duration, delay: 0, options: [.transitionCrossDissolve], animations: { }, completion: { done in
                child.didMove(toParent: self)
                completion?(done)
            })
        }
    }
    
    func transitionToChildViewController(_ child: UIViewController, inContainer containerView: UIView, animated: Bool) {
        
        //check if there is currently a viewcontroller in this container
        if let currentViewController = self.children.filter({ containerView.subviews.contains($0.view) }).first {
            
            if animated {
                //vc already exists in this container, animate the switch
                
                currentViewController.willMove(toParent: nil)
                
                self.addChild(child)
                child.view.frame = containerView.bounds
                child.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                child.view.alpha = 0.0
                containerView.addSubview(child.view)
                
                UIView.animate(withDuration: 0.2, animations: {
                    child.view.alpha = 1.0
                }) { _ in
                    currentViewController.view.removeFromSuperview()
                    currentViewController.removeFromParent()
                    child.didMove(toParent: self)
                }
            } else {
                //remove current vc
                currentViewController.willMove(toParent: nil)
                currentViewController.view.removeFromSuperview()
                currentViewController.removeFromParent()
                
                //embed new vc
                self.embedChildViewController(child, inContainer: containerView)
            }
        } else {
            //not currently a vc embedded in this container - can't animate a change, just embed
            self.embedChildViewController(child, inContainer: containerView)
        }
        
    }
    
    func embedChildViewController(_ child: UIViewController, inContainer containerView: UIView) {
        self.addChild(child)
        child.view.frame = containerView.bounds
        child.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(child.view)
        child.didMove(toParent: self)
    }
    
    /// A convienence function for adding a child viewController to
    /// a parent using ViewController containment APIs
    ///
    /// - Parameter child: the child view controller to add to the recipient
    func add(_ child: UIViewController) {
        addChild(child)
        view.addSubview(child.view)
        child.didMove(toParent: self)
    }
    
    /// A convienence function for removing the child viewController from
    /// its parent using ViewController containment APIs
    func remove() {
        guard parent != nil else { return }
        willMove(toParent: nil)
        removeFromParent()
        view.removeFromSuperview()
    }
    
}
