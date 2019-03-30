//
//  NoticesViewController.swift
//  VillageContainerApp
//
//  Created by Justin Munger on 8/30/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit
import AlamofireImage
import VillageCore

class NoticesViewController: UIViewController {

    let footerProgressIndicator = UIActivityIndicatorView(style: .gray)
    
    var loadingMoreNotices: Bool = false
    var currentPage: Int = 1
    
    var noticesList: [String: Notices] = [:]
    var tupleArray: [(key: String, value: Notices)] = []
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var emptyStateLabel: UILabel! {
        didSet {
            emptyStateLabel.text = "There are notices."
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 100.0
        
        if !User.current.securityPolicies.contains(.manageNotices) {
            addButton.tintColor = UIColor.clear
            addButton.isEnabled = false
        }
        
        displayProgressFooterView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !noticesList.isEmpty {
            noticesList.removeAll()
            self.tupleArray.removeAll()
        }
        
        activityIndicator.startAnimating()
        getNotices()
    }
    
    func getNotices() {
        loadingMoreNotices = true
        
        firstly {
            Notices.allNoticesAndNews(page: self.currentPage)
        }.then { [weak self] (notices) in
            guard let `self` = self else { return }
            
            guard !notices.isEmpty else {
                return
            }
            
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            
            let groupedNotices = Dictionary(grouping: notices, by: {
                notice in formatter.string(from: notice.publishDate)
            })
            
            self.noticesList.merge(groupedNotices, uniquingKeysWith: { (_, new) in new })
            
            self.tupleArray = self.noticesList
                .sorted { formatter.date(from: $0.0)!.compare(formatter.date(from: $1.0)!) == .orderedDescending }
            
            self.currentPage = self.currentPage + 1
        }.catch { error in
            let alert = UIAlertController.dismissable(title: "Error", message: error.vlg_userDisplayableMessage)
            self.present(alert, animated: true, completion: nil)
        }.always { [weak self] in
            self?.activityIndicator.stopAnimating()
            self?.activityIndicator.alpha = 0
            self?.loadingMoreNotices = false
            self?.footerProgressIndicator.alpha = 0
            
            if self?.noticesList.values.flatMap({ $0 }).isEmpty == true {
                self?.emptyStateLabel.alpha = 1
            } else {
                self?.emptyStateLabel.alpha = 0
            }
            
            self?.tableView.reloadData()
            self?.tableView.reloadSections([0], with: .automatic)
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
        if identifier == "CreateNotice", User.current.securityPolicies.contains(.manageNotices) {
            return true
        }
        return false
    }
    
}

extension NoticesViewController {
    @IBAction func menuItemPressed(_ sender: UIBarButtonItem!) {
        sideMenuController?.showMenu()
    }
    
    //Delete once caching is fixed
    func scaleImage(_ attachmentImage: UIImage, desiredImageWidth: CGFloat) -> UIImage {
        let imageWidth = attachmentImage.size.width
        let widthScale = (desiredImageWidth / imageWidth) < 1.0 ? (desiredImageWidth / imageWidth) : 1.0
        
        let size = attachmentImage.size.applying(CGAffineTransform(scaleX: widthScale, y: widthScale))
        let hasAlpha = true
        let scale: CGFloat = 0.0
        
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        attachmentImage.draw(in: CGRect(origin: CGPoint.zero, size: size))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage!
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
}

extension NoticesViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return tupleArray.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return tupleArray.map({ $0.key })[section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tupleArray[section].value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let notice = tupleArray[indexPath.section].value[indexPath.row]
        switch notice.type {
        case .notice:
            let cell = tableView.dequeueReusableCell(withIdentifier: "NoticeCell", for: indexPath) as! NoticeCell
            
            cell.selectionStyle = .none
            if notice.isAcknowledged || !notice.acknowledgeRequired {
                cell.markAccepted(true)
            } else {
                cell.markAccepted(false)
            }
            
            if User.current.securityPolicies.contains(.manageNotices) {
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
            
            cell.delegate = self
            
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

extension NoticesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedNotice = tupleArray[indexPath.section].value[indexPath.row]
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

extension NoticesViewController: NoticeCellDelegate {
    func percentageButtonPressed(noticeId: String) {
        guard let notice = tupleArray.flatMap({ $0.value }).first(where: { $0.id == noticeId }) else {
            assertionFailure()
            return
        }
        performSegue(withIdentifier: "NoticeAcknowledgements", sender: notice)
    }
}

extension NoticesViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y + scrollView.frame.size.height + 30 >= scrollView.contentSize.height {
            if !loadingMoreNotices {
                footerProgressIndicator.alpha = 1
                getNotices()
            }
        }
    }
}
