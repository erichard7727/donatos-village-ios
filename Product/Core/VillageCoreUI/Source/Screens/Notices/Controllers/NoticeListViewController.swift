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

final class NoticeListViewController: UIViewController {
    
    // MARK: - Public Properties
    
    enum DisplayType {
        case all
        case notices
        case news
        case events
        
        fileprivate var title: String {
            switch self {
            case .all:
                return "News / Notices"
                
            case .notices:
                return "Notices"
                
            case.news:
                return "News"
                
            case .events:
                return "Events"
            }
        }
        
        fileprivate func paginated() -> SectionedPaginated<Notice> {
            switch self {
            case .all:
                return Notices.allNoticesAndNewsPaginated()
                
            case .notices:
                return Notices.allNoticesPaginated()
                
            case.news:
                return Notices.allNewsPaginated()
                
            case .events:
                return Notices.allEventsPaginated()
            }
        }
        
        fileprivate var emptyMessage: String {
            switch self {
            case .all, .notices:
                return "There are no notices to display."
                
            case.news:
                return "There is no news to display."
                
            case .events:
                return "There are no events to display."
            }
        }
    }
    
    var displayType: DisplayType = .all {
        didSet {
            self.title = displayType.title
            notices = displayType.paginated()
        }
    }
    
    // MARK: - Private Properties
    
    /// All paginated notices available to the user
    private var notices: SectionedPaginated<Notice>! {
        didSet {
            notices.delegate = self
            if isViewLoaded {
                tableView.reloadData()
            }
        }
    }
        
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
        
        if notices == nil {
            notices = displayType.paginated()
        }
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
        if segue.identifier == "ViewNotice", let notice = sender as? Notice {
            guard let controller = segue.destination as? ViewNoticeViewController else {
                fatalError("ViewNoticeViewController not found")
            }
            controller.notice = notice
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
        case .events?:
            #warning("TODO - Create separate events cell?")
            let cell = tableView.dequeueReusableCell(withIdentifier: "NewsCell", for: indexPath) as! NewsCell
            NewsTableViewCellConfiguartor().configure(cell, forDisplaying: notice)
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
                    case .events: return "events"
                    }
                }(),
                AnalyticsParameterItemName: selectedNotice.title
            ]
        )
        
        performSegue(withIdentifier: "ViewNotice", sender: selectedNotice)
    }
    
}

// MARK: - DZNEmptyDataSetSource

extension NoticeListViewController: DZNEmptyDataSetSource {
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: displayType.emptyMessage, attributes: nil)
    }
    
}

// MARK: - DZNEmptyDataSetDelegate

extension NoticeListViewController: DZNEmptyDataSetDelegate {
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        // Only show an empty data set if loading is not in-progress
        return loadingNoticesContainer.isHidden
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
