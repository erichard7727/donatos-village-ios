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
    
    @IBOutlet private weak var noticesUnreadBadge: UILabel! {
        didSet {
            noticesUnreadBadge.layer.masksToBounds = true
            noticesUnreadBadge.isHidden = true
        }
    }
    
    private weak var currentUserViewController: CurrentUserViewController!
    
    private var unread: Unread? {
        didSet {
            noticesUnreadBadge.text = unread?.notices.description
            noticesUnreadBadge.isHidden = (unread?.notices ?? 0) == 0
        }
    }
    
}

// MARK: - UIViewController Overrides

extension MainMenuViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        subscribeToNotifications()
        
        updateUnreadCounts()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        noticesUnreadBadge.layer.cornerRadius = noticesUnreadBadge.bounds.size.height / 2
    }
    
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
        let vc = UIStoryboard(name: "Notices", bundle: Constants.bundle).instantiateInitialViewController() as! NoticeListViewController
        self.sideMenuController?.setContentViewController(UINavigationController(rootViewController: vc), fadeAnimation: true)
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
        let vc = UIStoryboard(name: "Directory", bundle: Constants.bundle).instantiateViewController(withIdentifier: "PeopleViewController") as! PeopleViewController
        vc.delegate = self
        
        sideMenuController?.setContentViewController(UINavigationController(rootViewController: vc), fadeAnimation: true)
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

// MARK: - Private Methods

private extension MainMenuViewController {
    
    func subscribeToNotifications() {
        
        NotificationCenter.default.addObserver(forName: Notification.Name.Notice.WasAcknowledged, object: nil, queue: nil) { [weak self] (_) in
            self?.updateUnreadCounts()
        }
        
    }
    
    func updateUnreadCounts() {
        firstly {
            Unread.getCounts()
        }.then { (unread) in
            self.unread = unread
        }
    }
    
}

// MARK: - PeopleViewControllerDelegate

extension MainMenuViewController: PeopleViewControllerDelegate {
    
    func shouldShowAndStartDirectMessage(_ directMessage: Group, controller: PeopleViewController) {
        #warning("TODO - Implmenent PeopleViewControllerDelegate")
        assertionFailure()
    }
    
}
