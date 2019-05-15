//
//  OtherGroupsListViewController.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 5/11/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit
import VillageCore
import Promises
import DZNEmptyDataSet

class GroupTableViewCellConfiguartor {
    
    func configure(_ cell: GroupTableViewCell, forDisplaying group: VillageCore.Stream?) {
        
        cell.nameLabel?.text = group?.name
        if let details = group?.details {
            cell.membersLabel?.text = "\(details.memberCount) \(details.memberCount == 1 ? "member" : "members")"
        } else {
            cell.membersLabel?.text = nil
        }
        
        cell.setLoading(group == nil)
    }
    
}

final class OtherGroupsListViewController: UIViewController {
    
    // MARK: - Public Properties
    
    // MARK: - Private Properties
    
    /// Returns the appropriate paginated streams based on whether
    /// the user is performing a search or browsing available streams
    /// from the entire organization
    private var groups: Paginated<VillageCore.Stream> {
        return searchedGroups ?? allGroups
    }
    
    /// All paginated streams available to the user
    private lazy var allGroups: Paginated<VillageCore.Stream> = {
        let paginated = Streams.otherPaginated()
        paginated.delegate = self
        return paginated
    }()
    
    /// Paginated streams represented the user's search. This will be `nil`
    /// if the user is not currently searching
    private var searchedGroups: Paginated<VillageCore.Stream>? {
        didSet {
            searchedGroups?.delegate = self
            guard searchedGroups != nil else { return }
            tableView.reloadData()
        }
    }
    
    private lazy var searchController: UISearchController = {
        let searchController = TintedSearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = true
        return searchController
    }()
    
    /// Allows the user's search to be "debounced" as the user is typing
    /// their query so that we don't query the API too frequently
    private let searchDebouncer = Debouncer()
    
    // MARK: Outlets
    
    @IBOutlet private var tableView: UITableView! {
        didSet {
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 64
            tableView.alwaysBounceVertical = false
            tableView.tableFooterView = UIView()
            tableView.emptyDataSetSource = self
            tableView.emptyDataSetDelegate = self
        }
    }
    
    @IBOutlet private var createGroupButton: UIBarButtonItem! {
        didSet {
            if Constants.Settings.createGroupsEnabled {
                createGroupButton.isEnabled = true
                createGroupButton.isAccessibilityElement = true
                createGroupButton.tintColor = UINavigationBar.appearance().tintColor
            } else {
                createGroupButton.isEnabled = false
                createGroupButton.isAccessibilityElement = false
                createGroupButton.tintColor = .clear
            }
        }
    }
    
    @IBOutlet private var loadingGroupsContainer: UIView!
    
}

// MARK: - UIViewController Overrides

extension OtherGroupsListViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBehaviors([
            LeftBarButtonBehavior(showing: .menuOrBack),
        ])
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if groups.needsFetching {
            loadingGroupsContainer.isHidden = false
            groups.fetchValues(at: [])
        } else {
            loadingGroupsContainer.isHidden = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: animated)
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        switch identifier {
        case "CreateGroup" where !Constants.Settings.createGroupsEnabled:
            assertionFailure("Programmer Error: Invalid segue when user does not have permission to create groups!")
            return false
            
        default:
            return true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is CreateGroupViewController {
            // nothing to configure
        } else {
            assertionFailure("Unexpected segue")
        }
    }
}

// MARK: - Public Methods

extension OtherGroupsListViewController { }

// MARK: - Target/Action

@objc private extension OtherGroupsListViewController { }

// MARK: - Private Methods

private extension OtherGroupsListViewController {
    
    func setSearchBarEnabled(_ isEnabled: Bool) {
        searchController.searchBar.isUserInteractionEnabled = isEnabled
        searchController.searchBar.alpha = isEnabled ? 1.0 : 0.75
    }
    
}

// MARK: - UITableViewDataSource

extension OtherGroupsListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups.totalCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupCell", for: indexPath) as! GroupTableViewCell
        let group = groups.value(at: indexPath.row)
        GroupTableViewCellConfiguartor().configure(cell, forDisplaying: group)
        return cell
    }
    
}

// MARK: - UITableViewDataSourcePrefetching

extension OtherGroupsListViewController: UITableViewDataSourcePrefetching {
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        if indexPaths.contains(where: groups.isLoadingValue) {
            groups.fetchValues(at: indexPaths)
        }
    }
    
}

// MARK: - UITableViewDelegate

extension OtherGroupsListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if groups.isLoadingValue(at: indexPath) {
            // can't select a cell that is loading
            return nil
        } else {
            return indexPath
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let group = groups.value(at: indexPath.row) else {
            assertionFailure("User should not be able to select a cell that is loading!")
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        
        firstly {
            group.subscribe()
        }.then { [weak self] in
            let dataSource = GroupStreamDataSource(stream: group)
            let vc = StreamViewController(dataSource: dataSource)
            self?.sideMenuController?.setContentViewController(UINavigationController(rootViewController: vc), fadeAnimation: true)
        }.catch { [weak self] error in
            let alert = UIAlertController.dismissable(title: "Error", message: error.vlg_userDisplayableMessage)
            self?.present(alert, animated: true, completion: nil)
        }
    }
    
}

// MARK: - DZNEmptyDataSetSource

extension OtherGroupsListViewController: DZNEmptyDataSetSource {
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        if searchController.isActive {
            let title = NSMutableAttributedString(string: "No group found", attributes: nil) // reg
            if let searchTerm = searchController.searchBar.text {
                let term = NSMutableAttributedString(string: " matching \"", attributes: nil) // reg
                term.append(NSAttributedString(string: searchTerm, attributes: [
                    .foregroundColor: UIColor.darkText,
                ]))
                term.append(NSAttributedString(string: "\"", attributes: nil)) // reg
                title.append(term)
            }
            title.append(NSAttributedString(string: ".", attributes: nil)) // reg
            return title
        } else {
            return NSAttributedString(string: "There are no groups to display.", attributes: nil) // reg
        }
    }
    
}

// MARK: - DZNEmptyDataSetDelegate

extension OtherGroupsListViewController: DZNEmptyDataSetDelegate {
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        // Only show an empty data set if loading is not in-progress
        return loadingGroupsContainer.isHidden
    }
    
    func emptyDataSetWillAppear(_ scrollView: UIScrollView!) {
        // Disable search if the main dataset is empty
        // Always leave search enabled if the user is searching
        setSearchBarEnabled(searchController.isActive)
    }
    
    func emptyDataSetWillDisappear(_ scrollView: UIScrollView!) {
        setSearchBarEnabled(true)
    }
    
}

// MARK: - PaginationDelegate

extension OtherGroupsListViewController: PaginationDelegate {

    func onFetchCompleted(with newIndexPathsToReload: [IndexPath]?) {
        guard let newIndexPathsToReload = newIndexPathsToReload else {
            // Show the first page of results
            loadingGroupsContainer.isHidden = true
            tableView.reloadData()
            return
        }
        
        // Reload the next page of results
        let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows ?? []
        let indexPathsToReload = groups.visibleIndexPathsToReload(indexPathsForVisibleRows, intersecting: newIndexPathsToReload)
        tableView.reloadRows(at: indexPathsToReload, with: .automatic)
    }
    
    func onFetchFailed(with error: Error) {
        let alert = UIAlertController.dismissable(title: "Error", message: error.vlg_userDisplayableMessage)
        self.present(alert, animated: true, completion: nil)
    }
    
}

// MARK: - UISearchResultsUpdating

extension OtherGroupsListViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text ?? ""

        guard !searchText.isEmpty else {
            self.loadingGroupsContainer.isHidden = true
            searchedGroups = nil
            tableView.reloadData()
            return
        }
        
        searchedGroups = Streams.searchOthersPaginated(for: searchText)
        self.loadingGroupsContainer.isHidden = false
        searchDebouncer.debounce(afterTimeInterval: 1) { [weak self] in
            self?.groups.fetchValues(at: [])
        }
    }
    
}
