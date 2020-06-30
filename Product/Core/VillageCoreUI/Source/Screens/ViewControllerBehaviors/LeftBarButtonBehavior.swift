//
//  LeftBarButtonBehavior.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 4/11/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit

class LeftBarButtonBehavior: ViewControllerLifecycleBehavior {
    
    enum ButtonStyle {
        case menu
        case back
        case menuOrBack
        
        fileprivate var showsBackButton: Bool {
            switch self {
            case .back, .menuOrBack:
                return true
            case .menu:
                return false
            }
        }
        
        fileprivate var showsMenuButton: Bool {
            switch self {
            case .menu, .menuOrBack:
                return true
            case .back:
                return false
            }
        }
    }
    
    var badgeText: String? {
        didSet {
            self.barButtonItem?.badgeString = badgeText
        }
    }
    
    init(showing buttonStyle: ButtonStyle) {
        self.buttonStyle = buttonStyle
    }
    
    private let buttonStyle: ButtonStyle?
    
    private var barButtonItem: UIBarButtonItem?
    
    private init() {
        self.buttonStyle = .none
    }
    
    func afterLoading(_ viewController: UIViewController) {
        guard let buttonStyle = self.buttonStyle else {
            return
        }
        
        if buttonStyle.showsBackButton {
            // Hide the actual back button text
            viewController.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            
            // Modify the back indicator image
            let backImage = UIImage.named("back-button")?.withRenderingMode(.alwaysTemplate)
            viewController.navigationController?.navigationBar.backIndicatorImage = backImage
            viewController.navigationController?.navigationBar.backIndicatorTransitionMaskImage = backImage
        }
        
        let isRootViewController = (viewController.navigationController?.viewControllers ?? []).count <= 1
        let hasSideMenu = viewController.sideMenuController != nil
        
        if buttonStyle.showsMenuButton && hasSideMenu && isRootViewController {
            let barButton = UIBarButtonItem(badge: badgeText, image: UIImage.named("menu-icon")?.withRenderingMode(.alwaysTemplate) ?? UIImage(), target: viewController, action: #selector(viewController.vlg_showMenu(_:)))
			barButton.accessibilityLabel = "menu_button"
            viewController.navigationItem.leftBarButtonItem = barButton
            self.barButtonItem = barButton
        }
        
    }
    
}

/// Default, overridable, implementations of back/menu button press actions.
fileprivate extension UIViewController {
    
    @objc func vlg_showMenu(_ sender: UIBarButtonItem) {
        sideMenuController?.showMenu()
    }
    
}
