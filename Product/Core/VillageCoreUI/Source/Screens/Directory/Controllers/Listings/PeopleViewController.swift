//
//  PeopleViewController.swift
//  VillageCore
//
//  Created by Colin on 12/2/15.
//  Copyright © 2015 Dynamit. All rights reserved.
//

import UIKit
import Promises
//import FirebaseAnalytics
import AlamofireImage
import VillageCore

protocol PeopleViewControllerDelegate {
    func shouldShowAndStartDirectMessage(_ directMessage: Group, controller: PeopleViewController)
}

final class PeopleViewController: UIViewController {
    
    @IBOutlet weak var addBarButtonItem: UIBarButtonItem!

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var emptyStateLabel: UILabel!
    
    /// Searching controller.
    var searchController: UISearchController!
    
    /// Delegate object.
    var delegate: PeopleViewControllerDelegate?
    
    var contentIDsLoading = Set<String>()
    
    var contentIDsDisplayingInRows = [String: IndexPath]()
    
    var currentPage: Int = 1
    var searchCurrentPage: Int = 1
    
    var loadingMorePeople: Bool = false
    var searchText: String = ""
    
    let progressIndicator = UIActivityIndicatorView(style: .gray)
    
    var filteredpeople = [Person]()
    var originalPeople = Set<Person>()
    
    var refreshControl: UIRefreshControl?
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    // MARK: UIViewController
    
    override func viewDidLoad() {
        setupTableView()
        
        if !Constants.Settings.invitationsEnabled && !User.current.securityPolicies.contains(.inviteUsers) {
            addBarButtonItem.tintColor = UIColor.clear
            addBarButtonItem.isEnabled = false
        }
        
        AnalyticsService.logEvent(name: AnalyticsEventViewItem, parameters: [
            AnalyticsParameterItemLocationID: "people",
            AnalyticsParameterItemCategory: "list"
        ])
        
        searchController.searchBar.sizeToFit()
        tableView.tableHeaderView = searchController.searchBar
        
        emptyStateLabel.alpha = 0
        
        // Add in refresh control.
        //enableRefreshing()
        activityIndicator.startAnimating()
        activityIndicator.alpha = 1
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.indexPathForSelectedRow.flatMap({ tableView.deselectRow(at: $0, animated: true) })
        
        loadMorePeople()
    }
    
    func setupTableView() {
        // Setup search controller.
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
        
        searchController.searchBar.searchBarStyle = .prominent
        searchController.searchBar.tintColor = UIColor(red: 233/255.0, green: 94/255.0, blue: 63/255.0, alpha: 1.0)
        searchController.searchBar.delegate = self
        displayProgressFooterView()
    }
    
    func enableRefreshing() {
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refreshTableView(_:)), for: UIControl.Event.valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    func disableRefreshing() {
        refreshControl = nil
    }
    
    func refreshTableView() {
        // Wrapper around refreshing action so as to not introduce implementation details to callers.
        refreshTableView(nil)
    }
    
    @objc func refreshTableView(_ sender: UIRefreshControl!) {
        // Don't refresh data if we're in search mode.
        if searchController.isActive {
            return
        }
        
        // Perform animations for refreshing if we're not initiated by the user.
        // This is needed for the initial fetch case to show activity to the user.
        if let refreshControl = refreshControl , !refreshControl.isRefreshing {
            refreshControl.beginRefreshing()
        }
        
        firstly {
            People.getDirectory(page: self.currentPage)
        }.then { [weak self] people in
            guard let `self` = self else { return }
            
            if !people.isEmpty {
                self.emptyStateLabel.alpha = 0
                self.filteredpeople.append(contentsOf: people)
                self.originalPeople = self.originalPeople.union(people)
                self.sortPeopleList()
                self.currentPage = self.currentPage + 1
            } else if self.filteredpeople.count == 0 {
                self.emptyStateLabel.alpha = 1
                self.emptyStateLabel.text = "There are no people to display."
            }
        }.always {
            self.refreshControl?.endRefreshing()
            self.activityIndicator.alpha = 0
        }.catch { (error) in
            assertionFailure(error.localizedDescription)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case "ShowPersonProfileSegue":
                guard
                    let controller = segue.destination as? PersonProfileViewController,
                    let person = sender as? Person
                else {
                    fatalError("Type mismatch")
                }
                
                guard let indexPath = tableView.indexPathForSelectedRow else {
                    return
                }
                
                controller.person = person
                controller.delegate = self
            
            case "InvitePersonSegue":
                guard let controller = segue.destination as? InvitePersonController else {
                    fatalError("InvitePersonController not found")
                }
                
                controller.delegate = self

            default: break
            }
        }
    }
    
    @IBAction func menuItemPressed(_ sender: UIBarButtonItem!) {
        sideMenuController?.showMenu()
    }
    
}

extension PeopleViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let personCell = tableView.cellForRow(at: indexPath) as? PersonTableViewCell else {
            return
        }
        
        personCell.initializeCell()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredpeople.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PersonTableViewCell") as! PersonTableViewCell
        
        let person = filteredpeople[indexPath.row]
        cell.configureForPerson(person)
        
        if let url = person.avatarURL {
            let filter = AspectScaledToFillSizeWithRoundedCornersFilter(
                size: cell.avatarImageView.frame.size,
                radius: cell.avatarImageView.frame.size.height / 2
            )
            
            cell.avatarImageView.af_setImage(withURL: url, filter: filter)
        }
        
        return cell
    }
}

extension PeopleViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let person = filteredpeople[indexPath.row]
        
        activityIndicator.startAnimating()
        activityIndicator.alpha = 1
        
        firstly {
            person.getDetails()
        }.then { [weak self] (personWithDetails) in
            self?.performSegue(withIdentifier: "ShowPersonProfileSegue", sender: personWithDetails)
        }.catch { [weak self] _ in
            self?.performSegue(withIdentifier: "ShowPersonProfileSegue", sender: person)
        }.always { [weak self] in
            self?.activityIndicator.stopAnimating()
            self?.activityIndicator.alpha = 0
        }
        
    }
    
}

extension PeopleViewController: PersonProfileViewControllerDelegate {

    func shouldShowAndStartDirectMessage(_ directMessage: Group, controller: ContactPersonViewController) {
        delegate?.shouldShowAndStartDirectMessage(directMessage, controller: self)
    }
}

extension PeopleViewController: UISearchControllerDelegate, UISearchResultsUpdating {
    
    func willPresentSearchController(_ searchController: UISearchController) {
        // Disable refreshing content while searching.
        disableRefreshing()
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        // Re-enable refreshing content after searching.
        enableRefreshing()
        filteredpeople = Array(originalPeople)
        activityIndicator.stopAnimating()
        activityIndicator.alpha = 0
        if filteredpeople.count == 0 {
            emptyStateLabel.alpha = 1
            self.emptyStateLabel.text = "There are no people to display."
        } else {
            emptyStateLabel.alpha = 0
        }
        sortPeopleList()
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.searchAPI), object: nil)
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        
    }
    
    @objc func searchAPI() {
        guard !loadingMorePeople else {
            return
        }
        
        loadingMorePeople = true
        
        firstly {
            People.search(for: searchText, page: searchCurrentPage)
        }.then { [weak self] people in
            guard let `self` = self else { return }
            
            if !people.isEmpty {
                self.emptyStateLabel.alpha = 0
                self.searchCurrentPage = self.searchCurrentPage + 1
                
                // Remove the current user from search results
                self.originalPeople = self.originalPeople.union(people.filter({ $0.id != User.current.personId }))
                
                self.filteredpeople = self.originalPeople.filter {
                    return ($0.firstName ?? "").localizedCaseInsensitiveContains(self.searchText)
                        || ($0.lastName ?? "").localizedCaseInsensitiveContains(self.searchText)
                        || ($0.displayName ?? "").localizedCaseInsensitiveContains(self.searchText)
                        || ($0.jobTitle ?? "").localizedCaseInsensitiveContains(self.searchText)
                }
                
                if self.filteredpeople.isEmpty {
                    self.emptyStateLabel.alpha = 1
                    self.emptyStateLabel.text = "There are no people to display."
                }
                
                self.sortPeopleList()
            } else {
                self.emptyStateLabel.alpha = 1
                self.emptyStateLabel.text = "There are no people to display."
            }
        }.always { [weak self] in
            self?.loadingMorePeople = false
            self?.activityIndicator.stopAnimating()
            self?.activityIndicator.alpha = 0
        }.catch { (error) in
            assertionFailure(error.localizedDescription)
        }
        
    }
}

extension PeopleViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y + scrollView.frame.size.height + 30 >= scrollView.contentSize.height {
            if !loadingMorePeople {
                progressIndicator.alpha = 1
                if searchController.isActive {
                    searchAPI()
                } else {
                    loadMorePeople()
                }
            }
        }
    }
}

extension PeopleViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchCurrentPage = 1
        self.filteredpeople = []
        tableView.reloadData()
        self.tableView.reloadSections([0], with: .automatic)
        activityIndicator.startAnimating()
        activityIndicator.alpha = 1
        
        if searchText.trimmingCharacters(in: CharacterSet.urlQueryAllowed.inverted).isEmpty {
            self.searchText = searchText
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.searchAPI), object: nil)
        } else {
            self.searchText = searchText
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.searchAPI), object: nil)
            self.perform(#selector(self.searchAPI), with: nil, afterDelay: 2)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.searchAPI), object: nil)
        searchAPI()
    }
}

extension PeopleViewController {
    
    
    func displayProgressFooterView() {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 44))
        progressIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        progressIndicator.center = headerView.center
        headerView.addSubview(progressIndicator)
        progressIndicator.bringSubviewToFront(headerView)
        progressIndicator.startAnimating()
        progressIndicator.alpha = 0
        headerView.backgroundColor = UIColor.white
        tableView.tableFooterView = headerView
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: -headerView.frame.height, right: 0)
    }
    
    func loadMorePeople() {
        guard !searchController.isActive else {
            // Don't refresh data if we're in search mode.
            return
        }
        
        loadingMorePeople = true
        
        firstly {
            People.getDirectory(page: self.currentPage)
        }.then { [weak self] people in
            guard let `self` = self else { return }
            
            if !people.isEmpty {
                self.currentPage = self.currentPage + 1
                
                // Remove the current user from search results
                self.originalPeople = self.originalPeople.union(people.filter({ $0.id != User.current.personId }))
                
                self.filteredpeople.append(contentsOf: people)
                self.sortPeopleList()
            } else if self.filteredpeople.count == 0 {
                self.emptyStateLabel.alpha = 1
                self.emptyStateLabel.text = "There are no people to display."
            }
        }.always {
            self.loadingMorePeople = false
            self.progressIndicator.alpha = 0
            self.activityIndicator.alpha = 0
        }.catch { (error) in
            assertionFailure(error.localizedDescription)
        }
    }
    
    func sortPeopleList() {
        let newPeopleList = filteredpeople.sorted {
            guard let lhs = $0.firstName, let rhs = $1.firstName else {
                return false
            }
            
            switch lhs.localizedCaseInsensitiveCompare(rhs) {
            case .orderedSame:
                return false
                
            case .orderedAscending:
                return true
                
            case .orderedDescending:
                return false
            }
        }
        
        filteredpeople = newPeopleList
        tableView.reloadData()
        self.tableView.reloadSections([0], with: .automatic)
    }
}

extension PeopleViewController: InvitePersonControllerDelegate {
    
    func personInvited(emailAddress: String?) {
        guard let emailAddress = emailAddress else {
            return
        }
        
        firstly {
            User.invite(emailAddress: emailAddress)
        }.then { [weak self] in
            guard let `self` = self else { return }
            
            self.navigationController?.popViewController(animated: true)
            
            let alert = UIAlertController.dismissable(title: "User Invited", message: "An email invitation has been sent.")
            self.present(alert, animated: true, completion: nil)
        }.catch { _ in
            let alert = UIAlertController.dismissable(title: "Error", message: "There was a problem sending an invitation to that user. Please check the address and try again.")
            self.present(alert, animated: true, completion: nil)
        }
        
    }
}
