//
//  NoticeListViewController.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 5/27/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit
import VillageCore
import Promises
import DZNEmptyDataSet

class NoticeTableViewCellConfiguartor {
    
    let displayAcknowledgements: () -> Void
    
    init(displayAcknowledgements: @escaping () -> Void) {
        self.displayAcknowledgements = displayAcknowledgements
    }
    
    func configure(_ cell: NoticeCell, forDisplaying notice: Notice?) {
        cell.selectionStyle = .none
        cell.setLoading(notice == nil)
        
        if let notice = notice {
            if notice.isAcknowledged || !notice.acknowledgeRequired {
                cell.markAccepted(true)
            } else {
                cell.markAccepted(false)
            }
            
            if Constants.Settings.manageNoticesEnabled && User.current.securityPolicies.contains(.manageNotices) {
                if notice.acknowledgeRequired {
                    if notice.isAcknowledged {
                        let greenColor = UIColor.init(red: 68/255.0, green: 176/255.0, blue: 49/255.0, alpha: 1.0)
                        cell.displayPercentage(notice.acceptedPercent.description, color: greenColor)
                    } else {
                        let orangeColor = UIColor.init(red: 251/255.0, green: 149/255.0, blue: 50/255.0, alpha: 1.0)
                        cell.displayPercentage(notice.acceptedPercent.description, color: orangeColor)
                    }
                } else {
                    cell.removePercentage()
                }
            }
            
            cell.noticeTitleLabel.text = notice.title
            cell.noticeId = notice.id
            cell.noticeBody = notice.body
            cell.acknowledged = notice.isAcknowledged
            cell.acknowledgementRequired = notice.acknowledgeRequired
            
            cell.percentageButtonPressed = { [weak self] in
                self?.displayAcknowledgements()
            }
        } else {
            cell.markAccepted(false)
            cell.removePercentage()
            cell.noticeTitleLabel.text = nil
            cell.noticeId = ""
            cell.noticeBody = ""
            cell.acknowledged = false
            cell.acknowledgementRequired = false
            cell.percentageButtonPressed = nil
        }
    }
    
}

class NewsTableViewCellConfiguartor {
    
    func configure(_ cell: NewsCell, forDisplaying news: Notice?) {
        cell.selectionStyle = .none
        cell.setLoading(news == nil)
        
        if let news = news {
            cell.newsTitleLabel.text = news.title
            cell.newsAuthorLabel.text = news.person.displayName
                .flatMap({ "Posted By \($0)" })
            cell.newsId = news.id
            cell.thumbnailImageURL = news.mediaAttachments
                .first(where: { $0.isThumbnailImage })
                .flatMap({ $0.url })
        } else {
            cell.newsTitleLabel.text = nil
            cell.newsAuthorLabel.text = nil
            cell.newsId = ""
            cell.thumbnailImageURL = nil
        }
    }
    
}

class EventTableViewCellConfiguartor {

    func configure(_ cell: NoticeCell, forDisplaying event: Notice?) {
        cell.selectionStyle = .none
        cell.setLoading(event == nil)

        if let event = event {

            cell.states = [
                NoticeCell.State(
                    primaryColor: UIColor(red: 0.68, green: 0.84, blue: 0.51, alpha: 1.00),
                    secondaryColor: UIColor(red: 0.95, green: 0.97, blue: 0.91, alpha: 1.00),
                    actionLabel: "GOING",
                    actionImage: UIImage.named("notice-needs-action")!
                ),
                NoticeCell.State(
                    primaryColor: UIColor(red: 0.70, green: 0.62, blue: 0.86, alpha: 1.00),
                    secondaryColor: UIColor(red: 0.93, green: 0.91, blue: 0.96, alpha: 1.00),
                    actionLabel: "INTERESTED",
                    actionImage: UIImage.named("notice-interested")!
                ),
                NoticeCell.State(
                    primaryColor: UIColor(red: 0.90, green: 0.45, blue: 0.45, alpha: 1.00),
                    secondaryColor: UIColor(red: 1.00, green: 0.92, blue: 0.93, alpha: 1.00),
                    actionLabel: "NOT GOING",
                    actionImage: UIImage.named("notice-not-going")!
                ),
                NoticeCell.State(
                    primaryColor: UIColor(red: 1.00, green: 0.72, blue: 0.30, alpha: 1.00),
                    secondaryColor: UIColor(red: 1.00, green: 0.95, blue: 0.88, alpha: 1.00),
                    actionLabel: "RSVP NEEDED",
                    actionImage: UIImage.named("notice-rsvp-needed")!
                ),
                NoticeCell.State(
                    primaryColor: UIColor(red: 0.51, green: 0.83, blue: 0.98, alpha: 1.00),
                    secondaryColor: UIColor(red: 0.88, green: 0.96, blue: 1.00, alpha: 1.00),
                    actionLabel: "NO RSVP NEEDED",
                    actionImage: UIImage.named("notice-no-rsvp-needed")!
                ),
            ]

            switch (event.eventRsvpStatus, event.acknowledgeRequired) {
            case (.yes, _):
                cell.setState(index: 0)
            case (.maybe, _):
                cell.setState(index: 1)
            case (.no, _):
                cell.setState(index: 2)
            case (.none, true):
                cell.setState(index: 3)
            case (.none, false):
                cell.setState(index: 4)
            }

            cell.removePercentage()

            let mutableTitle = NSMutableAttributedString(
                string: event.title,
                attributes: [
                    .font: UIFont(name: "ProximaNova-Semibold", size: 15.0)!,
                    .foregroundColor: #colorLiteral(red: 0.349019587, green: 0.3490196168, blue: 0.3490196168, alpha: 1)
                ]
            )



            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short

            let dateTimes = [
                event.eventStartDateTime.flatMap(formatter.string(from:)).flatMap({ "Starts: \($0)" }),
                event.eventEndDateTime.flatMap(formatter.string(from:)).flatMap({ "Ends: \($0)" }),
            ]
                .compactMap({ $0 })
                .joined(separator: "\n")

            if !dateTimes.isEmpty {
                mutableTitle.append(NSAttributedString(
                    string: "\n\(dateTimes)",
                    attributes: [
                        .font: UIFont(name: "ProximaNova-Regular", size: 14.0)!,
                        .foregroundColor: #colorLiteral(red: 0.349019587, green: 0.3490196168, blue: 0.3490196168, alpha: 1)
                    ])
                )
            }

            cell.noticeTitleLabel.attributedText = mutableTitle
            cell.noticeId = event.id
            cell.noticeBody = event.body
            cell.acknowledged = event.isAcknowledged
            cell.acknowledgementRequired = event.acknowledgeRequired
        } else {
            cell.markAccepted(false)
            cell.removePercentage()
            cell.noticeTitleLabel.text = nil
            cell.noticeId = ""
            cell.noticeBody = ""
            cell.acknowledged = false
            cell.acknowledgementRequired = false
            cell.percentageButtonPressed = nil
        }
    }

}

final class NoticeListViewController: UIViewController {
    
    // MARK: - Public Properties
    
    enum DisplayType {
        case all
        case notices
        case unacknowledgedNotices
        case news
        case events
        case unrespondedEvents
        
        fileprivate var title: String {
            switch self {
            case .all:
                return "News / Notices"
                
            case .notices:
                return "Notices"
                
            case .unacknowledgedNotices:
                return "Notices Needing Action"
                
            case.news:
                return "News"
                
            case .events, .unrespondedEvents:
                return "Events"
            }
        }
        
        fileprivate func paginated() -> SectionedPaginated<Notice> {
            switch self {
            case .all:
                return Notices.allNoticesAndNewsPaginated()
                
            case .notices:
                return Notices.allNoticesPaginated()
                
            case .unacknowledgedNotices:
                return Notices.unacknowledgedNoticesPaginated()
                
            case.news:
                return Notices.allNewsPaginated()
                
            case .events:
                return Notices.allEventsPaginated()
                
            case .unrespondedEvents:
                return Notices.unrespondedEventsPaginated()
            }
        }

        fileprivate func searchFor(_ searchText: String) -> SectionedPaginated<Notice> {
            switch self {
            case .all:
                return Notices.searchNoticesAndNewsPaginated(for: searchText)

            case .notices, .unacknowledgedNotices:
                return Notices.searchNoticesPaginated(for: searchText)

            case.news:
                return Notices.searchNewsPaginated(for: searchText)

            case .events, .unrespondedEvents:
                return Notices.searchEventsPaginated(for: searchText)
            }
        }
        
        fileprivate var emptyMessage: String {
            switch self {
            case .all, .notices, .unacknowledgedNotices:
                return "There are no notices to display."
                
            case.news:
                return "There is no news to display."
                
            case .events, .unrespondedEvents:
                return "There are no events to display."
            }
        }
    }
    
    var displayType: DisplayType = .all {
        didSet {
            self.title = displayType.title
            allNotices = displayType.paginated()
        }
    }
    
    // MARK: - Private Properties
    
    /// Returns the appropriate paginated notices based on whether
    /// the user is performing a search or browsing all available notices
    private var notices: SectionedPaginated<Notice>! {
        return searchedNotices ?? allNotices
    }

    /// All paginated notices available to the user
    private var allNotices: SectionedPaginated<Notice>! {
        didSet {
            allNotices.delegate = self
            if isViewLoaded {
                tableView.reloadData()
            }
        }
    }

    /// Paginated notices represented the user's search. This will be `nil`
    /// if the user is not currently searching
    private var searchedNotices: SectionedPaginated<Notice>? {
        didSet {
            searchedNotices?.delegate = self
            guard searchedNotices != nil else { return }
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
    
    @IBOutlet private var addButton: UIBarButtonItem! {
        didSet {
            if !Constants.Settings.manageNoticesEnabled ||
                !User.current.securityPolicies.contains(.manageNotices) {
                addButton.tintColor = UIColor.clear
                addButton.isEnabled = false
            }
        }
    }
    
    @IBOutlet private var loadingNoticesContainer: UIView!
    
}

// MARK: - UIViewController Overrides

extension NoticeListViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBehaviors([
            LeftBarButtonBehavior(showing: .menuOrBack),
        ])
        
        title = displayType.title
        
        if allNotices == nil {
            allNotices = displayType.paginated()
        }

        navigationItem.searchController = searchController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if notices.needsFetching {
            loadingNoticesContainer.isHidden = false
            notices.fetchValues(at: [])
        } else {
            loadingNoticesContainer.isHidden = true
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
        case "CreateNotice" where !Constants.Settings.manageNoticesEnabled || !User.current.securityPolicies.contains(.manageNotices):
            assertionFailure("Programmer Error: Invalid segue when user does not have permission to create notices!")
            return false
            
        default:
            return true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ViewNotice", let indexPath = sender as? IndexPath {
            guard let notice = notices.value(at: indexPath) else {
                assertionFailure()
                return
            }
            guard let controller = segue.destination as? ViewNoticeViewController else {
                fatalError("ViewNoticeViewController not found")
            }
            controller.notice = notice
            controller.didUpdateNotice = { [weak self] updatedNotice in
                guard let `self` = self else { return }
                let currentNotice = self.notices.value(at: indexPath)
                guard currentNotice == updatedNotice else {
                    assertionFailure("The items seem to have gotten out of sync.")
                    return
                }
                self.notices.update(item: updatedNotice, at: indexPath)
                self.tableView.reloadRows(at: [indexPath], with: .none)
            }
        } else if segue.identifier == "NoticeAcknowledgements", let notice = sender as? Notice {
            guard let controller = segue.destination as? NoticeAcknowledgementsViewController else {
                fatalError("ViewNoticeViewController not found")
            }
            controller.notice = notice
        } else if segue.identifier == "CreateNotice" {
            // Nothing to configure
        } else {
            assertionFailure()
        }
    }
}

// MARK: - Public Methods

extension NoticeListViewController { }

// MARK: - Target/Action

@objc private extension NoticeListViewController { }

// MARK: - Private Methods

private extension NoticeListViewController {
    
    class Section: Comparable {
        
        let title: String
        var notices: [Notice]
        
        private let date: Date
        
        fileprivate static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter
        }()
        
        init(title: String, notices: [Notice]) {
            self.title = title
            self.notices = notices
            self.date = Section.dateFormatter.date(from: title)!
        }
        
        // Comparable
        
        static func < (lhs: NoticeListViewController.Section, rhs: NoticeListViewController.Section) -> Bool {
            return Calendar.current.compare(lhs.date, to: rhs.date, toGranularity: .day) == .orderedAscending
        }
        
        static func == (lhs: NoticeListViewController.Section, rhs: NoticeListViewController.Section) -> Bool {
            return Calendar.current.isDate(lhs.date, equalTo: rhs.date, toGranularity: .day)
        }
    }

    func setSearchBarEnabled(_ isEnabled: Bool) {
        searchController.searchBar.isUserInteractionEnabled = isEnabled
        searchController.searchBar.alpha = isEnabled ? 1.0 : 0.75
    }
    
}

// MARK: - UITableViewDataSource

extension NoticeListViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return notices.numberOfSections
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return notices.title(for: section)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notices.numberOfRowsInSection(section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let notice = notices.value(at: indexPath)
        switch notice?.type {
        case .notice?, .none:
            let cell = tableView.dequeueReusableCell(withIdentifier: "NoticeCell", for: indexPath) as! NoticeCell
            let configurator = NoticeTableViewCellConfiguartor(displayAcknowledgements: { [weak self] in
                self?.performSegue(withIdentifier: "NoticeAcknowledgements", sender: notice)
            })
            configurator.configure(cell, forDisplaying: notice)
            return cell
        case .news?:
            let cell = tableView.dequeueReusableCell(withIdentifier: "NewsCell", for: indexPath) as! NewsCell
            NewsTableViewCellConfiguartor().configure(cell, forDisplaying: notice)
            return cell
        case .event?:
            let cell = tableView.dequeueReusableCell(withIdentifier: "NoticeCell", for: indexPath) as! NoticeCell
            EventTableViewCellConfiguartor().configure(cell, forDisplaying: notice)
            return cell
        }
    }
    
}

// MARK: - UITableViewDataSourcePrefetching

extension NoticeListViewController: UITableViewDataSourcePrefetching {
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        if indexPaths.contains(where: notices.isLoadingValue) {
            notices.fetchValues(at: indexPaths)
        }
    }
    
}

// MARK: - UITableViewDelegate

extension NoticeListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if notices.isLoadingValue(at: indexPath) {
            // can't select a cell that is loading
            return nil
        } else {
            return indexPath
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedNotice = notices.value(at: indexPath) else {
            assertionFailure("User should not be able to select a cell that is loading!")
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }

        AnalyticsService.logEvent(
            name: AnalyticsEventViewItem,
            parameters: [
                AnalyticsParameterItemLocationID: "news and notice",
                AnalyticsParameterItemCategory: {
                    switch selectedNotice.type {
                    case .notice: return "notice"
                    case .news: return "news"
                    case .event: return "event"
                    }
                }(),
                AnalyticsParameterItemName: selectedNotice.title
            ]
        )

        performSegue(withIdentifier: "ViewNotice", sender: indexPath)
    }
    
}

// MARK: - DZNEmptyDataSetSource

extension NoticeListViewController: DZNEmptyDataSetSource {
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        if searchController.isActive {
            let title = NSMutableAttributedString(string: "No \(displayType.title) found", attributes: nil) // reg
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
            return NSAttributedString(string: displayType.emptyMessage, attributes: nil) // reg
        }
    }
    
}

// MARK: - DZNEmptyDataSetDelegate

extension NoticeListViewController: DZNEmptyDataSetDelegate {
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        // Only show an empty data set if loading is not in-progress
        return loadingNoticesContainer.isHidden
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

extension NoticeListViewController: SectionedPaginationDelegate {
    
    func onFetchCompleted(deleteRows: [IndexPath],
                          insertRows: [IndexPath],
                          deleteSections: IndexSet,
                          insertSections: IndexSet) {
        loadingNoticesContainer.isHidden = true
        
        tableView.performBatchUpdates({
            tableView.deleteRows(at: deleteRows, with: .automatic)
            tableView.insertRows(at: insertRows, with: .automatic)
            tableView.deleteSections(deleteSections, with: .automatic)
            tableView.insertSections(insertSections, with: .automatic)
        }, completion: nil)
    }
    
    func onFetchFailed(with error: Error) {
        loadingNoticesContainer.isHidden = true
        tableView.reloadEmptyDataSet()
        let alert = UIAlertController.dismissable(title: "Error", message: error.vlg_userDisplayableMessage)
        self.present(alert, animated: true, completion: nil)
    }
    
}

// MARK: - UISearchResultsUpdating

extension NoticeListViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text ?? ""

        guard !searchText.isEmpty else {
            self.loadingNoticesContainer.isHidden = true
            searchedNotices = nil
            tableView.reloadData()
            return
        }

        searchedNotices = displayType.searchFor(searchText)
        self.loadingNoticesContainer.isHidden = false
        searchDebouncer.debounce(afterTimeInterval: 1) { [weak self] in
            self?.notices.fetchValues(at: [])
        }
    }

}
