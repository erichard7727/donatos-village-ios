//
//  AccommodatesKeyboardBehavior.swift
//  VillageContainerApp
//
//  Created by Rob Feldmann on 4/6/17.
//  Copyright © 2017 Dynamit. All rights reserved.
//

import UIKit

/// Methods and properties for a class that can expand when the keyboard is visible
protocol KeyboardExpandable: class {
    var scrollView: UIScrollView? { get }
    var keyboardObservers: [NSObjectProtocol]? { get set }
    func keyboardWillShow(_ notification: Notification)
    func keyboardWillHide(_ notification: Notification)
}

/// Default implementation of KeyboardExpandable for UIViewControllers
extension KeyboardExpandable where Self: UIViewController {
    
    func keyboardWillShow(_ notification: Notification) {
        guard let info = notification.userInfo,
            let kbSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size,
            let scrollView = self.scrollView else {
                return
        }
        
        // Expand the scrollView's contentInset to make room for the displaying keyboard
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: kbSize.height, right: 0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }
    
    func keyboardWillHide(_ notification: Notification) {
        scrollView?.contentInset = UIEdgeInsets.zero
        scrollView?.scrollIndicatorInsets = UIEdgeInsets.zero
    }
    
}

/// Behavior which automatically registers for keyboard notifications and expands the
/// scrollView to make room for the keyboard
struct AccommodatesKeyboardBehavior: ViewControllerLifecycleBehavior {
    
    func beforeAppearing(_ viewController: UIViewController) {
        if let vc = viewController as? KeyboardExpandable {
            let notificationCenter = NotificationCenter.default
            vc.keyboardObservers = [
                notificationCenter.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil, using: {
                    [weak vc] notification in
                    vc?.keyboardWillShow(notification)
                }),
                notificationCenter.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil, using: {
                    [weak vc] notification in
                    vc?.keyboardWillHide(notification)
                }),
            ]
        } else {
            assertionFailure("\(String(describing: type(of: viewController))) adopting AccomodatesKeyboardBehavior must conform to KeyboardExpandable protocol")
        }
    }
    
    func beforeDisappearing(_ viewController: UIViewController) {
        if let vc = viewController as? KeyboardExpandable,
            let keyboardObservers = vc.keyboardObservers {
            let notificationCenter = NotificationCenter.default
            for keyboardObserver in keyboardObservers {
                notificationCenter.removeObserver(keyboardObserver)
            }
        }
    }
    
}
