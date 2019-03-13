//
//  SideMenuControllerDelegate.swift
//  SideMenuController
//
//  Created by Jack Miller on 4/3/18.
//  Copyright © 2018 Dynamit. All rights reserved.
//

import UIKit

protocol SideMenuControllerDelegate {
    ///The delegate object can provide a block that will get called inside a UIView.animate block, allowing it to perform animations alongside the "show menu" animation
    var showMenuAnimations: (() -> Void)? { get }
    
    ///The delegate object can provide a block that will get called inside a UIView.animate block, allowing it to perform animations alongside the "hide menu" animation
    var hideMenuAnimations: (() -> Void)? { get }
    
    func sideMenuWillShow(sideMenuController: SideMenuController)
    func sideMenuWillHide(sideMenuController: SideMenuController)
    func sideMenuDidShow(sideMenuController: SideMenuController)
    func sideMenuDidHide(sideMenuController: SideMenuController)
}

extension SideMenuControllerDelegate {
    var showMenuAnimations: (() -> Void)? { get { return nil } }
    var hideMenuAnimations: (() -> Void)? { get { return nil } }
    
    func sideMenuWillShow(sideMenuController: SideMenuController) { }
    func sideMenuWillHide(sideMenuController: SideMenuController) { }
    func sideMenuDidShow(sideMenuController: SideMenuController) { }
    func sideMenuDidHide(sideMenuController: SideMenuController) { }
}
