//
//  LeaderboardViewController.swift
//  VillageContainerApp
//
//  Created by Russell Stephenson on 9/27/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit

class LeaderboardViewController: UIViewController {

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
    
    @objc internal func onTabClick(_ sender: UIButton) {
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
        
        addBehaviors([
            LeftBarButtonBehavior(showing: .menuOrBack)
        ])
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
        
        pages = [
            LeaderboardTableViewController.make(for: .week),
            LeaderboardTableViewController.make(for: .all),
        ]
        
        self.thisWeekTab?.tabButton.isEnabled = true
        self.allTimeTab?.tabButton.isEnabled = true
        
        
        self.pageController?.setViewControllers([self.pages.first!], direction: .forward, animated: false, completion: nil)

        self.selectThisWeekTab()
    }
    
}

// MARK: - UIPageViewControllerDataSource, UIPageViewControllerDelegate

extension LeaderboardViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let vc = viewController as? LeaderboardTableViewController, let index = pages.firstIndex(of: vc) {
            if index > 0 && index < pages.count {
                let newIndex = index - 1
                return pages[newIndex]
            }
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let vc = viewController as? LeaderboardTableViewController, let index = pages.firstIndex(of: vc) {
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
            let currentIndex = pages.firstIndex(of: currentVC) else {
                return
        }
        
        currentIndex == 0 ? selectThisWeekTab() : selectAllTimeTab()
    }
}

