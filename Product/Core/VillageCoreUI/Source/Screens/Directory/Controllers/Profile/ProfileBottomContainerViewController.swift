//
//  ProfileBottomContainerViewController.swift
//  VillageContainerApp
//
//  Created by Russell Stephenson on 10/4/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit
import VillageCore

class ProfileBottomContainerViewController: UIViewController {
    
    var person: Person!
    var currentPerson: Person?
    
    var animateLeft: Bool = true
    
    enum tabs: Int {
        case profile = 0
        case kudos = 1
        case achievements = 2
    }
    
    var selectedTab: tabs = .profile
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let controller = UIStoryboard(name: "Directory", bundle: Constants.bundle).instantiateViewController(withIdentifier: "ContactPersonViewController") as! ContactPersonViewController
        controller.person = person
        controller.currentPerson = currentPerson
        self.addChild(controller)
        controller.view.frame = self.view.frame
        self.view.addSubview(controller.view)
        controller.didMove(toParent: self)
    }
    
    func cycleViewController(fromVC: UIViewController, toVC: UIViewController) {
        fromVC.willMove(toParent: nil)
        addChild(toVC)
        
        var endFrame = CGRect(x: 0, y: 0, width: 0, height: 0)
        
        if animateLeft {
            toVC.view.frame = rightView()
            endFrame = leftView()
        } else {
            toVC.view.frame = leftView()
            endFrame = rightView()
        }
        
        transition(
            from: fromVC,
            to: toVC,
            duration: 0.25,
            options: .curveEaseIn,
            animations: {
                toVC.view.frame = fromVC.view.frame
                fromVC.view.frame = endFrame
            },
            completion: { finished in
                fromVC.removeFromParent()
                toVC.didMove(toParent: self)
            }
        )
    }
    
    func rightView() -> CGRect {
        return CGRect(x: view.frame.width, y: 0.0, width: view.frame.width, height: view.frame.height)
    }
    
    func leftView() -> CGRect {
        return CGRect(x: -view.frame.width, y: 0.0, width: view.frame.width, height: view.frame.height)
    }
    
}
