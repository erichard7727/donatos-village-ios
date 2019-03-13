//
//  MainMenuViewController.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 2/10/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit
import VillageCore

final class MainMenuViewController: UIViewController {
    
    @IBOutlet private weak var menuOptionHome: UIView!
    @IBOutlet private weak var menuOptionNotices: UIView!
    @IBOutlet private weak var menuOptionDirectMessages: UIView!
    @IBOutlet private weak var menuOptionGroups: UIView!
    @IBOutlet private weak var menuOptionOtherGroups: UIView!
    @IBOutlet private weak var menuOptionPeople: UIView!
    @IBOutlet private weak var menuOptionKudos: UIView!
    @IBOutlet private weak var menuOptionContentLibrary: UIView!
    
    private weak var currentUserViewController: CurrentUserViewController!
    
}

// MARK: - UIViewController Overrides

extension MainMenuViewController {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let currentUserVC = segue.destination as? CurrentUserViewController {
            currentUserVC.view.translatesAutoresizingMaskIntoConstraints = false
            self.currentUserViewController = currentUserVC
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        currentUserViewController.configure(with: User.current)
    }
    
}

// MARK: - Target/Action

private extension MainMenuViewController {
    
    @IBAction func onGoToHome(_ sender: Any? = nil) {
        guard let villageContainer = self.sideMenuController as? VillageContainer else {
            assertionFailure();
            return
        }
        villageContainer.showHome()
    }
    
    @IBAction func onGoToNotices(_ sender: Any? = nil) {
//        let vc = ...
//        self.sideMenuController?.setContentViewController(vc, fadeAnimation: true)
        print("TODO - show Notices")
        self.sideMenuController?.hideMenu()
    }
    
    @IBAction func onGoToDirectMessages(_ sender: Any? = nil) {
        //        let vc = ...
        //        self.sideMenuController?.setContentViewController(vc, fadeAnimation: true)
        print("TODO - show DirectMessages")
        self.sideMenuController?.hideMenu()
    }
    
    @IBAction func onGoToGroups(_ sender: Any? = nil) {
        //        let vc = ...
        //        self.sideMenuController?.setContentViewController(vc, fadeAnimation: true)
        print("TODO - show Groups")
        self.sideMenuController?.hideMenu()
    }
    
    @IBAction func onGoToOtherGroups(_ sender: Any? = nil) {
        //        let vc = ...
        //        self.sideMenuController?.setContentViewController(vc, fadeAnimation: true)
        print("TODO - show Other Groups")
        self.sideMenuController?.hideMenu()
    }
    
    @IBAction func onGoToPeople(_ sender: Any? = nil) {
        //        let vc = ...
        //        self.sideMenuController?.setContentViewController(vc, fadeAnimation: true)
        print("TODO - show People")
        self.sideMenuController?.hideMenu()
    }
    
    @IBAction func onGoToKudos(_ sender: Any? = nil) {
        //        let vc = ...
        //        self.sideMenuController?.setContentViewController(vc, fadeAnimation: true)
        print("TODO - show Kudos")
        self.sideMenuController?.hideMenu()
    }
    
    @IBAction func onGoToContentLibrary(_ sender: Any? = nil) {
        //        let vc = ...
        //        self.sideMenuController?.setContentViewController(vc, fadeAnimation: true)
        print("TODO - show ContentLibrary")
        self.sideMenuController?.hideMenu()
    }
}
