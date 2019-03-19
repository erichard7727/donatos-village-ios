//
//  MyKudosViewController.swift
//  VillageContainerApp
//
//  Created by Rob Feldmann on 3/31/17.
//  Copyright © 2017 Dynamit. All rights reserved.
//

import UIKit

class MyKudosViewController: UIViewController {
    
    // MARK: - Pulic (Internal) Vars
    
    var context: AppContext!
    var selectedFilter: filter?
    
    enum filter {
        case given
        case received
    }
    
    // MARK: - Private Outlets
    
    @IBOutlet fileprivate weak var receivedTab: TabItemView? {
        didSet {
            // Configure tab
            receivedTab?.tabButton.setTitle("Received", for: .normal)
            receivedTab?.tabButton.addTarget(self, action: #selector(onTabClick(_:)), for: .touchUpInside)
            
            // Start out with this tab selected
            selectedTab = receivedTab
        }
    }
    @IBOutlet fileprivate weak var givenTab: TabItemView? {
        didSet {
            // Configure tab
            givenTab?.tabButton.setTitle("Given", for: .normal)
            givenTab?.tabButton.addTarget(self, action: #selector(onTabClick(_:)), for: .touchUpInside)
        }
    }
    
    // MARK: - Private Vars
    
    fileprivate var selectedTab: TabItemView!
    
    fileprivate var pageController: UIPageViewController? {
        didSet {
            if let pageController = self.pageController {
                pageController.dataSource = self
                pageController.delegate = self
            }
        }
    }
    
    fileprivate var pages = [KudosListController]()
    
    // MARK: - UIViewController Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.title = "My Kudos"
        
        loadPages()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let pageController = segue.destination as? UIPageViewController {
            self.pageController = pageController
        }
    }
    
    // MARK: - Target/Action
    
    @IBAction func menuItemPressed(_ sender: UIBarButtonItem!) {
        guard let sideMenuController = sideMenuController else {
            return
        }
        sideMenuController.showLeftMenuController(true)
    }
    
    internal func onTabClick(_ sender: UIButton) {
        if sender == receivedTab?.tabButton && selectedTab != receivedTab {
            selectReceivedTab()
        } else if sender == givenTab?.tabButton && selectedTab != givenTab {
            selectGivenTab()
        }
        
    }
    
    // MARK: - Private Methods
    
    fileprivate func loadPages() {
        
        guard let session = self.context.session,
              let person = session.person else {
            assertionFailure("Person not found")
            return
        }
        
        pages.removeAll()
        
        let storyboard = UIStoryboard(name: "Kudos", bundle: Constants.bundle)
        let kudosListControllerId = "KudosListController"
        
        // Received Kudos
        let received = storyboard.instantiateViewController(withIdentifier: kudosListControllerId) as! KudosListController
        received.list = .received(context: self.context, receiver: person)
        pages.append(received)
        
        // Given Kudos
        let given = storyboard.instantiateViewController(withIdentifier: kudosListControllerId) as! KudosListController
        given.list = .given(context: self.context, giver: person)
        pages.append(given)
        
        pageController?.setViewControllers([pages.first!], direction: .forward, animated: false, completion: nil)
        
        if selectedFilter == filter.given {
            selectGivenTab()
        } else if selectedFilter == filter.received {
            selectReceivedTab()
        } else {
            selectReceivedTab()
        }
    }
    
    fileprivate func selectReceivedTab() {
        selectedTab = receivedTab
        pageController?.setViewControllers([self.pages[0]], direction: .reverse, animated: true, completion: nil)
        receivedTab?.changeHighlight()
        givenTab?.removeHighlight()
    }
    
    fileprivate func selectGivenTab() {
        selectedTab = givenTab
        pageController?.setViewControllers([self.pages[1]], direction: .forward, animated: true, completion: nil)
        receivedTab?.removeHighlight()
        givenTab?.changeHighlight()
    }
    
}

// MARK: - UIPageViewControllerDataSource, UIPageViewControllerDelegate

extension MyKudosViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let index = pages.index(of: viewController as! KudosListController) {
            if index > 0 && index < pages.count {
                let newIndex = index - 1
                return pages[newIndex]
            }
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let index = pages.index(of: viewController as! KudosListController) {
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
              let currentVC = pageViewController.viewControllers?.first as? KudosListController,
              let currentIndex = pages.index(of: currentVC) else {
            return
        }
        
        currentIndex == 0 ? selectReceivedTab() : selectGivenTab()
    }
}
