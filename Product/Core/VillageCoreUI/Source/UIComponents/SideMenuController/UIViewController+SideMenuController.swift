//
//  UIViewController+SideMenuController.swift
//  SideMenuController
//
//  Created by Jack Miller on 4/3/18.
//  Copyright © 2018 Dynamit. All rights reserved.
//

import UIKit

extension UIViewController {
    
    var sideMenuController: SideMenuController? {
        //climb the UIViewController hierarchy looking for a SideMenuController
        guard var climber = self.parent else { return nil }
        
        if let climber = climber as? SideMenuController {
            return climber
        }
        
        while let parent = climber.parent {
            if let menu = parent as? SideMenuController {
                return menu
            }
            climber = parent
        }
        
        return nil
    }
    
    @IBAction func showSideMenu() {
        guard sideMenuController != nil else { assertionFailure("invalid - no side menu found"); return }
        self.sideMenuController?.showMenu()
    }
    
}
