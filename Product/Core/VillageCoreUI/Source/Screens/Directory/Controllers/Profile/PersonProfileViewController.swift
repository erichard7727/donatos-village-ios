//
//  PersonProfileViewController.swift
//  VillageCore
//
//  Created by Colin on 12/9/15.
//  Copyright © 2015 Dynamit. All rights reserved.
//

import UIKit
import VillageCore

/// Person profile controller.
final class PersonProfileViewController: UIViewController, NavBarDisplayable {

    var person: Person?
    
    var delegate: PersonProfileViewControllerDelegate?

    @IBOutlet fileprivate weak var profileTab: TabItemView? {
        didSet {
            // Configure tab
            profileTab?.tabButton.setTitle("Profile", for: .normal)
            profileTab?.tabButton.addTarget(self, action: #selector(onTabClick(_:)), for: .touchUpInside)
            
            // Start out with this tab selected
            selectedTab = profileTab
        }
    }
    
    @IBOutlet fileprivate weak var kudoTab: TabItemView? {
        didSet {
            // Configure tab
            kudoTab?.tabButton.setTitle(Constants.Settings.kudosPluralShort, for: .normal)
            kudoTab?.tabButton.addTarget(self, action: #selector(onTabClick(_:)), for: .touchUpInside)
        }
    }
    
    @IBOutlet fileprivate weak var achievementTab: TabItemView? {
        didSet {
            // Configure tab
            achievementTab?.tabButton.setTitle("Achievements", for: .normal)
            achievementTab?.tabButton.addTarget(self, action: #selector(onTabClick(_:)), for: .touchUpInside)
        }
    }
    
    fileprivate var selectedTab: TabItemView!
    
    fileprivate func selectProfileTab() {
        selectedTab?.removeHighlight()
        profileTab?.changeHighlight()
        selectedTab = profileTab
        pageController?.setViewControllers([self.pages[0] as! ContactPersonViewController], direction: .reverse, animated: true, completion: nil)
        pageController?.currentScrollView?.setContentOffset(CGPoint.zero, animated: false)
        scrollView.childScrollView = pageController?.currentScrollView
    }
    
    fileprivate func selectKudosTab() {
        var direction: UIPageViewController.NavigationDirection = .reverse
        if selectedTab == profileTab {
            direction = .forward
        }
        selectedTab?.removeHighlight()
        kudoTab?.changeHighlight()
        selectedTab = kudoTab
        pageController?.setViewControllers([self.pages[1] as! KudosListController], direction: direction, animated: true, completion: nil)
        pageController?.currentScrollView?.setContentOffset(CGPoint.zero, animated: false)
        scrollView.childScrollView = pageController?.currentScrollView
    }
    
    fileprivate func selectAchievementsTab() {
        selectedTab?.removeHighlight()
        achievementTab?.changeHighlight()
        selectedTab = achievementTab
        pageController?.setViewControllers([self.pages[2] as! MyAchievementsViewController], direction: .forward, animated: true, completion: nil)
        pageController?.currentScrollView?.setContentOffset(CGPoint.zero, animated: false)
        scrollView.childScrollView = pageController?.currentScrollView
    }
    
    fileprivate var pageController: UIPageViewController? {
        didSet {
            if let pageController = self.pageController {
                pageController.dataSource = self
                pageController.delegate = self
                
                loadPages()
                
                self.scrollView.childScrollView = pageController.currentScrollView
            }
        }
    }
    
    @objc internal func onTabClick(_ sender: UIButton) {
        if sender == profileTab?.tabButton && selectedTab != profileTab {
            selectProfileTab()
        } else if sender == kudoTab?.tabButton && selectedTab != kudoTab {
            selectKudosTab()
        } else if sender == achievementTab?.tabButton && selectedTab != achievementTab {
            selectAchievementsTab()
        }
    }
    
    fileprivate var pages = [AnyObject]()
    
    fileprivate func loadPages() {
        
        firstly {
            User.current.getPerson()
        }.then { [weak self] currentPerson in
            guard
                let `self` = self,
                let profilePerson = self.person,
                let pagedViewController = self.pageController
            else { return }
            
            self.pages.removeAll()
            
            let storyboard = UIStoryboard(name: "Kudos", bundle: Constants.bundle)
            let kudosListControllerId = "KudosListController"
            let profileControllerId = "ContactPersonViewController"
            let achievementControllerId = "MyAchievementsViewController"
            
            // Profile
            let profile = UIStoryboard(name: "Directory", bundle: Constants.bundle).instantiateViewController(withIdentifier: profileControllerId) as! ContactPersonViewController
            profile.delegate = self.delegate
            profile.person = profilePerson
            profile.currentPerson = currentPerson
            self.pages.append(profile)
            
            if self.showKudos {
                // Received Kudos
                let received = storyboard.instantiateViewController(withIdentifier: kudosListControllerId) as! KudosListController
                received.list = .received(receiver: profilePerson)
                received.delegate = self
                self.pages.append(received)
                
                if Constants.Settings.achievementsEnabled {
                    //MyAchievementsViewController
                    let achievements = storyboard.instantiateViewController(withIdentifier: achievementControllerId) as! MyAchievementsViewController
                    achievements.otherUser = profilePerson
                    achievements.person = profilePerson
                    self.pages.append(achievements)
                }
                
            }
            
            pagedViewController.setViewControllers([self.pages.first! as! ContactPersonViewController], direction: .forward, animated: false, completion: nil)
            
            self.selectProfileTab()
        }
    }
    
    @IBOutlet weak var bottomContainerView: UIView!
    @IBOutlet fileprivate var scrollView: ParentScrollView!
    fileprivate var observeParentScrollView = true
    @IBOutlet weak var tabViewFrame: UIView!
    @IBOutlet weak var scrollContainerView: UIView!
    
    @IBOutlet weak var bottomContainerHeightConstraint: NSLayoutConstraint!
    var currentTab: TabItemView?
    var showKudos: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBehaviors([
            LeftBarButtonBehavior(showing: .menuOrBack)
        ])
        
        if !Constants.Settings.kudosEnabled {
            kudoTab?.isHidden = true
            achievementTab?.isHidden = true
            showKudos = false
        }
        
        if !Constants.Settings.achievementsEnabled {
            achievementTab?.isHidden = true
        }
        
        if let person = self.person {
            AnalyticsService.logEvent(name: "select_profile", parameters: ["profile_name": person.displayName ?? ""])
            
            self.updateHeader()
        }
        
        self.scrollView.contentInsetAdjustmentBehavior = .never
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNavbarAppearance(for: navigationItem)
        let originalHeight = bottomContainerView.frame.height
        var navBarHeight: CGFloat = 0
        if let navController = navigationController {
            navBarHeight = navController.navigationBar.frame.height + UIApplication.shared.statusBarFrame.height
        }
        
        let newHeight = ((view.frame.height * 2) - tabViewFrame.frame.height - originalHeight - (navBarHeight * 2)) as CGFloat
        scrollView.contentSize = CGSize(width: view.frame.width, height: newHeight)
        currentTab = profileTab
        //change back after kindred attains kudos stuff
        //bottomContainerHeightConstraint.constant = view.frame.height - (navBarHeight * 2) + UIApplication.shared.statusBarFrame.height
        bottomContainerHeightConstraint.constant = view.frame.height / 2
    }
    
    // MARK: UIViewController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case "EmbedPersonProfileHeaderSegue":
                guard let controller = segue.destination as? PersonProfileHeaderViewController else { fatalError("Type mismatch") }
                controller.person = person

            default:
                break
            }
        }
        
        if let pageController = segue.destination as? UIPageViewController {
            self.pageController = pageController
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    //cycle through embeded views to find the header and change the button title
    func changeButton(isAchievement: Bool) {
        for controller in self.children {
            if controller is PersonProfileHeaderViewController {
                if isAchievement {
                    if let childVC = controller as? PersonProfileHeaderViewController {
                        childVC.kudosButton.setTitle("Redeem Kudos", for: .normal)
                    }
                } else {
                    if let childVC = controller as? PersonProfileHeaderViewController {
                        childVC.kudosButton.setTitle("Give Kudos", for: .normal)
                    }
                }
            }
        }
    }
    
    func updateHeader() {
        for controller in self.children {
            if controller is PersonProfileHeaderViewController {
                if let childVC = controller as? PersonProfileHeaderViewController,
                   let currentPerson = person {
                    childVC.fullNameLabel.text = currentPerson.displayName
                    childVC.kudosLabel.text = currentPerson.kudos.points > 0 ? "- \(currentPerson.kudos.points) Kudos -" : ""
                }
            }
        }
    }
        
}

// MARK: - UIPageViewControllerDataSource, UIPageViewControllerDelegate

extension PersonProfileViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if viewController is ContactPersonViewController {
            for (i, page) in pages.enumerated() {
                if page is ContactPersonViewController {
                    if i > 0 && i < pages.count {
                        let newIndex = i - 1
                        return pages[newIndex] as! ContactPersonViewController
                    }
                }
            }
        } else if viewController is KudosListController {
            for (i, page) in pages.enumerated() {
                if page is KudosListController {
                    if i > 0 && i < pages.count {
                        let newIndex = i - 1
                        return pages[newIndex] as! ContactPersonViewController
                    }
                }
            }
        } else if viewController is MyAchievementsViewController {
            for (i, page) in pages.enumerated() {
                if page is MyAchievementsViewController {
                    if i > 0 && i < pages.count {
                        let newIndex = i - 1
                        return pages[newIndex] as! KudosListController
                    }
                }
            }
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if viewController is ContactPersonViewController {
            for (i, page) in pages.enumerated() {
                if page is ContactPersonViewController {
                    if i < pages.count - 1 {
                        let newIndex = i + 1
                        return pages[newIndex] as! KudosListController
                    }
                }
            }
        } else if viewController is KudosListController {
            for (i, page) in pages.enumerated() {
                if page is KudosListController {
                    if i < pages.count - 1 {
                        let newIndex = i + 1
                        return pages[newIndex] as! MyAchievementsViewController
                    }
                }
            }
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if pageController?.viewControllers?.first is ContactPersonViewController {
            selectProfileTab()
        } else if pageController?.viewControllers?.first is KudosListController {
            selectKudosTab()
        } else if pageController?.viewControllers?.first is MyAchievementsViewController {
            selectAchievementsTab()
        }
        guard let currentScrollView = pageViewController.currentScrollView else { return }
        
        scrollView.childScrollView = currentScrollView
    }
}

// MARK: - KudosListViewControllerDelegate

extension PersonProfileViewController: KudosListViewControllerDelegate {

    func kudosListController(_ kudosListController: KudosListController, shouldShowProfileFor person: Person) -> Bool {
        return self.person != person
    }

}

extension UIPageViewController {
    
    var currentScrollView: UIScrollView? {
        if let currentViewController = viewControllers?.first {
            if currentViewController.isViewLoaded {
                let currentView = currentViewController.view!
                
                if let currentScrollView = currentView as? UIScrollView {
                    return currentScrollView
                } else {
                    for view in currentView.subviews {
                        if let currentScrollView = view as? UIScrollView {
                            return currentScrollView
                        }
                    }
                }
            }
        }
        
        return nil
    }
}
