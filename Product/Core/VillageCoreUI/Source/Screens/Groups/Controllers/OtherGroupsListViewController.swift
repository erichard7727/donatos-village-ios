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

class GroupTableViewCell: UITableViewCell {
    
    @IBOutlet var nameLabel: UILabel! {
        didSet {
            _accessibilityElements = nil
        }
    }
    
    @IBOutlet var membersLabel: UILabel! {
        didSet {
            _accessibilityElements = nil
        }
    }
    
    @IBOutlet private var loadingIndicator: UIActivityIndicatorView!
    
    func setLoading(_ isLoading: Bool) {
        let oldValue = loadingIndicator.isAnimating
        if isLoading {
            loadingIndicator.startAnimating()
            selectionStyle = .none
            accessoryType = .none
        } else {
            loadingIndicator.stopAnimating()
            selectionStyle = .gray
            accessoryType = .disclosureIndicator
        }
        if oldValue != isLoading {
            UIAccessibility.post(notification: .layoutChanged, argument: self)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        nameLabel.text = nil
        membersLabel.text = nil
        loadingIndicator.stopAnimating()
        selectionStyle = .gray
    }
    
    override var accessibilityElements: [Any]? {
        get {
            if _accessibilityElements == nil {
                let element = UIAccessibilityElement(accessibilityContainer: self.contentView)
                
                if loadingIndicator.isAnimating {
                    element.accessibilityLabel = "Loading Group"
                    element.accessibilityTraits = [.staticText]
                } else {
                    element.accessibilityLabel = [nameLabel.text, membersLabel.text]
                        .compactMap({ $0 })
                        .joined(separator: ", ")
                    element.accessibilityTraits = [.button]
                    if isSelected {
                        element.accessibilityTraits.formUnion([.selected])
                    }
                    element.accessibilityHint = "Double tap to subscribe"
                }
                
                _accessibilityElements = [element]
            }
            return _accessibilityElements!
        }
        set { }
    }
    private var _accessibilityElements: [Any]?
    
}

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
    
    private lazy var groups: Paginated<VillageCore.Stream> = {
        let paginated = Streams.otherPaginated()
        paginated.delegate = self
        return paginated
    }()
    
    // MARK: Outlets
    
    @IBOutlet private var tableView: UITableView! {
        didSet {
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 64
            tableView.alwaysBounceVertical = false
            tableView.tableFooterView = UIView()
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
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if groups.needsFetching {
            loadingGroupsContainer.isHidden = false
            groups.fetchValues()
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

private extension OtherGroupsListViewController { }

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
            groups.fetchValues()
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
            let vc = UIStoryboard(name: "Groups", bundle: Constants.bundle).instantiateViewController(withIdentifier: "GroupViewController") as! GroupViewController
            vc.group = group
            self.sideMenuController?.setContentViewController(UINavigationController(rootViewController: vc), fadeAnimation: true)
        }.catch { [weak self] error in
            let alert = UIAlertController.dismissable(title: "Error", message: error.vlg_userDisplayableMessage)
            self?.present(alert, animated: true, completion: nil)
        }
    }
    
}

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
