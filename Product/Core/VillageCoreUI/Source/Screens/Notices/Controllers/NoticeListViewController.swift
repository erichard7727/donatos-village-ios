//
//  NoticeListViewController.swift
//  VillageContainerApp
//
//  Created by Rob Feldmann on 3/31/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit
import AlamofireImage
import VillageCore

final class NoticeListViewController: UIViewController {
    
    private class Section: Comparable {

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
    
    @IBOutlet private weak var tableView: UITableView! {
        didSet {
            tableView.estimatedRowHeight = 100.0
            
            tableView.refreshControl = self.refreshControl
            
            if let footerHeight = tableView.tableFooterView?.bounds.height {
                tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: -footerHeight, right: 0)
            }
        }
    }
    
    @IBOutlet private weak var addButton: UIBarButtonItem! {
        didSet {
            if !Constants.Settings.manageNoticesEnabled || !User.current.securityPolicies.contains(.manageNotices) {
                addButton.tintColor = UIColor.clear
                addButton.isEnabled = false
            }
        }
    }
    
    @IBOutlet private weak var loadingIndicator: UIActivityIndicatorView!
    
    @IBOutlet private weak var emptyStateLabel: UILabel! {
        didSet {
            emptyStateLabel.text = "There are no notices."
        }
    }
    
    @IBOutlet private var footerProgressIndicator: UIActivityIndicatorView!
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        return refreshControl
    }()
    
    private var sections: [Section] = []
    private var isLoadingMoreData = false
    private var currentPage = 0
    
    private var isAllDataLoaded = false {
        didSet {
            self.emptyStateLabel.isHidden = !sections.isEmpty
        }
    }
    
    private var needsRefresh = false
}

// MARK: - UIViewController Overrides

extension NoticeListViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: Notification.Name.Notice.WasAcknowledged, object: nil, queue: nil) { [weak self] (_) in
            self?.needsRefresh = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if needsRefresh || currentPage == 0 {
            loadNotices(page: 1, isRefreshing: needsRefresh)
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
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "CreateNotice",
           (Constants.Settings.manageNoticesEnabled && User.current.securityPolicies.contains(.manageNotices)) {
            return true
        }
        return false
    }
    
}

// MARK: - Private Methods

private extension NoticeListViewController {
    
    func loadNotices(page: Int, isRefreshing: Bool = false) {
        guard isRefreshing || (!isLoadingMoreData && !isAllDataLoaded) else {
            return
        }
        
        if isRefreshing {
            isAllDataLoaded = false
        }
        
        defer {
            isLoadingMoreData = true
        }
        
        if isRefreshing {
            // The the refreshControl indicate loading
        } else if page > 1 {
            footerProgressIndicator.startAnimating()
        } else {
            loadingIndicator.startAnimating()
        }
        
        firstly {
            Notices.allNoticesAndNews(page: page)
        }.then { [weak self] (notices) in
            guard let `self` = self else { return }
            
            if isRefreshing {
                self.sections = []
            }
            
            guard !notices.isEmpty else {
                self.isAllDataLoaded = true
                return
            }
            
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            
            let groupedNotices = Dictionary(grouping: notices, by: {
                notice in formatter.string(from: notice.publishDate)
            })
            
            var sections = self.sections
            
            groupedNotices.forEach({ (title, notices) in
                if let section = sections.first(where: { $0.title == title }) {
                    section.notices += notices
                } else {
                    sections += [Section(title: title, notices: notices)]
                }
            })
            
            self.sections = sections.sorted(by: >)
            
            self.currentPage = page
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }.catch { error in
            let alert = UIAlertController.dismissable(title: "Error", message: error.vlg_userDisplayableMessage)
            self.present(alert, animated: true, completion: nil)
        }.always { [weak self] in
            self?.isLoadingMoreData = false
            self?.needsRefresh = false
            
            if isRefreshing {
                self?.refreshControl.endRefreshing()
            } else if page > 1 {
                self?.footerProgressIndicator.stopAnimating()
            } else {
                self?.loadingIndicator.stopAnimating()
            }
        }
    }
    
    @IBAction func menuItemPressed(_ sender: UIBarButtonItem!) {
        sideMenuController?.showMenu()
    }
    
    @objc func refreshData() {
        guard !isLoadingMoreData else {
            refreshControl.endRefreshing()
            return
        }
        
        loadNotices(page: 1, isRefreshing: true)
    }
}

extension NoticeListViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].notices.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let notice = sections[indexPath.section].notices[indexPath.row]
        
        switch notice.type {
        case .notice:
            let cell = tableView.dequeueReusableCell(withIdentifier: "NoticeCell", for: indexPath) as! NoticeCell
            
            cell.selectionStyle = .none
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
                self?.performSegue(withIdentifier: "NoticeAcknowledgements", sender: notice)
            }
            
            return cell
            
        case .news:
            let cell = tableView.dequeueReusableCell(withIdentifier: "NewsCell", for: indexPath) as! NewsCell
            
            cell.selectionStyle = .none
            cell.newsTitleLabel.text = notice.title
            cell.newsAuthorLabel.text = notice.person.displayName
            //cell.newsDescriptionLabel.text = notice.body
            cell.newsId = notice.id
            cell.activityIndicator.startAnimating()
            cell.activityIndicator.alpha = 1
            cell.thumbnailImageURL = notice.mediaAttachments
                .first(where: { $0.isThumbnailImage })
                .flatMap({ $0.url })
            
            return cell
        }
        
    }
}

extension NoticeListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastSection = sections.count - 1
        let lastRow = sections[indexPath.section].notices.count - 1
        
        if indexPath.section == lastSection && indexPath.row == lastRow {
            loadNotices(page: currentPage + 1)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedNotice = sections[indexPath.section].notices[indexPath.row]
        
        AnalyticsService.logEvent(
            name: AnalyticsEventViewItem,
            parameters: [
                AnalyticsParameterItemLocationID: "news and notice",
                AnalyticsParameterItemCategory: {
                    switch selectedNotice.type {
                    case .notice: return "notice"
                    case .news: return "news"
                    }
                }(),
                AnalyticsParameterItemName: selectedNotice.title
            ]
        )
        
        performSegue(withIdentifier: "ViewNotice", sender: selectedNotice)
    }
    
}
