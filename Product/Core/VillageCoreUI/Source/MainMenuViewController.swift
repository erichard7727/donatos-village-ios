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
    
    @IBOutlet private weak var menuOptionKudosContainer: UIView! {
        didSet {
            menuOptionKudosContainer.isHidden = !Constants.Settings.kudosEnabled
        }
    }
    @IBOutlet private weak var menuOptionKudos: UIView!
    @IBOutlet private weak var menuOptionsKudosExpandButton: UIButton!
    @IBOutlet private weak var menuOptionKudosChildrenContainer: UIStackView! {
        didSet {
            menuOptionKudosChildrenContainer.arrangedSubviews.forEach { (view) in
                view.alpha = self.areKudosCollapsed ? 0 : 1
                view.isHidden = areKudosCollapsed
            }
        }
    }
    @IBOutlet private weak var menuOptionKudosStream: UIView!
    @IBOutlet private weak var menuOptionKudosMyKudos: UIView!
    @IBOutlet private weak var menuOptionKudosAchievements: UIView! {
        didSet {
            if !Constants.Settings.achievementsEnabled {
//                menuOptionKudosAchievements.removeFromSuperview()
            }
        }
    }
    @IBOutlet private weak var menuOptionKudosGiveKudos: UIView!
    @IBOutlet private weak var menuOptionKudosLeaderboard: UIView! {
        didSet {
            if !Constants.Settings.achievementsEnabled {
                menuOptionKudosLeaderboard.removeFromSuperview()
            }
        }
    }
    
    @IBOutlet private weak var menuOptionContentLibrary: UIView!
    
    @IBOutlet private weak var noticesUnreadBadge: UILabel! {
        didSet {
            noticesUnreadBadge.layer.masksToBounds = true
            noticesUnreadBadge.isHidden = true
        }
    }
    
    private var areKudosCollapsed = true {
        didSet {
            UIView.animate(withDuration: 0.25) {
                self.menuOptionsKudosExpandButton.transform = self.menuOptionsKudosExpandButton.transform.rotated(by: .pi / 1) // 180 degrees
                self.menuOptionKudosChildrenContainer.arrangedSubviews.forEach { (view) in
                    view.alpha = self.areKudosCollapsed ? 0 : 1
                    view.isHidden = self.areKudosCollapsed
                }
                self.menuOptionKudosChildrenContainer.layoutIfNeeded()
            }
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
    
    @IBAction func onToggleKudos(_ sender: Any? = nil) {
        areKudosCollapsed.toggle()
    }
    
    @IBAction func onGoToKudosStream(_ sender: Any? = nil) {
        let vc = UIStoryboard(name: "Kudos", bundle: Constants.bundle).instantiateViewController(withIdentifier: "KudosListController") as! KudosListController
        vc.list = .allStream
        sideMenuController?.setContentViewController(UINavigationController(rootViewController: vc), fadeAnimation: true)
        self.sideMenuController?.hideMenu()
    }
    
    @IBAction func onGoToKudosMine(_ sender: Any? = nil) {
        let vc = UIStoryboard(name: "Kudos", bundle: Constants.bundle).instantiateViewController(withIdentifier: "MyKudosViewController") as! MyKudosViewController
        sideMenuController?.setContentViewController(UINavigationController(rootViewController: vc), fadeAnimation: true)
        self.sideMenuController?.hideMenu()
    }
    
    @IBAction func onGoToKudosAchievements(_ sender: Any? = nil) {
        let vc = UIStoryboard(name: "Kudos", bundle: Constants.bundle).instantiateViewController(withIdentifier: "MyAchievementsViewController") as! MyAchievementsViewController
        sideMenuController?.setContentViewController(UINavigationController(rootViewController: vc), fadeAnimation: true)
        self.sideMenuController?.hideMenu()
    }
    
    @IBAction func onGoToKudosGive(_ sender: Any? = nil) {
        let vc = UIStoryboard(name: "Kudos", bundle: Constants.bundle).instantiateViewController(withIdentifier: "GiveKudosViewController") as! GiveKudosViewController
        sideMenuController?.setContentViewController(UINavigationController(rootViewController: vc), fadeAnimation: true)
        self.sideMenuController?.hideMenu()
    }
    
    @IBAction func onGoToKudosLeaderboard(_ sender: Any? = nil) {
        let vc = UIStoryboard(name: "Kudos", bundle: Constants.bundle).instantiateViewController(withIdentifier: "LeaderboardViewController") as! LeaderboardViewController
        sideMenuController?.setContentViewController(UINavigationController(rootViewController: vc), fadeAnimation: true)
        self.sideMenuController?.hideMenu()
    }
    
    @IBAction func onGoToContentLibrary(_ sender: Any? = nil) {
        let vc = UIStoryboard(name: "ContentLibrary", bundle: Constants.bundle).instantiateViewController(withIdentifier: "ContentLibraryViewController") as! ContentLibraryViewController
        sideMenuController?.setContentViewController(UINavigationController(rootViewController: vc), fadeAnimation: true)
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
    
    func shouldShowAndStartDirectMessage(_ directMessage: VillageCore.Stream, controller: PeopleViewController) {
        #warning("TODO - Implmenent PeopleViewControllerDelegate")
        assertionFailure()
    }
    
}
