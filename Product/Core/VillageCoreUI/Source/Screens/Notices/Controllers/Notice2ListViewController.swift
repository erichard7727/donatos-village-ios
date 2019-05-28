//
//  Notice2ListViewController.swift
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

final class Notice2ListViewController: UIViewController {
    
    // MARK: - Public Properties
    
    // MARK: - Private Properties
    
    /// All paginated notices available to the user
    private lazy var notices: Paginated<Notice> = {
        let paginated = Notices.allNoticesAndNewsPaginated()
        paginated.delegate = self
        return paginated
    }()
        
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

extension Notice2ListViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBehaviors([
            LeftBarButtonBehavior(showing: .menuOrBack),
        ])
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

extension Notice2ListViewController { }

// MARK: - Target/Action

@objc private extension Notice2ListViewController { }

// MARK: - Private Methods

private extension Notice2ListViewController { }

// MARK: - UITableViewDataSource

extension Notice2ListViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        #warning("TODO - how to do sectioned paginated results?")
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        #warning("TODO - how to do sectioned paginated results?")
        return "TODO" // sections[section].title
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notices.totalCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let notice = notices.value(at: indexPath.row)
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
        }
    }
    
}

// MARK: - UITableViewDataSourcePrefetching

extension Notice2ListViewController: UITableViewDataSourcePrefetching {
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        if indexPaths.contains(where: notices.isLoadingValue) {
            notices.fetchValues(at: indexPaths)
        }
    }
    
}

// MARK: - UITableViewDelegate

extension Notice2ListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if notices.isLoadingValue(at: indexPath) {
            // can't select a cell that is loading
            return nil
        } else {
            return indexPath
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedNotice = notices.value(at: indexPath.row) else {
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
                    }
                }(),
                AnalyticsParameterItemName: selectedNotice.title
            ]
        )
        
        performSegue(withIdentifier: "ViewNotice", sender: selectedNotice)
    }
    
}

// MARK: - DZNEmptyDataSetSource

extension Notice2ListViewController: DZNEmptyDataSetSource {
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "There are no notices to display.", attributes: nil)
    }
    
}

// MARK: - DZNEmptyDataSetDelegate

extension Notice2ListViewController: DZNEmptyDataSetDelegate {
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        // Only show an empty data set if loading is not in-progress
        return loadingNoticesContainer.isHidden
    }
    
}

// MARK: - PaginationDelegate

extension Notice2ListViewController: PaginationDelegate {
    
    func onFetchCompleted(with newIndexPathsToReload: [IndexPath]?) {
        guard let newIndexPathsToReload = newIndexPathsToReload else {
            // Show the first page of results
            loadingNoticesContainer.isHidden = true
            tableView.reloadData()
            return
        }
        
        // Reload the next page of results
        let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows ?? []
        let indexPathsToReload = notices.visibleIndexPathsToReload(indexPathsForVisibleRows, intersecting: newIndexPathsToReload)
        tableView.reloadRows(at: indexPathsToReload, with: .automatic)
    }
    
    func onFetchFailed(with error: Error) {
        let alert = UIAlertController.dismissable(title: "Error", message: error.vlg_userDisplayableMessage)
        self.present(alert, animated: true, completion: nil)
    }
    
}
