//
//  MyKudosViewController.swift
//  VillageContainerApp
//
//  Created by Rob Feldmann on 3/31/17.
//  Copyright © 2017 Dynamit. All rights reserved.
//

import UIKit
import VillageCore

class MyKudosViewController: UIViewController, NavBarDisplayable {
    
    // MARK: - Pulic (Internal) Vars
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBehaviors([
            LeftBarButtonBehavior(showing: .menuOrBack)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.title = "My " + Constants.Settings.kudosPluralShort
        
        loadPages()
        setNavbarAppearance(for: navigationItem)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let pageController = segue.destination as? UIPageViewController {
            self.pageController = pageController
        }
    }
    
    // MARK: - Target/Action
    
    @objc internal func onTabClick(_ sender: UIButton) {
        if sender == receivedTab?.tabButton && selectedTab != receivedTab {
            selectReceivedTab()
        } else if sender == givenTab?.tabButton && selectedTab != givenTab {
            selectGivenTab()
        }
        
    }
    
    // MARK: - Private Methods
    
    fileprivate func loadPages() {        
        firstly {
            User.current.getPerson()
        }.then { [weak self] person in
            guard let `self` = self else { return }
            
            self.pages.removeAll()
            
            let storyboard = UIStoryboard(name: "Kudos", bundle: Constants.bundle)
            let kudosListControllerId = "KudosListController"
            
            // Received Kudos
            let received = storyboard.instantiateViewController(withIdentifier: kudosListControllerId) as! KudosListController
            received.list = .received(receiver: person)
            self.pages.append(received)
            
            // Given Kudos
            let given = storyboard.instantiateViewController(withIdentifier: kudosListControllerId) as! KudosListController
            given.list = .given(giver: person)
            self.pages.append(given)
            
            self.pageController?.setViewControllers([self.pages.first!], direction: .forward, animated: false, completion: nil)
            
            if self.selectedFilter == filter.given {
                self.selectGivenTab()
            } else if self.selectedFilter == filter.received {
                self.selectReceivedTab()
            } else {
                self.selectReceivedTab()
            }
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
        if let index = pages.firstIndex(of: viewController as! KudosListController) {
            if index > 0 && index < pages.count {
                let newIndex = index - 1
                return pages[newIndex]
            }
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let index = pages.firstIndex(of: viewController as! KudosListController) {
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
              let currentIndex = pages.firstIndex(of: currentVC) else {
            return
        }
        
        currentIndex == 0 ? selectReceivedTab() : selectGivenTab()
    }
}
