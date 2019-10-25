//
//  PeopleViewController.swift
//  VillageCore
//
//  Created by Colin on 12/2/15.
//  Copyright © 2015 Dynamit. All rights reserved.
//

import UIKit
import VillageCore
import Promises
import DZNEmptyDataSet
import AlamofireImage

protocol PeopleViewControllerDelegate {
    func shouldShowAndStartDirectMessage(_ directMessage: VillageCore.Stream, controller: PeopleViewController)
}

final class PeopleViewController: UIViewController {

    // MARK: - Public Properties

    var delegate: PeopleViewControllerDelegate?

    // MARK: - Private Properties

    /// Returns the appropriate paginated people based on whether
    /// the user is performing a search or browsing all available people
    private var people: Paginated<Person> {
        return searchedPeople ?? allPeople
    }

    /// All paginated people available to the user
    private lazy var allPeople: Paginated<Person> = {
        let paginated = People.getDirectoryPaginated()
        paginated.delegate = self
        return paginated
    }()

    /// Paginated directory representing the user's search. This will be `nil`
    /// if the user is not currently searching
    private var searchedPeople: Paginated<Person>? {
        didSet {
            searchedPeople?.delegate = self
            guard searchedPeople != nil else { return }
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
            tableView.estimatedRowHeight = 100
            tableView.alwaysBounceVertical = false
            tableView.tableFooterView = UIView()
            tableView.emptyDataSetSource = self
            tableView.emptyDataSetDelegate = self
        }
    }

    @IBOutlet weak var addBarButtonItem: UIBarButtonItem!

    @IBOutlet private var loadingPeopleContainer: UIView!

}

// MARK: - UIViewController Overrides

extension PeopleViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        addBehaviors([
            LeftBarButtonBehavior(showing: .menuOrBack),
        ])

        navigationItem.searchController = searchController
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if people.needsFetching {
            loadingPeopleContainer.isHidden = false
            people.fetchValues(at: [])
        } else {
            loadingPeopleContainer.isHidden = true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: animated)
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

}

// MARK: - Public Methods

extension PeopleViewController { }

// MARK: - Target/Action

@objc private extension PeopleViewController { }

// MARK: - Private Methods

private extension PeopleViewController {

    func setSearchBarEnabled(_ isEnabled: Bool) {
        searchController.searchBar.isUserInteractionEnabled = isEnabled
        searchController.searchBar.alpha = isEnabled ? 1.0 : 0.75
    }

}

// MARK: - UITableViewDataSource

extension PeopleViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return people.totalCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PersonTableViewCell", for: indexPath) as! PersonTableViewCell
        let person = people.value(at: indexPath.row)

        if let p = person {
            cell.configureForPerson(p)
        } else {
            print("loading")
        }

        if let url = person?.avatarURL {
            let filter = AspectScaledToFillSizeWithRoundedCornersFilter(
                size: cell.avatarImageView.frame.size,
                radius: cell.avatarImageView.frame.size.height / 2
            )

            cell.avatarImageView.af_setImage(withURL: url, filter: filter)
        }

        return cell
    }

}

// MARK: - UITableViewDataSourcePrefetching

extension PeopleViewController: UITableViewDataSourcePrefetching {

    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        if indexPaths.contains(where: people.isLoadingValue) {
            people.fetchValues(at: indexPaths)
        }
    }

}

// MARK: - UITableViewDelegate

extension PeopleViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if people.isLoadingValue(at: indexPath) {
            // can't select a cell that is loading
            return nil
        } else {
            return indexPath
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedPerson = people.value(at: indexPath.row) else {
            assertionFailure("User should not be able to select a cell that is loading!")
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }

        firstly {
            selectedPerson.getDetails()
        }.then { [weak self] (personWithDetails) in
            self?.performSegue(withIdentifier: "ShowPersonProfileSegue", sender: personWithDetails)
        }.catch { [weak self] _ in
            self?.performSegue(withIdentifier: "ShowPersonProfileSegue", sender: selectedPerson)
        }
    }

}

// MARK: - DZNEmptyDataSetSource

extension PeopleViewController: DZNEmptyDataSetSource {

    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        if searchController.isActive {
            let title = NSMutableAttributedString(string: "No people found", attributes: nil) // reg
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
            return NSAttributedString(string: "There are no people to display.", attributes: nil) // reg
        }
    }

}

// MARK: - DZNEmptyDataSetDelegate

extension PeopleViewController: DZNEmptyDataSetDelegate {

    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        // Only show an empty data set if loading is not in-progress
        return loadingPeopleContainer.isHidden
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

extension PeopleViewController: PaginationDelegate {

    func onFetchCompleted(with newIndexPathsToReload: [IndexPath]?) {
        guard let newIndexPathsToReload = newIndexPathsToReload else {
            // Show the first page of results
            loadingPeopleContainer.isHidden = true
            tableView.reloadData()
            return
        }

        // Reload the next page of results
        let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows ?? []
        let indexPathsToReload = people.visibleIndexPathsToReload(indexPathsForVisibleRows, intersecting: newIndexPathsToReload)
        tableView.reloadRows(at: indexPathsToReload, with: .automatic)
    }

    func onFetchFailed(with error: Error) {
        let alert = UIAlertController.dismissable(title: "Error", message: error.vlg_userDisplayableMessage)
        self.present(alert, animated: true, completion: nil)
    }

}

// MARK: - UISearchResultsUpdating

extension PeopleViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text ?? ""

        guard !searchText.isEmpty else {
            self.loadingPeopleContainer.isHidden = true
            searchedPeople = nil
            tableView.reloadData()
            return
        }

        searchedPeople = People.searchPaginated(for: searchText)
        self.loadingPeopleContainer.isHidden = false
        searchDebouncer.debounce(afterTimeInterval: 1) { [weak self] in
            self?.people.fetchValues(at: [])
        }
    }

}

extension PeopleViewController: PersonProfileViewControllerDelegate {

    func shouldShowAndStartDirectMessage(_ directMessage: VillageCore.Stream, controller: ContactPersonViewController) {
        delegate?.shouldShowAndStartDirectMessage(directMessage, controller: self)
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
        }.catch { (error) in
            let errorMessage = (error as? VillageServiceError)?.userDisplayableMessage ?? VillageServiceError.genericFailureMessage
            let alert = UIAlertController.dismissable(title: "Error", message: errorMessage)
            self.present(alert, animated: true, completion: nil)
        }

    }
}

//import UIKit
//import Promises
////import FirebaseAnalytics
//import AlamofireImage
//import VillageCore
//
//protocol PeopleViewControllerDelegate {
//    func shouldShowAndStartDirectMessage(_ directMessage: VillageCore.Stream, controller: PeopleViewController)
//}
//
//final class PeopleViewController: UIViewController {
//
//    @IBOutlet weak var addBarButtonItem: UIBarButtonItem!
//
//    @IBOutlet weak var tableView: UITableView! {
//        didSet {
//            tableView.alwaysBounceVertical = false
//        }
//    }
//
//    @IBOutlet weak var emptyStateLabel: UILabel! {
//        didSet {
//            emptyStateLabel.text = "There are no people to display."
//        }
//    }
//
//    /// Searching controller.
//    var searchController: UISearchController!
//
//    /// Delegate object.
//    var delegate: PeopleViewControllerDelegate?
//
//    var contentIDsLoading = Set<String>()
//
//    var contentIDsDisplayingInRows = [String: IndexPath]()
//
//    var currentPage: Int = 1
//    var searchCurrentPage: Int = 1
//
//    var loadingMorePeople: Bool = false
//    var searchText: String = ""
//
//    let progressIndicator = UIActivityIndicatorView(style: .gray)
//
//    var filteredpeople = [Person]()
//    var originalPeople = Set<Person>()
//
//    var refreshControl: UIRefreshControl?
//
//    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
//
//    // MARK: UIViewController
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        addBehaviors([
//            LeftBarButtonBehavior(showing: .menuOrBack)
//        ])
//
//        setupTableView()
//
//        if !Constants.Settings.invitationsEnabled || !User.current.securityPolicies.contains(.inviteUsers) {
//            addBarButtonItem.tintColor = UIColor.clear
//            addBarButtonItem.isEnabled = false
//        }
//
//        AnalyticsService.logEvent(name: AnalyticsEventViewItem, parameters: [
//            AnalyticsParameterItemLocationID: "people",
//            AnalyticsParameterItemCategory: "list"
//        ])
//
//        emptyStateLabel.isHidden = true
//
//        activityIndicator.startAnimating()
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//
//        tableView.indexPathForSelectedRow.flatMap({ tableView.deselectRow(at: $0, animated: true) })
//
//        loadMorePeople()
//    }
//
//    func setupTableView() {
//        // Setup search controller.
//        searchController = TintedSearchController(searchResultsController: nil)
//        searchController.dimsBackgroundDuringPresentation = false
//        searchController.hidesNavigationBarDuringPresentation = true
//        searchController.searchBar.delegate = self
//        searchController.searchResultsUpdater = self
//        searchController.delegate = self
//
//        navigationItem.searchController = searchController
//        navigationItem.hidesSearchBarWhenScrolling = Constants.Settings.hidesSearchBarWhenScrolling
//
//        self.definesPresentationContext = true
//
//        displayProgressFooterView()
//    }
//
//    func enableRefreshing() {
//        refreshControl = UIRefreshControl()
//        refreshControl?.addTarget(self, action: #selector(refreshTableView(_:)), for: UIControl.Event.valueChanged)
//        tableView.refreshControl = refreshControl
//    }
//
//    func disableRefreshing() {
//        refreshControl = nil
//    }
//
//    @objc func refreshTableView(_ sender: UIRefreshControl!) {
//        // Don't refresh data if we're in search mode.
//        if searchController.isActive {
//            return
//        }
//
//        // Perform animations for refreshing if we're not initiated by the user.
//        // This is needed for the initial fetch case to show activity to the user.
//        if let refreshControl = refreshControl , !refreshControl.isRefreshing {
//            refreshControl.beginRefreshing()
//        }
//
//        firstly {
//            People.getDirectory(page: self.currentPage)
//        }.then { [weak self] people in
//            guard let `self` = self else { return }
//
//            if !people.isEmpty {
//                self.filteredpeople.append(contentsOf: people)
//                self.originalPeople = self.originalPeople.union(people)
//                self.sortPeopleList()
//                self.currentPage = self.currentPage + 1
//            }
//
//            self.emptyStateLabel.isHidden = !self.filteredpeople.isEmpty
//        }.always { [weak self] in
//            self?.refreshControl?.endRefreshing()
//            self?.activityIndicator.stopAnimating()
//            self?.progressIndicator.alpha = 0
//        }.catch { (error) in
//            assertionFailure(error.localizedDescription)
//        }
//    }
//
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if let identifier = segue.identifier {
//            switch identifier {
//            case "ShowPersonProfileSegue":
//                guard
//                    let controller = segue.destination as? PersonProfileViewController,
//                    let person = sender as? Person
//                else {
//                    fatalError("Type mismatch")
//                }
//
//                controller.person = person
//                controller.delegate = self
//
//            case "InvitePersonSegue":
//                guard let controller = segue.destination as? InvitePersonController else {
//                    fatalError("InvitePersonController not found")
//                }
//
//                controller.delegate = self
//
//            default: break
//            }
//        }
//    }
//
//}
//
//extension PeopleViewController: UITableViewDataSource {
//
//    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        guard let personCell = tableView.cellForRow(at: indexPath) as? PersonTableViewCell else {
//            return
//        }
//
//        personCell.initializeCell()
//    }
//
//    func numberOfSections(in tableView: UITableView) -> Int {
//        return 1
//    }
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return filteredpeople.count
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "PersonTableViewCell") as! PersonTableViewCell
//
//        let person = filteredpeople[indexPath.row]
//        cell.configureForPerson(person)
//
//        if let url = person.avatarURL {
//            let filter = AspectScaledToFillSizeWithRoundedCornersFilter(
//                size: cell.avatarImageView.frame.size,
//                radius: cell.avatarImageView.frame.size.height / 2
//            )
//
//            cell.avatarImageView.af_setImage(withURL: url, filter: filter)
//        }
//
//        return cell
//    }
//}
//
//extension PeopleViewController: UITableViewDelegate {
//
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//
//        let person = filteredpeople[indexPath.row]
//
//        activityIndicator.startAnimating()
//
//        firstly {
//            person.getDetails()
//        }.then { [weak self] (personWithDetails) in
//            self?.performSegue(withIdentifier: "ShowPersonProfileSegue", sender: personWithDetails)
//        }.catch { [weak self] _ in
//            self?.performSegue(withIdentifier: "ShowPersonProfileSegue", sender: person)
//        }.always { [weak self] in
//            self?.activityIndicator.stopAnimating()
//        }
//
//    }
//
//}
//
//extension PeopleViewController: PersonProfileViewControllerDelegate {
//
//    func shouldShowAndStartDirectMessage(_ directMessage: VillageCore.Stream, controller: ContactPersonViewController) {
//        delegate?.shouldShowAndStartDirectMessage(directMessage, controller: self)
//    }
//}
//
//extension PeopleViewController: UISearchControllerDelegate, UISearchResultsUpdating {
//
//    func willPresentSearchController(_ searchController: UISearchController) {
//        // Disable refreshing content while searching.
//        disableRefreshing()
//    }
//
//    func willDismissSearchController(_ searchController: UISearchController) {
//        // Re-enable refreshing content after searching.
//        enableRefreshing()
//
//        filteredpeople = Array(originalPeople)
//        activityIndicator.stopAnimating()
//        self.emptyStateLabel.isHidden = !self.filteredpeople.isEmpty
//        sortPeopleList()
//        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.searchAPI), object: nil)
//    }
//
//    func updateSearchResults(for searchController: UISearchController) {
//
//    }
//
//    @objc func searchAPI() {
//        guard !loadingMorePeople else {
//            return
//        }
//
//        loadingMorePeople = true
//
//        activityIndicator.startAnimating()
//
//        firstly {
//            People.search(for: searchText, page: searchCurrentPage)
//        }.then { [weak self] people in
//            guard let `self` = self else { return }
//
//            if !people.isEmpty {
//                self.searchCurrentPage = self.searchCurrentPage + 1
//
//                // Remove the current user from search results
//                self.originalPeople = self.originalPeople.union(people.filter({ $0.id != User.current.personId }))
//
//                self.filteredpeople = self.originalPeople.filter {
//                    return ($0.firstName ?? "").localizedCaseInsensitiveContains(self.searchText)
//                        || ($0.lastName ?? "").localizedCaseInsensitiveContains(self.searchText)
//                        || ($0.displayName ?? "").localizedCaseInsensitiveContains(self.searchText)
//                        || ($0.jobTitle ?? "").localizedCaseInsensitiveContains(self.searchText)
//                }
//
//                self.sortPeopleList()
//            }
//
//            self.emptyStateLabel.isHidden = !self.filteredpeople.isEmpty
//        }.always { [weak self] in
//            self?.loadingMorePeople = false
//            self?.activityIndicator.stopAnimating()
//            self?.progressIndicator.alpha = 0
//        }.catch { (error) in
//            assertionFailure(error.localizedDescription)
//        }
//
//    }
//}
//
//extension PeopleViewController: UIScrollViewDelegate {
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        if scrollView.contentOffset.y + scrollView.frame.size.height + 30 >= scrollView.contentSize.height {
//            if !loadingMorePeople {
//                progressIndicator.alpha = 1
//                if searchController.isActive {
//                    searchAPI()
//                } else {
//                    loadMorePeople()
//                }
//            }
//        }
//    }
//}
//
//extension PeopleViewController: UISearchBarDelegate {
//
//    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//        searchCurrentPage = 1
//        self.filteredpeople = []
//        tableView.reloadData()
//        self.tableView.reloadSections([0], with: .automatic)
//        activityIndicator.startAnimating()
//
//        if searchText.trimmingCharacters(in: CharacterSet.urlQueryAllowed.inverted).isEmpty {
//            activityIndicator.stopAnimating()
//            self.searchText = searchText
//            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.searchAPI), object: nil)
//        } else {
//            self.searchText = searchText
//            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.searchAPI), object: nil)
//            self.perform(#selector(self.searchAPI), with: nil, afterDelay: 2)
//        }
//    }
//
//    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//        activityIndicator.stopAnimating()
//        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.searchAPI), object: nil)
//        searchAPI()
//    }
//}
//
//extension PeopleViewController {
//
//
//    func displayProgressFooterView() {
//        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 44))
//        progressIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
//        progressIndicator.center = headerView.center
//        headerView.addSubview(progressIndicator)
//        progressIndicator.bringSubviewToFront(headerView)
//        progressIndicator.startAnimating()
//        progressIndicator.alpha = 0
//        headerView.backgroundColor = UIColor.white
//        tableView.tableFooterView = headerView
//        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: -headerView.frame.height, right: 0)
//    }
//
//    func loadMorePeople() {
//        guard !searchController.isActive else {
//            // Don't refresh data if we're in search mode.
//            return
//        }
//
//        loadingMorePeople = true
//
//        firstly {
//            People.getDirectory(page: self.currentPage)
//        }.then { [weak self] people in
//            guard let `self` = self else { return }
//
//            if !people.isEmpty {
//                self.currentPage = self.currentPage + 1
//
//                // Remove the current user from search results
//                self.originalPeople = self.originalPeople.union(people.filter({ $0.id != User.current.personId }))
//
//                self.filteredpeople.append(contentsOf: people)
//                self.sortPeopleList()
//            }
//
//            self.emptyStateLabel.isHidden = !self.filteredpeople.isEmpty
//
//        }.always { [weak self] in
//            self?.loadingMorePeople = false
//            self?.progressIndicator.alpha = 0
//            self?.activityIndicator.stopAnimating()
//        }.catch { (error) in
//            assertionFailure(error.localizedDescription)
//        }
//    }
//
//    func sortPeopleList() {
//        let newPeopleList = filteredpeople.sorted {
//            guard let lhs = $0.firstName, let rhs = $1.firstName else {
//                return false
//            }
//
//            switch lhs.localizedCaseInsensitiveCompare(rhs) {
//            case .orderedSame:
//                return false
//
//            case .orderedAscending:
//                return true
//
//            case .orderedDescending:
//                return false
//            }
//        }
//
//        filteredpeople = newPeopleList
//        tableView.reloadData()
//        self.tableView.reloadSections([0], with: .automatic)
//    }
//}
//
//extension PeopleViewController: InvitePersonControllerDelegate {
//
//    func personInvited(emailAddress: String?) {
//        guard let emailAddress = emailAddress else {
//            return
//        }
//
//        firstly {
//            User.invite(emailAddress: emailAddress)
//        }.then { [weak self] in
//            guard let `self` = self else { return }
//
//            self.navigationController?.popViewController(animated: true)
//
//            let alert = UIAlertController.dismissable(title: "User Invited", message: "An email invitation has been sent.")
//            self.present(alert, animated: true, completion: nil)
//        }.catch { (error) in
//            let errorMessage = (error as? VillageServiceError)?.userDisplayableMessage ?? VillageServiceError.genericFailureMessage
//            let alert = UIAlertController.dismissable(title: "Error", message: errorMessage)
//            self.present(alert, animated: true, completion: nil)
//        }
//
//    }
//}
