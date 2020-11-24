//
//  NavBarDisplayable.swift
//  VillageCoreUI
//
//  Created by Scott Harman on 7/1/20.
//  Copyright © 2020 Dynamit. All rights reserved.
//

import Foundation


protocol NavBarDisplayable: AnyObject {
    func setTransparentNavbarAppearance(for navigationItem: UINavigationItem, in navigationController: UINavigationController?)
    func setOpaqueNavbarAppearance(for navigationItem: UINavigationItem, in navigationController: UINavigationController?)
}

extension NavBarDisplayable {
    
    func setTransparentNavbarAppearance(for navigationItem: UINavigationItem, in navigationController: UINavigationController?) {
        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithTransparentBackground()
            navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            navigationItem.standardAppearance = navBarAppearance
            navigationItem.scrollEdgeAppearance = navBarAppearance
        } else {
            navigationController?.navigationBar.isTranslucent = true
            navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController?.navigationBar.shadowImage = UIImage()
        }
    }
    
    func setOpaqueNavbarAppearance(for navigationItem: UINavigationItem, in navigationController: UINavigationController?) {
        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            navBarAppearance.backgroundColor = .vlgRed
            navigationItem.standardAppearance = navBarAppearance
            navigationItem.scrollEdgeAppearance = navBarAppearance
        } else {
            navigationController?.navigationBar.isTranslucent = false
            navigationController?.navigationBar.barTintColor = .vlgRed
        }
    }
}
