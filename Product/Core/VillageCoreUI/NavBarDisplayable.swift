//
//  NavBarDisplayable.swift
//  VillageCoreUI
//
//  Created by Scott Harman on 7/1/20.
//  Copyright © 2020 Dynamit. All rights reserved.
//

import Foundation


protocol NavBarDisplayable {
    func setNavbarAppearance(for navigationItem: UINavigationItem)
}

extension NavBarDisplayable {
    
    func setNavbarAppearance(for navigationItem: UINavigationItem) {
        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            navBarAppearance.backgroundColor = .vlgRed
            navigationItem.standardAppearance = navBarAppearance
            navigationItem.scrollEdgeAppearance = navBarAppearance
        }
    }
    
}
