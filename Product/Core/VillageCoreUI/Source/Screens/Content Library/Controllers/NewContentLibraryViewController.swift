//
//  ContentLibraryViewController.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 9/27/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit
import VillageCore
import Promises
import DZNEmptyDataSet

final class ContentLibraryViewController: UIViewController {

    // MARK: - Public Properties

    // MARK: - Private Properties

    /// Base content item (folder) to show in.
    var baseContentItem: ContentLibraryItem? {
        didSet {
            guard let baseContentItem = baseContentItem else {
                return
            }

            guard baseContentItem.isDirectory else {
                assertionFailure()
                return
            }

            loadViewIfNeeded()

            title = baseContentItem.name

            allItems = baseContentItem.getDirectoryPaginated()
        }
    }

    /// Returns the appropriate paginated streams based on whether
    /// the user is performing a search or browsing available streams
    /// from the entire organization
    private var items: Paginated<ContentLibraryItem> {
        return searchedItems ?? allItems
    }

    /// All paginated streams available to the user
    private var allItems: Paginated<ContentLibraryItem> = ContentLibrary.getRootDirectoryPaginated() {
        didSet {
            allItems.delegate = self
        }
    }

    /// Paginated streams represented the user's search. This will be `nil`
    /// if the user is not currently searching
    private var searchedItems: Paginated<ContentLibraryItem>? {
        didSet {
            searchedItems?.delegate = self
            guard searchedItems != nil else { return }
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

    @IBOutlet private var loadingItemsContainer: UIView!

}

// MARK: - UIViewController Overrides

extension ContentLibraryViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        addBehaviors([
            LeftBarButtonBehavior(showing: .menuOrBack),
        ])

        allItems.delegate = self

        if baseContentItem == nil {
            navigationItem.searchController = searchController
        }

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let defaultLargeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode
        if Constants.Settings.disableLargeTitles {
            defaultLargeTitleDisplayMode = .never
        } else {
            defaultLargeTitleDisplayMode = .always
        }

        navigationItem.largeTitleDisplayMode = baseContentItem == nil ? defaultLargeTitleDisplayMode : .never
        if baseContentItem == nil {
            title = "Content Library"
        }

        if items.needsFetching {
            loadingItemsContainer.isHidden = false
            items.fetchValues(at: [])
        } else {
            loadingItemsContainer.isHidden = true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: animated)
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

extension ContentLibraryViewController { }

// MARK: - Target/Action

@objc private extension ContentLibraryViewController { }

// MARK: - Private Methods

private extension ContentLibraryViewController {

    func setSearchBarEnabled(_ isEnabled: Bool) {
        searchController.searchBar.isUserInteractionEnabled = isEnabled
        searchController.searchBar.alpha = isEnabled ? 1.0 : 0.75
    }

}

// MARK: - UITableViewDataSource

extension ContentLibraryViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.totalCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContentLibraryCell", for: indexPath) as! ContentLibraryCell
        let item = items.value(at: indexPath.row)

        cell.filetype = item?.type ?? .directory
        cell.nameLabel.text = item?.name

        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        cell.modifiedLabel.text = item?.modified.flatMap({ formatter.string(from: $0) }).map({ "Modified \($0)" })

        return cell
    }

}

// MARK: - UITableViewDataSourcePrefetching

extension ContentLibraryViewController: UITableViewDataSourcePrefetching {

    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        if indexPaths.contains(where: items.isLoadingValue) {
            items.fetchValues(at: indexPaths)
        }
    }

}

// MARK: - UITableViewDelegate

extension ContentLibraryViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if items.isLoadingValue(at: indexPath) {
            // can't select a cell that is loading
            return nil
        } else {
            return indexPath
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = items.value(at: indexPath.row) else {
            assertionFailure("User should not be able to select a cell that is loading!")
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }

        if item.type == .directory {
            // Push a new folder browser.
            let controller = UIStoryboard(name: "ContentLibrary", bundle: Constants.bundle).instantiateViewController(withIdentifier: "ContentLibraryViewController") as! ContentLibraryViewController
            controller.baseContentItem = item
            navigationController?.pushViewController(controller, animated: true)
        } else {
            // Push content browser.
            let controller = UIStoryboard(name: "ContentLibrary", bundle: Constants.bundle).instantiateViewController(withIdentifier: "ContentDetailController") as! ContentDetailController
            controller.contentItem = item
            navigationController?.pushViewController(controller, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }

}

// MARK: - DZNEmptyDataSetSource

extension ContentLibraryViewController: DZNEmptyDataSetSource {

    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        if searchController.isActive {
            let title = NSMutableAttributedString(string: "No items found", attributes: nil) // reg
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
            return NSAttributedString(string: "This folder is empty.", attributes: nil) // reg
        }
    }

}

// MARK: - DZNEmptyDataSetDelegate

extension ContentLibraryViewController: DZNEmptyDataSetDelegate {

    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        // Only show an empty data set if loading is not in-progress
        return loadingItemsContainer.isHidden
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

extension ContentLibraryViewController: PaginationDelegate {

    func onFetchCompleted(with newIndexPathsToReload: [IndexPath]?) {
        guard let newIndexPathsToReload = newIndexPathsToReload else {
            // Show the first page of results
            loadingItemsContainer.isHidden = true
            tableView.reloadData()
            return
        }

        // Reload the next page of results
        let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows ?? []
        let indexPathsToReload = items.visibleIndexPathsToReload(indexPathsForVisibleRows, intersecting: newIndexPathsToReload)
        tableView.reloadRows(at: indexPathsToReload, with: .automatic)
    }

    func onFetchFailed(with error: Error) {
        let alert = UIAlertController.dismissable(title: "Error", message: error.vlg_userDisplayableMessage)
        self.present(alert, animated: true, completion: nil)
    }

}

// MARK: - UISearchResultsUpdating

extension ContentLibraryViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text ?? ""

        guard !searchText.isEmpty else {
            self.loadingItemsContainer.isHidden = true
            searchedItems = nil
            tableView.reloadData()
            return
        }

        searchedItems = ContentLibrary.searchLibraryPaginated(searchText)
        self.loadingItemsContainer.isHidden = false
        searchDebouncer.debounce(afterTimeInterval: 1) { [weak self] in
            self?.items.fetchValues(at: [])
        }
    }

}
