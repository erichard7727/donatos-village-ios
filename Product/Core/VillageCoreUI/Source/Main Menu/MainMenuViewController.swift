//
//  MainMenuViewController.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 2/10/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit
import Promises
import VillageCore
import SafariServices

final class MainMenuViewController: UIViewController {
    
    @IBOutlet private weak var menuOptionHome: UIView!
    @IBOutlet private weak var menuOptionNotices: UIView!
    @IBOutlet private weak var menuOptionEvents: UIView!
    @IBOutlet private weak var menuOptionNews: UIView!
    @IBOutlet private weak var menuOptionDirectMessages: UIView!

    @IBOutlet private weak var menuOptionGroupsContainer: UIView!
    @IBOutlet private weak var menuOptionGroups: UIView!
    @IBOutlet private weak var menuOptionGroupsExpandButton: UIButton!
    @IBOutlet private weak var menuOptionGroupsChildrenContainer: UIStackView! {
        didSet {
            menuOptionGroupsChildrenContainer.arrangedSubviews.forEach({ $0.removeFromSuperview() })
        }
    }
    @IBOutlet private weak var groupsUnreadBadge: UILabel! {
        didSet {
            groupsUnreadBadge.layer.masksToBounds = true
            groupsUnreadBadge.isHidden = true
        }
    }
    
    @IBOutlet private weak var menuOptionOtherGroups: UIView!
    @IBOutlet private weak var menuOptionPeople: UIView!
    
    @IBOutlet private weak var menuOptionKudosContainer: UIView! {
        didSet {
            menuOptionKudosContainer.isHidden = !Constants.Settings.kudosEnabled
        }
    }
    @IBOutlet private weak var menuOptionKudos: UIView!
    @IBOutlet private weak var menuOptionKudosLabel: UILabel! {
        didSet {
            menuOptionKudosLabel.text = Constants.Settings.kudosPluralLong
        }
    }
    @IBOutlet private weak var menuOptionsKudosExpandButton: UIButton!
    @IBOutlet private weak var menuOptionKudosChildrenContainer: UIStackView! {
        didSet {
            menuOptionKudosChildrenContainer.arrangedSubviews.forEach { (view) in
                view.alpha = self.areKudosCollapsed ? 0 : 1
                view.isHidden = self.areKudosCollapsed
            }
        }
    }
    @IBOutlet private weak var menuOptionKudosStream: UIView!
    @IBOutlet private weak var menuOptionKudosStreamLabel: UILabel! {
        didSet {
            menuOptionKudosStreamLabel.text = "All " + Constants.Settings.kudosPluralLong
        }
    }
    @IBOutlet private weak var menuOptionKudosMyKudos: UIView!
    @IBOutlet private weak var menuOptionKudosMyKudosLabel: UILabel! {
        didSet {
            menuOptionKudosMyKudosLabel.text = "My " + Constants.Settings.kudosPluralLong
        }
    }
    @IBOutlet private weak var menuOptionKudosAchievements: UIView!
    @IBOutlet private weak var menuOptionKudosGiveKudos: UIView!
    @IBOutlet private weak var menuOptionKudosGiveKudosLabel: UILabel! {
        didSet {
            menuOptionKudosGiveKudosLabel.text = "Give " + Constants.Settings.kudosSingularLong
        }
    }
    @IBOutlet private weak var menuOptionKudosLeaderboard: UIView!
    
    @IBOutlet private weak var menuOptionContentLibrary: UIView!
    
    @IBOutlet private weak var noticesUnreadBadge: UILabel! {
        didSet {
            noticesUnreadBadge.layer.masksToBounds = true
            noticesUnreadBadge.isHidden = true
        }
    }
    
    @IBOutlet private weak var eventsUnreadBadge: UILabel! {
        didSet {
            eventsUnreadBadge.layer.masksToBounds = true
            eventsUnreadBadge.isHidden = true
        }
    }
    
    @IBOutlet private weak var newsUnreadBadge: UILabel! {
        didSet {
            newsUnreadBadge.layer.masksToBounds = true
            newsUnreadBadge.isHidden = true
        }
    }
    
    @IBOutlet private weak var directMessagesUnreadBadge: UILabel! {
        didSet {
            directMessagesUnreadBadge.layer.masksToBounds = true
            directMessagesUnreadBadge.isHidden = true
        }
    }
    
    private var areGroupsCollapsed = false {
        didSet {
            UIView.animate(withDuration: 0.25) {
                let groupsUnreadCount = Int(self.groupsUnreadBadge.text ?? "") ?? 0
                self.groupsUnreadBadge.isHidden = !self.areGroupsCollapsed || groupsUnreadCount == 0

                self.menuOptionGroupsExpandButton.transform = self.menuOptionGroupsExpandButton.transform.rotated(by: .pi / 1) // 180 degrees
                self.menuOptionGroupsChildrenContainer.arrangedSubviews.forEach { (view) in
                    view.alpha = self.areGroupsCollapsed == true ? 0 : 1
                    view.isHidden = self.areGroupsCollapsed
                }
                self.menuOptionGroupsChildrenContainer.layoutIfNeeded()
            }
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

            eventsUnreadBadge.text = unread?.events.description
            eventsUnreadBadge.isHidden = (unread?.events ?? 0) == 0
            
            // News isn't available in the API yet
            newsUnreadBadge.isHidden = true
            
            let groupMenuItems = menuOptionGroupsChildrenContainer.arrangedSubviews
                .compactMap({ $0 as? GroupMenuItem})
            var allGroupsUnreadCount = 0
            groupMenuItems.forEach { (item) in
                item.unread = unread?.streams.first(where: { $0.id == item.stream?.id })
                allGroupsUnreadCount += item.unread?.count ?? 0
            }
            
            groupsUnreadBadge.text = allGroupsUnreadCount.description
            groupsUnreadBadge.isHidden = !areGroupsCollapsed || allGroupsUnreadCount == 0
            
            let unreadDMs = unread?.streams
                .filter({ $0.id.lowercased().starts(with: "dm") })
                .map({ $0.count })
                .reduce(0, +) ?? 0
            directMessagesUnreadBadge.text = unreadDMs.description
            directMessagesUnreadBadge.isHidden = unreadDMs == 0
        }
    }
    
}

// MARK: - UIViewController Overrides

extension MainMenuViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if !Constants.Settings.achievementsEnabled {
            menuOptionKudosAchievements.removeFromSuperview()
            menuOptionKudosLeaderboard.removeFromSuperview()
        }

        if !Constants.Settings.contentLibraryEnabled {
            menuOptionContentLibrary.removeFromSuperview()
        }

        subscribeToNotifications()
        
        self.updateSubscribedGroups()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        noticesUnreadBadge.layer.cornerRadius = noticesUnreadBadge.bounds.size.height / 2
        eventsUnreadBadge.layer.cornerRadius = eventsUnreadBadge.bounds.size.height / 2
        newsUnreadBadge.layer.cornerRadius = newsUnreadBadge.bounds.size.height / 2
        directMessagesUnreadBadge.layer.cornerRadius = directMessagesUnreadBadge.bounds.size.height / 2
        groupsUnreadBadge.layer.cornerRadius = groupsUnreadBadge.bounds.size.height / 2
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
        vc.displayType = .notices
        self.sideMenuController?.setContentViewController(UINavigationController(rootViewController: vc), fadeAnimation: true)
        self.sideMenuController?.hideMenu()
    }
    
    @IBAction func onGoToEvents(_ sender: Any? = nil) {
        let vc = UIStoryboard(name: "Notices", bundle: Constants.bundle).instantiateInitialViewController() as! NoticeListViewController
        vc.displayType = .events
        self.sideMenuController?.setContentViewController(UINavigationController(rootViewController: vc), fadeAnimation: true)
        self.sideMenuController?.hideMenu()
    }
    
    @IBAction func onGoToNews(_ sender: Any? = nil) {
        let vc = UIStoryboard(name: "Notices", bundle: Constants.bundle).instantiateInitialViewController() as! NoticeListViewController
        vc.displayType = .news
        self.sideMenuController?.setContentViewController(UINavigationController(rootViewController: vc), fadeAnimation: true)
        self.sideMenuController?.hideMenu()
    }
    
    @IBAction func onGoToDirectMessages(_ sender: Any? = nil) {
        let vc = UIStoryboard(name: "DirectMessages", bundle: Constants.bundle).instantiateViewController(withIdentifier: "DMViewController") as! DMViewController
        self.sideMenuController?.setContentViewController(UINavigationController(rootViewController: vc), fadeAnimation: true)
        self.sideMenuController?.hideMenu()
    }
    
    @IBAction func onToggleGroups(_ sender: Any? = nil) {
        areGroupsCollapsed.toggle()
    }
    
    @IBAction func onCreateGroup(_ sender: Any? = nil) {
        let vc = UIStoryboard(name: "Groups", bundle: Constants.bundle).instantiateViewController(withIdentifier: "CreateGroupViewController") as! CreateGroupViewController
        sideMenuController?.setContentViewController(UINavigationController(rootViewController: vc), fadeAnimation: true)
        self.sideMenuController?.hideMenu()
    }
    
    @IBAction func onGoToOtherGroups(_ sender: Any? = nil) {
        let vc = UIStoryboard(name: "OtherGroupsListViewController", bundle: Constants.bundle).instantiateInitialViewController() as! OtherGroupsListViewController
        sideMenuController?.setContentViewController(UINavigationController(rootViewController: vc), fadeAnimation: true)
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
    
    @IBAction func onGoToSchedular(_ sender: Any? = nil) {
		MySchedule.fetchCredentials(using: VillageService.shared)
			.then { credentials in
				DispatchQueue.main.async { [weak self] in
					let controller = MyScheduleViewController.create()
					controller.load(credentials: credentials)
					self?.present(controller, animated: true) {}
				}
			}
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
        
        NotificationCenter.default.addObserver(forName: Notification.Name.sideMenuDidShow, object: nil, queue: nil) { [weak self] (_) in
            guard let `self` = self else { return }
            firstly {
                return self.updateSubscribedGroups()
            }.then {
                self.updateUnreadCounts()
            }
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.Notice.WasAcknowledged, object: nil, queue: nil) { [weak self] (_) in
            self?.updateUnreadCounts()
        }
        
    }
    
    @discardableResult
    func updateSubscribedGroups() -> Promise<Void> {
        return firstly {
            Streams.subscribed()
        }.then { [weak self] streams in
            guard let `self` = self else { return }
            
            self.menuOptionGroupsChildrenContainer.arrangedSubviews.forEach({ $0.removeFromSuperview() })
            
            streams
                .map { stream -> GroupMenuItem in
                    let view = GroupMenuItem()
                    view.delegate = self
                    view.stream = stream
                    view.alpha = self.areGroupsCollapsed == true ? 0 : 1
                    view.isHidden = self.areGroupsCollapsed
                    return view
                }
                .forEach { self.menuOptionGroupsChildrenContainer.addArrangedSubview($0) }
        }.asVoid()
    }
    
    @discardableResult
    func updateUnreadCounts() -> Promise<Void> {
        return firstly {
            Unread.getCounts()
        }.then { (unread) in
            self.unread = unread
        }.asVoid()
    }
    
}

// MARK: - PeopleViewControllerDelegate

extension MainMenuViewController: PeopleViewControllerDelegate {
    
    func shouldShowAndStartDirectMessage(_ directMessage: VillageCore.Stream, controller: PeopleViewController) {
        let dataSource = DirectMessageStreamDataSource(stream: directMessage)
        let vc = StreamViewController(dataSource: dataSource)
        self.sideMenuController?.setContentViewController(UINavigationController(rootViewController: vc), fadeAnimation: true)
    }
    
}

// MARK: - GroupMenuItemDelegate

extension MainMenuViewController: GroupMenuItemDelegate {
    
    func groupMenuItem(_ item: GroupMenuItem, didSelectGroup group: VillageCore.Stream) {
        group.ensureHasDetails { (group) in
            let dataSource = GroupStreamDataSource(stream: group, isUserSubscribed: true)
            let vc = StreamViewController(dataSource: dataSource)
            self.sideMenuController?.setContentViewController(UINavigationController(rootViewController: vc), fadeAnimation: true)
            self.sideMenuController?.hideMenu()
        }
    }
    
}

// MARK: - SFSafariViewControllerDelegate

extension MainMenuViewController: SFSafariViewControllerDelegate {
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
