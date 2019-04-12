//
//  MenuButtonBehavior.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 4/11/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit

/// Behavior adding a menu button as the left navigation item.
/// NOTE: Requires -menuButtonPressed: to be implemented.
class MenuButtonBehavior: ViewControllerLifecycleBehavior {
    func afterLoading(_ viewController: UIViewController) {
        // Load menu image as templated image.
        let menuImage = UIImage.named("menu-icon")
        let menuTemplateImage = menuImage?.withRenderingMode(.alwaysTemplate)
        
        // Add to navigation item.
        viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(image: menuTemplateImage,
                                                                          style: .plain,
                                                                          target: viewController,
                                                                          action: #selector(UIViewController.menuButtonPressed(_:)))
    }
}

/// Behavior adding a menu, or back, button as the left navigation item based on current navigation controller stack.
/// NOTE: Requires -backButtonPressed: and -menuButtonPressed: to be implemented.
class MenuOrBackButtonBehavior: ViewControllerLifecycleBehavior {
    
    func beforeAppearing(_ viewController: UIViewController) {
        /// Set up left menu button depending on navigation controller stack.
        let menuTemplateImage: UIImage
        let selector: Selector
        
        if (viewController.navigationController?.viewControllers ?? []).count > 1 {
            let menuImage = UIImage.named("back-button")!
            menuTemplateImage = menuImage.withRenderingMode(.alwaysTemplate)
            selector = #selector(UIViewController.backButtonPressed(_:))
        } else {
            let menuImage = UIImage.named("menu-icon")!
            menuTemplateImage = menuImage.withRenderingMode(.alwaysTemplate)
            selector = #selector(UIViewController.menuButtonPressed(_:))
        }
        
        viewController.navigationController?.navigationBar.tintColor = UIColor.black
        viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(image: menuTemplateImage,
                                                                          style: .plain,
                                                                          target: viewController,
                                                                          action: selector)
    }
    
}

/// Default, overridable, implementations of back/menu button press actions.
extension UIViewController {
    
    @objc func backButtonPressed(_ sender: UIBarButtonItem!) {
        if let navigationController = self.navigationController {
            navigationController.popViewController(animated: true)
        }
    }
    
    @objc func menuButtonPressed(_ sender: UIBarButtonItem!) {
        guard let sideMenuController = sideMenuController else {
            return
        }
        sideMenuController.showMenu()
    }
    
}
