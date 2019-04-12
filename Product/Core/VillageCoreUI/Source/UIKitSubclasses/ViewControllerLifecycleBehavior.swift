//
//  ViewControllerLifecycleBehavior.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 4/11/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit

/// This protocol extension provides a way to extract certain functionality
/// or behaviors using standard UIViewController containment.
///
/// See http://irace.me/lifecycle-behaviors for more information.

protocol ViewControllerLifecycleBehavior {
    
    // Responding to View Events
    
    func afterLoading(_ viewController: UIViewController)
    
    func beforeAppearing(_ viewController: UIViewController)
    
    func afterAppearing(_ viewController: UIViewController)
    
    func beforeDisappearing(_ viewController: UIViewController)
    
    func afterDisappearing(_ viewController: UIViewController)
    
    // Configuring Layout
    
    func beforeLayingOutSubviews(_ viewController: UIViewController)
    
    func afterLayingOutSubviews(_ viewController: UIViewController)
    
    func afterUpdatingViewConstraints(_ viewController: UIViewController)
    
    // Responding to Containment Events
    
    func beforeMovingToParentViewController(_ viewController: UIViewController, parentViewController: UIViewController?)
    
    func afterMovingToParentViewController(_ viewController: UIViewController, parentViewController: UIViewController?)
    
    // Responding to Environment Changes
    
    func beforeTransitioningToSize(_ viewController: UIViewController, size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator)
    
    func beforeTransitioningToTraitCollection(_ viewController: UIViewController, newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator)
    
    // Handling Memory Warnings
    
    func afterReceivingMemoryWarning(_ viewController: UIViewController)
}

extension ViewControllerLifecycleBehavior {
    
    func afterLoading(_ viewController: UIViewController) {}
    
    func beforeAppearing(_ viewController: UIViewController) {}
    
    func afterAppearing(_ viewController: UIViewController) {}
    
    func beforeDisappearing(_ viewController: UIViewController) {}
    
    func afterDisappearing(_ viewController: UIViewController) {}
    
    func beforeLayingOutSubviews(_ viewController: UIViewController) {}
    
    func afterLayingOutSubviews(_ viewController: UIViewController) {}
    
    func afterUpdatingViewConstraints(_ viewController: UIViewController) {}
    
    func beforeMovingToParentViewController(_ viewController: UIViewController, parentViewController: UIViewController?) {}
    
    func afterMovingToParentViewController(_ viewController: UIViewController, parentViewController: UIViewController?) {}
    
    func beforeTransitioningToSize(_ viewController: UIViewController, size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {}
    
    func beforeTransitioningToTraitCollection(_ viewController: UIViewController, newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {}
    
    func afterReceivingMemoryWarning(_ viewController: UIViewController) {}
}

extension UIViewController {
    /**
     Add behaviors to be hooked into this view controller’s lifecycle.
     
     This method requires the view controller’s view to be loaded, so it’s best to call
     in `viewDidLoad` to avoid it being loaded prematurely.
     
     - parameter behaviors: Behaviors to be added.
     */
    func addBehaviors(_ behaviors: [ViewControllerLifecycleBehavior]) {
        let behaviorViewController = LifecycleBehaviorViewController(behaviors: behaviors)
        
        addChild(behaviorViewController)
        view.addSubview(behaviorViewController.view)
        behaviorViewController.didMove(toParent: self)
    }
    
    fileprivate final class LifecycleBehaviorViewController: UIViewController {
        fileprivate let behaviors: [ViewControllerLifecycleBehavior]
        
        // MARK: - Initialization
        
        init(behaviors: [ViewControllerLifecycleBehavior]) {
            self.behaviors = behaviors
            
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // MARK: - UIViewController
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            view.isHidden = true
            
            applyBehaviors { behavior, viewController in
                behavior.afterLoading(viewController)
            }
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            
            applyBehaviors { behavior, viewController in
                behavior.beforeAppearing(viewController)
            }
        }
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            
            applyBehaviors { behavior, viewController in
                behavior.afterAppearing(viewController)
            }
        }
        
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            
            applyBehaviors { behavior, viewController in
                behavior.beforeDisappearing(viewController)
            }
        }
        
        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            
            applyBehaviors { behavior, viewController in
                behavior.afterDisappearing(viewController)
            }
        }
        
        override func viewWillLayoutSubviews() {
            super.viewWillLayoutSubviews()
            
            applyBehaviors { behavior, viewController in
                behavior.beforeLayingOutSubviews(viewController)
            }
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            
            applyBehaviors { behavior, viewController in
                behavior.afterLayingOutSubviews(viewController)
            }
        }
        
        override func updateViewConstraints() {
            super.updateViewConstraints()
            
            applyBehaviors { behavior, viewController in
                behavior.afterUpdatingViewConstraints(viewController)
            }
        }
        
        override func willMove(toParent parent: UIViewController?) {
            super.willMove(toParent: parent)
            
            applyBehaviors { behavior, viewController in
                behavior.beforeMovingToParentViewController(viewController, parentViewController: parent)
            }
        }
        
        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            
            applyBehaviors { behavior, viewController in
                behavior.afterMovingToParentViewController(viewController, parentViewController: parent)
            }
        }
        
        fileprivate override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
            super.viewWillTransition(to: size, with: coordinator)
            
            applyBehaviors { behavior, viewController in
                behavior.beforeTransitioningToSize(viewController, size: size, withTransitionCoordinator: coordinator)
            }
        }
        
        fileprivate override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
            super.willTransition(to: newCollection, with: coordinator)
            
            applyBehaviors { behavior, viewController in
                behavior.beforeTransitioningToTraitCollection(viewController, newCollection: newCollection, withTransitionCoordinator: coordinator)
            }
        }
        
        override func didReceiveMemoryWarning() {
            super.didReceiveMemoryWarning()
            
            applyBehaviors { behavior, viewController in
                behavior.afterReceivingMemoryWarning(viewController)
            }
        }
        
        // MARK: - Private
        
        fileprivate func applyBehaviors(_ body: (_ behavior: ViewControllerLifecycleBehavior, _ viewController: UIViewController) -> Void) {
            guard let parentViewController = parent else { return }
            
            for behavior in behaviors {
                body(behavior, parentViewController)
            }
        }
    }
}
