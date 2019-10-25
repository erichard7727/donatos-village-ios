//
//  UIViewController+BadSwizzleStuff.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 10/25/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//
//  Source: https://github.com/kickstarter/ios-oss/blob/master/Library/DataSource/UIView-Extensions.swift

import UIKit

private func swizzle(_ v: UIViewController.Type) {

    let methodsToSwizzle: [(Selector, Selector)] = [
        // Replace `viewDidLoad` so that we can disable large
        // titles application-wide if needed.
        (#selector(v.viewDidLoad), #selector(v.vlg_viewDidLoad)),
    ]

    methodsToSwizzle.forEach { original, swizzled in
        guard
            let originalMethod = class_getInstanceMethod(v, original),
            let swizzledMethod = class_getInstanceMethod(v, swizzled)
        else { return }

        let didAddViewDidLoadMethod = class_addMethod(
            v,
            original,
            method_getImplementation(swizzledMethod),
            method_getTypeEncoding(swizzledMethod)
        )

        if didAddViewDidLoadMethod {
            class_replaceMethod(
                v,
                swizzled,
                method_getImplementation(originalMethod),
                method_getTypeEncoding(originalMethod)
            )
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}

private var hasSwizzled = false

extension UIViewController {

    public final class func doBadSwizzleStuff() {
        guard !hasSwizzled else { return }

        hasSwizzled = true
        swizzle(self)
    }

    @objc internal func vlg_viewDidLoad() {
        if Constants.Settings.disableLargeTitles {
            navigationItem.largeTitleDisplayMode = .never
        }

        navigationItem.hidesSearchBarWhenScrolling = Constants.Settings.hidesSearchBarWhenScrolling

        self.vlg_viewDidLoad()
    }
}
