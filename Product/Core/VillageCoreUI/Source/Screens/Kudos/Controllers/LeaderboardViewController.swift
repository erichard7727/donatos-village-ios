//
//  LeaderboardViewController.swift
//  VillageContainerApp
//
//  Created by Russell Stephenson on 9/27/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit

class LeaderboardViewController: UIViewController, KudosServiceInjected {
    var context: AppContext!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet fileprivate weak var thisWeekTab: TabItemView? {
        didSet {
            // Configure tab
            thisWeekTab?.tabButton.setTitle("This Week", for: .normal)
            thisWeekTab?.tabButton.addTarget(self, action: #selector(onTabClick(_:)), for: .touchUpInside)
            
            // Start out with this tab selected
            selectedTab = thisWeekTab
        }
    }
    @IBOutlet fileprivate weak var allTimeTab: TabItemView? {
        didSet {
            // Configure tab
            allTimeTab?.tabButton.setTitle("All Time", for: .normal)
            allTimeTab?.tabButton.addTarget(self, action: #selector(onTabClick(_:)), for: .touchUpInside)
        }
    }
    
    fileprivate var selectedTab: TabItemView!
    
    internal func onTabClick(_ sender: UIButton) {
        if sender == thisWeekTab?.tabButton && selectedTab != thisWeekTab {
            selectThisWeekTab()
        } else if sender == allTimeTab?.tabButton && selectedTab != allTimeTab {
            selectAllTimeTab()
        }
    }
    
    fileprivate func selectThisWeekTab() {
        selectedTab = thisWeekTab
        pageController?.setViewControllers([self.pages[0]], direction: .reverse, animated: true, completion: nil)
        thisWeekTab?.changeHighlight()
        allTimeTab?.removeHighlight()
    }
    
    fileprivate func selectAllTimeTab() {
        selectedTab = allTimeTab
        pageController?.setViewControllers([self.pages[1]], direction: .forward, animated: true, completion: nil)
        thisWeekTab?.removeHighlight()
        allTimeTab?.changeHighlight()
    }
    
    fileprivate var pageController: UIPageViewController? {
        didSet {
            if let pageController = self.pageController {
                pageController.dataSource = self
                pageController.delegate = self
            }
        }
    }
    
    fileprivate var pages = [LeaderboardTableViewController]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.startAnimating()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        thisWeekTab?.tabButton.isEnabled = false
        allTimeTab?.tabButton.isEnabled = false
        
        loadPages()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let pageController = segue.destination as? UIPageViewController {
            self.pageController = pageController
        }
    }
    
    fileprivate func loadPages() {
        
        pages.removeAll()
        
        let storyboard = UIStoryboard(name: "Kudos", bundle: Constants.bundle)
        let leaderboardTableviewControllerId = "LeaderboardTableViewController"
        
        kudosService.getLeaderboard(filter: FetchLeaderboardFilter.week, page: 1) {  weekResult in
            switch weekResult {
            case .success(let people):
                
                // Week
                let weekly = storyboard.instantiateViewController(withIdentifier: leaderboardTableviewControllerId) as! LeaderboardTableViewController
                weekly.list = people
                weekly.context = self.context
                weekly.filter = FetchLeaderboardFilter.week
                self.thisWeekTab?.tabButton.isEnabled = true
                self.pages.append(weekly)
                
                self.kudosService.getLeaderboard(filter: FetchLeaderboardFilter.all, page: 1) {
                    allResult in
                    switch allResult {
                    case .success(let allPeople):
                        
                        // All Time
                        let allTime = storyboard.instantiateViewController(withIdentifier: leaderboardTableviewControllerId) as! LeaderboardTableViewController
                        allTime.list = allPeople
                        allTime.context = self.context
                        allTime.filter = FetchLeaderboardFilter.all
                        self.allTimeTab?.tabButton.isEnabled = true
                        self.pages.append(allTime)
                        
                        self.pageController?.setViewControllers([self.pages.first!], direction: .forward, animated: false, completion: nil)
                        self.activityIndicator.stopAnimating()
                        self.activityIndicator.alpha = 0
                        self.selectThisWeekTab()
                    case .error(let error):
                        var errorMessage: String
                        if let localizedFailure = error.userInfo[NSLocalizedFailureReasonErrorKey] as? [String: AnyObject], let error = localizedFailure["error"] as? [String: AnyObject], let code = error["code"], let errorDescription = error["description"] as? String {
                            errorMessage = "E" + String(describing: code) + " - " + String(describing: errorDescription)
                        } else {
                            errorMessage = "Could not update Leaderboard data."
                        }
                        let alert = UIAlertController.dismissableAlert("Error", message: errorMessage)
                        self.present(alert, animated: true, completion: nil)
                    }
                }
                
            case .error(let error):
                var errorMessage: String
                if let localizedFailure = error.userInfo[NSLocalizedFailureReasonErrorKey] as? [String: AnyObject], let error = localizedFailure["error"] as? [String: AnyObject], let code = error["code"], let errorDescription = error["description"] as? String {
                    errorMessage = "E" + String(describing: code) + " - " + String(describing: errorDescription)
                } else {
                    errorMessage = "Could not update Leaderboard data."
                }
                let alert = UIAlertController.dismissableAlert("Error", message: errorMessage)
                self.present(alert, animated: true, completion: nil)
            }
            
        }
        
    }
    
    @IBAction func menuItemPressed(_ sender: UIBarButtonItem!) {
        guard let sideMenuController = sideMenuController else {
            return
        }
        sideMenuController.showLeftMenuController(true)
    }
}

// MARK: - UIPageViewControllerDataSource, UIPageViewControllerDelegate

extension LeaderboardViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let vc = viewController as? LeaderboardTableViewController, let index = pages.index(of: vc) {
            if index > 0 && index < pages.count {
                let newIndex = index - 1
                return pages[newIndex]
            }
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let vc = viewController as? LeaderboardTableViewController, let index = pages.index(of: vc) {
            if index < pages.count - 1 {
                let newIndex = index + 1
                return pages[newIndex]
            }
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        guard completed,
            let currentVC = pageViewController.viewControllers?.first as? LeaderboardTableViewController,
            let currentIndex = pages.index(of: currentVC) else {
                return
        }
        
        currentIndex == 0 ? selectThisWeekTab() : selectAllTimeTab()
    }
}

