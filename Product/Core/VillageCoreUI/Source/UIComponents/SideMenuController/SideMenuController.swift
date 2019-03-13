//
//  SideMenuController.swift
//  SideMenuController
//
//  Created by Jack Miller on 4/3/18.
//  Copyright © 2018 Dynamit. All rights reserved.
//

import UIKit

public extension Notification.Name {
    static let sideMenuDidShow = Notification.Name("sideMenuDidShow")
    static let sideMenuDidHide = Notification.Name("sideMenuDidHide")
}

public class SideMenuController: UIViewController, UIGestureRecognizerDelegate {
    
    //Public Config Vars
    public var animationDuration: TimeInterval = 0.3
    
    public var openMenuProportionalWidth: CGFloat = 0.72
    public var openMenuMinimumWidth: CGFloat = 200.0
    public var openMenuContentScaledFactor: CGFloat = 0.85
    
    public var leftEdgeGestureTolerance: CGFloat = 10.0
    
    public var panGestureEnabled: Bool = true {
        didSet {
            if panGestureEnabled {
                panGesture = UIPanGestureRecognizer(target: self, action: #selector(SideMenuController.onPan(gesture:)))
                panGesture.delegate = self
                self.view.addGestureRecognizer(panGesture)
            } else {
                self.view.removeGestureRecognizer(panGesture)
                panGesture.delegate = nil
            }
        }
    }
    
    
    private var openMenuActualWidth: CGFloat {
        return max(openMenuMinimumWidth,self.view.frame.width * openMenuProportionalWidth)
    }
    
    private var menuPresentationTransform: CGAffineTransform {
        let transform = CGAffineTransform(translationX: openMenuActualWidth, y: 0.0).scaledBy(x: openMenuContentScaledFactor, y: openMenuContentScaledFactor)
        return transform
    }
    
    private(set) var menuViewController: UIViewController?
    private(set) var contentViewController: UIViewController?
    
    private var menuContainerView: UIView = UIView()
    private var contentContainerView: UIView = UIView()
    
    private var closeMenuTapOverlay: UIButton = UIButton()
    private var panGesture: UIPanGestureRecognizer = UIPanGestureRecognizer()
    
    private var menuIsVisible: Bool = false
    
    private var originalSafeArea: UIEdgeInsets?
    
    //MARK: Initializers
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    public required init(menuViewController: UIViewController, contentViewController: UIViewController) {
        super.init(nibName: nil, bundle: nil)
        self.menuViewController = menuViewController
        self.contentViewController = contentViewController
        self.commonInit()
    }
    
    private func commonInit() {
//        self.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.menuContainerView.frame = self.view.bounds
        self.menuContainerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(menuContainerView)
        
        self.contentContainerView.frame = self.view.bounds
        self.contentContainerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(contentContainerView)
        
        if let menuViewController = self.menuViewController {
            self.setMenuViewController(menuViewController)
        }
        
        if let contentViewController = self.contentViewController {
            self.setContentViewController(contentViewController)
        }
        
        closeMenuTapOverlay.addTarget(self, action: #selector(SideMenuController.hideMenu), for: .touchUpInside)
        closeMenuTapOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        closeMenuTapOverlay.tag = 991
        
        //Content Shadow
        contentContainerView.layer.shadowColor = UIColor.black.cgColor
        contentContainerView.layer.shadowOpacity = 0.2
        contentContainerView.layer.shadowOffset = .zero
        contentContainerView.layer.shadowRadius = 5.0
        
        self.panGestureEnabled = true
    }
    
    //MARK: Public Functions
    
    public func setMenuViewController(_ newMenuViewController: UIViewController) {
        self.switchViewController(from: self.menuViewController, to: newMenuViewController, inContainer: self.menuContainerView)
        self.menuViewController = newMenuViewController
    }
    
    public func setContentViewController(_ newContentViewController: UIViewController, fadeAnimation: Bool = false) {
        self.switchViewController(from: self.contentViewController, to: newContentViewController, inContainer: self.contentContainerView, animated: fadeAnimation)
        self.contentViewController = newContentViewController
    }
    
    public func showMenu() {
        //Need the tasks to be split so we can call 'begin' when a pan gesture starts and 'finish' when it completes
        self.beginShowMenu()
        self.finishShowMenu()
    }
    
    ///Sets things up for showing the menu - called when showMenu() is called or when a pan gesture begins
    private func beginShowMenu() {
        guard let menuViewController = self.menuViewController else { assertionFailure("menu view controller is not set"); return }
        
        self.alertDelegatesWillShow()
        
        if #available(iOS 11.0, *) {
            originalSafeArea = contentViewController?.view.safeAreaInsets
        }
        
        menuViewController.beginAppearanceTransition(true, animated: true)
        self.view.window?.endEditing(true)
    }
    
    ///Shows the actual animation to display the menu and completion tasks. Called from showMenu() or when a pan gesture finishes
    private func finishShowMenu() {
        guard let menuViewController = self.menuViewController else { assertionFailure("menu view controller is not set"); return }
        
        closeMenuTapOverlay.frame = contentContainerView.bounds
        contentContainerView.addSubview(closeMenuTapOverlay)
        
        UIView.animate(withDuration: animationDuration, delay: 0.0, options: [.beginFromCurrentState, .curveEaseOut], animations: {
            self.contentContainerView.transform = self.menuPresentationTransform
            self.performChildViewControllerAnimations(showing: true)
            
            if #available(iOS 11.0, *) {
                if let contentViewController = self.contentViewController, let originalSafeArea = self.originalSafeArea {
                    contentViewController.additionalSafeAreaInsets = originalSafeArea.minus(contentViewController.view.safeAreaInsets)
                }
            }
            
        }) { (_) in
            self.menuIsVisible = true
            menuViewController.endAppearanceTransition()
            self.alertDelegatesDidShow()
            NotificationCenter.default.post(name: .sideMenuDidShow, object: self)
            
            if #available(iOS 11.0, *) {
                if let contentViewController = self.contentViewController, let originalSafeArea = self.originalSafeArea {
                    contentViewController.additionalSafeAreaInsets = .zero
                    contentViewController.additionalSafeAreaInsets = originalSafeArea.minus(contentViewController.view.safeAreaInsets)
                }
            }
            
            
        }
    }
    
    @objc func hideMenu() {
        self.beginHideMenu()
        self.finishHideMenu()
    }
    
    private func beginHideMenu() {
        guard let menuViewController = self.menuViewController else { assertionFailure("menu view controller is not set"); return }
        
        self.alertDelegatesWillHide()
        
        menuViewController.beginAppearanceTransition(true, animated: true)
        self.view.window?.endEditing(true)
    }
    
    private func finishHideMenu() {
        guard let menuViewController = self.menuViewController else { assertionFailure("menu view controller is not set"); return }
        
        closeMenuTapOverlay.removeFromSuperview()
        
        UIView.animate(withDuration: animationDuration, delay: 0.0, options: [.beginFromCurrentState, .curveEaseOut], animations: {
            self.contentContainerView.transform = .identity
            self.performChildViewControllerAnimations(showing: false)
            
            if #available(iOS 11.0, *) {
                self.contentViewController?.additionalSafeAreaInsets = .zero
            }
        }) { (_) in
            self.menuIsVisible = false
            menuViewController.endAppearanceTransition()
            self.alertDelegatesDidHide()
            NotificationCenter.default.post(name: .sideMenuDidHide, object: self)
        }
    }
    
}

//MARK: - Pan Gesture Delegate
extension SideMenuController {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer == self.panGesture {
            if !menuIsVisible {
                return touch.location(in: gestureRecognizer.view).x < leftEdgeGestureTolerance
            }
            else {
                return touch.location(in: gestureRecognizer.view).x > openMenuActualWidth - leftEdgeGestureTolerance
            }
        }
        return false
    }
    
    @objc private func onPan(gesture: UIPanGestureRecognizer) {
        guard panGestureEnabled else { return }
        
        let translation = gesture.translation(in: gesture.view)
        
        
        let startingScaleValue: CGFloat = menuIsVisible ? openMenuContentScaledFactor : 1
        let totalScaleChange: CGFloat = 1 - openMenuContentScaledFactor
        let percentComplete = min(1,abs(translation.x / openMenuActualWidth))
        let newScaleChangeValue: CGFloat = totalScaleChange * percentComplete
        
        var scale: CGFloat = 0.0
        var horizontalTranslation: CGFloat = 0.0
        
        if !menuIsVisible {
            scale = max(openMenuContentScaledFactor, startingScaleValue - newScaleChangeValue)
            horizontalTranslation = min(max(0, translation.x),openMenuActualWidth)
        }
        else {
            scale = max(openMenuContentScaledFactor, startingScaleValue + newScaleChangeValue)
            horizontalTranslation = max(0,min(openMenuActualWidth, openMenuActualWidth + translation.x))
        }
        
        //calculate new safe area for animation
        var additionalSafeArea: UIEdgeInsets = .zero
        
        if #available(iOS 11.0, *) {
            contentViewController?.additionalSafeAreaInsets = .zero
            if let originalSafeArea = originalSafeArea, let currentContentSafeArea = contentViewController?.view.safeAreaInsets {
                let changeInSafeArea = originalSafeArea.minus(currentContentSafeArea)
                additionalSafeArea = changeInSafeArea
            }
        }
        
        switch gesture.state {
        case .began:
            menuIsVisible ? self.beginHideMenu() : self.beginShowMenu()
            self.contentContainerView.transform = CGAffineTransform(translationX: horizontalTranslation, y: 0).scaledBy(x: scale, y: scale)
            if #available(iOS 11.0, *) {
                self.contentViewController?.additionalSafeAreaInsets = additionalSafeArea
            }
        case .changed:
            self.contentContainerView.transform = CGAffineTransform(translationX: horizontalTranslation, y: 0).scaledBy(x: scale, y: scale)
            if #available(iOS 11.0, *) {
                self.contentViewController?.additionalSafeAreaInsets = additionalSafeArea
            }
        case .ended:
            if !menuIsVisible {
                translation.x > 20 ? self.finishShowMenu() : self.finishHideMenu()
            } else {
                translation.x > -10 ? self.finishShowMenu() : self.finishHideMenu()
            }
        default:
            self.hideMenu()
        }
    }
}

//MARK: - Helpers for Handling Child ViewControllers
extension SideMenuController {
    
    private func switchViewController(from fromViewController: UIViewController?, to toViewController: UIViewController, inContainer container: UIView, animated: Bool = false) {
        if animated {
            self.transitionToChildViewController(toViewController, inContainer: container, animated: true)
        } else {
            if let fromViewController = fromViewController {
                self.removeViewController(fromViewController)
            }
            self.addViewController(toViewController, container: container)
        }
    }
    
    private func removeViewController(_ viewController: UIViewController) {
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
    
    private func addViewController(_ viewController: UIViewController, container: UIView) {
        self.addChild(viewController)
        viewController.view.frame = container.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(viewController.view)
        viewController.didMove(toParent: self)
    }
}

//MARK: - Helpers for Crawling ViewController Hierarchy
extension SideMenuController {
    
    private func alertDelegatesWillShow() {
        self.callDelegates { [weak self] delegate in
            guard let strongSelf = self else { return }
            delegate.sideMenuWillShow(sideMenuController: strongSelf)
        }
    }
    
    private func alertDelegatesDidShow() {
        self.callDelegates { [weak self] delegate in
            guard let strongSelf = self else { return }
            delegate.sideMenuDidShow(sideMenuController: strongSelf)
        }
    }
    
    private func alertDelegatesWillHide() {
        self.callDelegates { [weak self] delegate in
            guard let strongSelf = self else { return }
            delegate.sideMenuWillHide(sideMenuController: strongSelf)
        }
    }
    
    private func alertDelegatesDidHide() {
        self.callDelegates { [weak self] delegate in
            guard let strongSelf = self else { return }
            delegate.sideMenuDidHide(sideMenuController: strongSelf)
        }
    }
    
    private func callDelegates(block: (SideMenuControllerDelegate) -> Void) {
        crawlForDelegates(viewController: self, block: block)
    }
    
    private func crawlForDelegates(viewController: UIViewController, block: (SideMenuControllerDelegate) -> Void) {
        for child in subViewControllers(for: viewController) {
            if let menuDelegate = child as? SideMenuControllerDelegate {
                block(menuDelegate)
            }
            crawlForDelegates(viewController: child, block: block)
        }
    }
    
    private func performChildViewControllerAnimations(showing: Bool) {
        crawlChildAnimationBlocks(viewController: self, showing: showing)
    }
    
    private func crawlChildAnimationBlocks(viewController: UIViewController, showing: Bool) {
        for child in subViewControllers(for: viewController) {
            if let menuDelegate = child as? SideMenuControllerDelegate {
                showing ? menuDelegate.showMenuAnimations?() : menuDelegate.hideMenuAnimations?()
            }
            self.crawlChildAnimationBlocks(viewController: child, showing: showing)
        }
    }
    
    private func subViewControllers(for viewController: UIViewController) -> [UIViewController] {
        
        if let navController = viewController as? UINavigationController {
            return navController.viewControllers
        }
        if let tabController = viewController as? UITabBarController {
            return tabController.viewControllers ?? []
        }
        
        return viewController.children
    }
}

extension UIEdgeInsets {
    
    func minus(_ edgeInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets(top: self.top - edgeInsets.top, left: self.left - edgeInsets.left, bottom: self.bottom - edgeInsets.bottom, right: self.right - edgeInsets.right)
    }
    
    func plus(_ edgeInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets(top: self.top + edgeInsets.top, left: self.left + edgeInsets.left, bottom: self.bottom + edgeInsets.bottom, right: self.right + edgeInsets.right)
    }
}
