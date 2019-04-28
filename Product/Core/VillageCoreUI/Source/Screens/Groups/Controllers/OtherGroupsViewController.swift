//
//  OtherGroupsViewController.swift
//  VillageCore
//
//  Created by Colin on 12/4/15.
//  Copyright © 2015 Dynamit. All rights reserved.
//

import Foundation
import UIKit
import VillageCore

// MARK: OtherGroupsViewController
/// View controller showing a list of non-subscribed groups for the current user.
final class OtherGroupsViewController: UIViewController {

    @IBOutlet weak var emptyStateLabel: UILabel! {
        didSet {
            emptyStateLabel.text = "There are no groups to display."
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    /// Searching controller.
    var searchController: UISearchController!
    
    var refreshControl: UIRefreshControl?
    
    var groups: [VillageCore.Stream] = []
    var originalGroups: Set<VillageCore.Stream> = []
    var searchText = ""
    var currentPage = 1
    var loadingMoreGroups = false
    let footerProgressIndicator = UIActivityIndicatorView(style: .gray)
    @IBOutlet weak var createGroupButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBehaviors([
            LeftBarButtonBehavior(showing: .menuOrBack)
        ])
        
        if !Constants.Settings.createGroupsEnabled {
            createGroupButton.tintColor = UIColor.white.withAlphaComponent(0)
            createGroupButton.isEnabled = false
        }
        
        setup()
        activityIndicator.startAnimating()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadingMoreGroups = true
        loadMoreGroups()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.disableRefreshing()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if let searchControl = searchController {
            searchControl.isActive = false
        }
    }
    
    func sortGroupList() {
        let newGroupList = groups.sorted {
            return $0.name.lowercased() < $1.name.lowercased()
        }
        
        groups = newGroupList
        self.tableView.reloadData()
        self.tableView.reloadSections([0], with: .automatic)
        loadingMoreGroups = false
    }
    
    func setup() {
        // Setup search controller.
        self.searchController = UISearchController(searchResultsController: nil)
        self.searchController.searchResultsUpdater = self
        self.searchController.delegate = self
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.hidesNavigationBarDuringPresentation = false
        self.searchController.searchBar.delegate = self
        self.searchController.searchBar.searchBarStyle = .prominent
        self.searchController.searchBar.tintColor = UIColor(red: 233/255.0, green: 94/255.0, blue: 63/255.0, alpha: 1.0)
        
        self.definesPresentationContext = true
        self.tableView.tableHeaderView = self.searchController.searchBar
        
        emptyStateLabel.alpha = 0
        displayProgressFooterView()
    }
    
    // NOTE: This must not be removed. This supports the unwind action from subsequent view controllers.
    @IBAction func prepareforUnwind(_ segue: UIStoryboardSegue) {}
    
    func enableRefreshing() {
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(OtherGroupsViewController.refreshTableView(_:)), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    func disableRefreshing() {
        refreshControl = nil
    }
    
    @objc func refreshTableView(_ sender: UIRefreshControl!) {
        loadMoreGroups()
    }
    
    func displayProgressFooterView() {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 44))
        footerProgressIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        footerProgressIndicator.center = headerView.center
        headerView.addSubview(footerProgressIndicator)
        footerProgressIndicator.bringSubviewToFront(headerView)
        footerProgressIndicator.startAnimating()
        footerProgressIndicator.alpha = 0
        headerView.backgroundColor = UIColor.white
        tableView.tableFooterView = headerView
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: -headerView.frame.height, right: 0)
    }
    
    func loadMoreGroups() {
        // Don't refresh data if we're in search mode.
        if searchController.isActive {
            loadingMoreGroups = false
            return
        }
        
        activityIndicator.startAnimating()
        footerProgressIndicator.alpha = 0
        
        firstly {
            Streams.other(page: self.currentPage)
        }.then { [weak self] groups in
            guard let `self` = self else { return }
            
            self.currentPage = self.currentPage + 1
            self.groups.append(contentsOf: groups)
            self.originalGroups.formUnion(groups)
            self.sortGroupList()
            self.tableView.reloadData()
            
            self.emptyStateLabel.isHidden = !self.groups.isEmpty
        }.always { [weak self] in
            self?.activityIndicator.stopAnimating()
            self?.footerProgressIndicator.alpha = 0
        }
    }
    
}

extension OtherGroupsViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y + scrollView.frame.size.height > scrollView.contentSize.height && !loadingMoreGroups {
            loadingMoreGroups = true
            footerProgressIndicator.alpha = 1
            loadMoreGroups()
        }
    }
}

extension OtherGroupsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupTableViewCell")
        let group = groups[indexPath.row]
        cell?.textLabel?.text = group.name
        cell?.detailTextLabel?.text = (group.details?.memberCount ?? 0) == 1 ? "Member" : "Members"
        return cell!
    }
}

extension OtherGroupsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Join group action.
        let group = groups[indexPath.row]
        
        firstly {
            group.subscribe()
        }.then { [weak self] in
            let vc = UIStoryboard(name: "Groups", bundle: Constants.bundle).instantiateViewController(withIdentifier: "GroupViewController") as! GroupViewController
            vc.group = group
            self?.sideMenuController?.setContentViewController(UINavigationController(rootViewController: vc), fadeAnimation: true)
        }.catch { [weak self] error in
            let alert = UIAlertController.dismissable(title: "Error", message: error.vlg_userDisplayableMessage)
            self?.present(alert, animated: true, completion: nil)
        }
    }
    
}

// MARK: UISearchControllerDelegate, UISearchResultsUpdating
extension OtherGroupsViewController: UISearchControllerDelegate, UISearchResultsUpdating {
    
    func willPresentSearchController(_ searchController: UISearchController) {
        // Disable refreshing content while searching.
        disableRefreshing()
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        // Re-enable refreshing content after searching.
        groups = Array(originalGroups)
        self.sortGroupList()
        emptyStateLabel.isHidden = !groups.isEmpty
        activityIndicator.stopAnimating()
        footerProgressIndicator.stopAnimating()
        enableRefreshing()
    }

    func updateSearchResults(for searchController: UISearchController) {
        // HACK: TODO: Update this. This only works due to membership begin local.
        
//        let searchString = searchController.searchBar.text ?? ""
//        
//        if searchString.trimmingCharacters(in: CharacterSet.whitespaces).characters.count == 0 {
//            groups = Array(originalGroups)
//        } else {
//            let strippedSearchString = searchString.trimmingCharacters(in: CharacterSet.whitespaces)
//            
//            groups = originalGroups.filter {
//                return $0.name.lowercased().contains(strippedSearchString.lowercased()) && $0.streamType == GroupObject.StreamType.Open
//            }
//        }
//        self.sortGroupList()
//        tableView.reloadData()
    }
}

extension OtherGroupsViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.groups = []
        self.tableView.reloadData()
        self.tableView.reloadSections([0], with: .automatic)
        activityIndicator.startAnimating()
        if searchText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).count == 0 {
            self.searchText = searchText
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.searchAPI), object: nil)
        } else {
            if searchText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).count > 0 {
                self.searchText = searchText
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.searchAPI), object: nil)
                self.perform(#selector(self.searchAPI), with: nil, afterDelay: 2)
            }
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.searchAPI), object: nil)
        searchAPI()
    }
    
    @objc func searchAPI() {
        guard !loadingMoreGroups else { return }

        activityIndicator.startAnimating()
        
        firstly {
            Streams.searchOthers(for: self.searchText.trimmingCharacters(in: CharacterSet.newlines))
        }.then { [weak self] groups in
            guard let `self` = self else { return }
            
            self.groups = groups
            self.sortGroupList()
            self.tableView.reloadData()
            
            self.emptyStateLabel.isHidden = !groups.isEmpty
        }.catch { [weak self] error in
            let alert = UIAlertController.dismissable(title: "Error", message: error.vlg_userDisplayableMessage)
            self?.present(alert, animated: true, completion: nil)
        }.always { [weak self] in
            self?.activityIndicator.stopAnimating()
        }
    }
}
