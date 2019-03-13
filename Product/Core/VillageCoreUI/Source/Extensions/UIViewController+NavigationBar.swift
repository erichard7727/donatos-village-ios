//
//  UIViewController+NavigationBar.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 3/1/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func vlg_setNavigationBarBackgroundVisible(_ makeVisible: Bool, animated: Bool) {
        let updateNavBarAppearance = { [weak self] in
            if makeVisible {
                self?.navigationController?.navigationBar.isTranslucent = false
                self?.navigationController?.navigationBar.barTintColor = .white
                self?.navigationController?.navigationBar.tintColor = .black
            } else {
                self?.navigationController?.navigationBar.isTranslucent = true
                self?.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
                self?.navigationController?.navigationBar.shadowImage = UIImage()
                self?.navigationController?.navigationBar.tintColor = .white
            }
            self?.navigationController?.navigationBar.layoutIfNeeded()
        }
        if animated {
            UIView.animate(withDuration: 0.1) {
                updateNavBarAppearance()
            }
        } else {
            updateNavBarAppearance()
        }
    }
    
}
