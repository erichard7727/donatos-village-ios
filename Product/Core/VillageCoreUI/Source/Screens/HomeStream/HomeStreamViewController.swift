//
//  HomeStreamViewController.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 9/14/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit
import VillageCore
import SafariServices


final class HomeStreamViewController: UIViewController {

    fileprivate var homeStream: HomeStream?
    fileprivate var unreads: Unread?
    
    @IBOutlet private weak var headerImageView: UIImageView!
    @IBOutlet private weak var stackView: UIStackView!
    
    @IBOutlet private weak var noticesHeaderView: UIView!
    @IBOutlet private weak var noticesStackView: DataSourcedStackView!
    @IBOutlet private weak var additionalNoticesView: UIView!
    @IBOutlet private weak var additionalNoticesLabel: UILabel!

    @IBOutlet private weak var eventsStackView: DataSourcedStackView!
    @IBOutlet private weak var eventsHeaderView: UIView!
    @IBOutlet private weak var additionalEventsView: UIView!
    @IBOutlet private weak var additionalEventsLabel: UILabel!
    
    @IBOutlet private weak var newsStackView: DataSourcedStackView!
    @IBOutlet private weak var newsHeaderView: UIView!
    
    @IBOutlet private weak var kudoStackView: DataSourcedStackView!
    @IBOutlet private weak var kudoHeaderView: UIView!
    @IBOutlet private weak var kudoHeaderLabel: UILabel!
    @IBOutlet private weak var kudoViewAllButton: UIButton!
    @IBOutlet private weak var giveKudoView: UIView!
    @IBOutlet private weak var giveKudoLabel: UILabel!
    
    private let leftBarBehavior = LeftBarButtonBehavior(showing: .menuOrBack)
}

// MARK: - UIViewController Overrides

extension HomeStreamViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.largeTitleDisplayMode = .never
        
        addBehaviors([
            leftBarBehavior
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reloadViewData()

        getHomeStream()
        
        if let navController = self.navigationController {
            navController.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
            navController.navigationBar.isTranslucent = true
            navController.navigationBar.shadowImage = UIImage()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let navController = self.navigationController {
            navController.navigationBar.setBackgroundImage(nil, for: UIBarMetrics.default)
            navController.navigationBar.isTranslucent = false
            navController.navigationBar.shadowImage = nil
        }
    }
    
    

}

// MARK: - Private Methods

private extension HomeStreamViewController {

    func getHomeStream() {
        
        // load stream content
        firstly {
            HomeStream.fetch()
        }.then { [weak self] homeStream in
            self?.homeStream = homeStream
            self?.reloadViewData()
        }.catch { [weak self] error in
            let alert = UIAlertController(title: "Error", message: "There was a problem downloading your data.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { _ in self?.getHomeStream() }))
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
            self?.present(alert, animated: true, completion: nil)
        }
        
        // load unread counts
        firstly {
            Unread.getCounts()
        }.then { counts in
            self.unreads = counts
            self.reloadViewData()
        }
    }
    
    func reloadViewData() {
        
        // set header image
        headerImageView.setImage(named: "homestream-header")
        
        // Hide StackView if data is not loaded
        guard let homeStream = self.homeStream else {
            self.stackView.isHidden = true
            
            noticesStackView.isHidden = true
            eventsStackView.isHidden = true
            newsStackView.isHidden = true
            kudoStackView.isHidden = true
            
            return
        }
        self.stackView.isHidden = false
        
        // Configure badge
        if let unreads = unreads {
            let unreadStreamMessages = unreads.streams.map({ $0.count }).reduce(0, +)
            let total = unreads.notices + unreads.events + unreadStreamMessages
            leftBarBehavior.badgeText = total > 0 ? "\(total)" : nil
        }

        // Configure Notices Section
        noticesStackView.reloadData()
        noticesStackView.isHidden = (homeStream.notice?.acknowledgeRequired ?? false) == false
        
        if let unreadNotices = unreads?.notices, unreadNotices - 1 > 0 {
            let additionalNoticeCount = unreadNotices - 1
            additionalNoticesView.isHidden = false
            additionalNoticesLabel.text = "\(additionalNoticeCount) OTHER NOTICE\(additionalNoticeCount == 1 ? "":"S") NEED\(additionalNoticeCount == 1 ? "S":"") ACTION"
        } else {
            additionalNoticesView.isHidden = true
            additionalNoticesLabel.text = nil
        }
        
        
        // Configure Events Section
        eventsStackView.reloadData()
        eventsStackView.isHidden = homeStream.events.isEmpty
        
        if let unreadNotices = unreads?.events, unreadNotices - 1 > 0 {
            let additionalNoticeCount = unreadNotices - 1
            additionalEventsView.isHidden = false
            additionalEventsLabel.text = "\(additionalNoticeCount) OTHER EVENT\(additionalNoticeCount == 1 ? "":"S") NEED\(additionalNoticeCount == 1 ? "S":"") ACTION"
        } else {
            additionalEventsView.isHidden = true
            additionalEventsLabel.text = nil
        }
        
        
        // Configure News Section
        newsStackView.reloadData()
        newsStackView.isHidden = homeStream.news.isEmpty
        
        
        // Configure Kudo section
        kudoStackView.reloadData()
        kudoStackView.isHidden = homeStream.kudos.isEmpty
        kudoHeaderLabel.text = Constants.Settings.kudosSingularLong
        kudoViewAllButton.setTitle("View My \(Constants.Settings.kudosPluralShort)", for: .normal)
        giveKudoLabel.text = "GIVE A \(Constants.Settings.kudosSingularLong.uppercased())"
    }

}

//MARK: - Navigation Helpers
extension HomeStreamViewController {
    
    @IBAction func showMySchedule() {
        let url = Constants.URL.schedulerLink
        let sfvc = SFSafariViewController(url: url)
        sfvc.preferredBarTintColor = UINavigationBar.appearance().barTintColor
        sfvc.preferredControlTintColor = UINavigationBar.appearance().tintColor
        sfvc.delegate = self
        sfvc.modalTransitionStyle = .coverVertical
        self.present(sfvc, animated: true, completion: nil)
    }
    
    private func showNoticeDetail(notice: Notice) {
        guard let noticeViewController = UIStoryboard(name: "Notices", bundle: Constants.bundle).instantiateViewController(withIdentifier: "ViewNoticeVC") as? ViewNoticeViewController else {
            assertionFailure()
            return
        }
        
        noticeViewController.notice = notice
        self.show(noticeViewController, sender: nil)
    }
    
    @IBAction func viewAllNotices() {
        guard let noticesViewController = UIStoryboard(name: "Notices", bundle: Constants.bundle).instantiateInitialViewController() as? NoticeListViewController else { assertionFailure(); return }
        noticesViewController.displayType = .notices
        self.show(noticesViewController, sender: nil)
    }
    
    @IBAction func viewUnacknowledgedNotices() {
        guard let unacknowledgedNoticesViewController = UIStoryboard(name: "Notices", bundle: Constants.bundle).instantiateInitialViewController() as? NoticeListViewController else { assertionFailure(); return }
        unacknowledgedNoticesViewController.displayType = .unacknowledgedNotices
        self.show(unacknowledgedNoticesViewController, sender: nil)
    }
    
    @IBAction func viewAllEvents() {
        guard let eventsViewController = UIStoryboard(name: "Notices", bundle: Constants.bundle).instantiateInitialViewController() as? NoticeListViewController else { assertionFailure(); return }
        eventsViewController.displayType = .events
        self.show(eventsViewController, sender: nil)
    }
    
    @IBAction func viewUnrespondedEvents() {
        guard let unrespondedEventsViewController = UIStoryboard(name: "Notices", bundle: Constants.bundle).instantiateInitialViewController() as? NoticeListViewController else { assertionFailure(); return }
        unrespondedEventsViewController.displayType = .unrespondedEvents
        self.show(unrespondedEventsViewController, sender: nil)
    }
    
    @IBAction func viewAllNews() {
        guard let newsViewController = UIStoryboard(name: "Notices", bundle: Constants.bundle).instantiateInitialViewController() as? NoticeListViewController else { assertionFailure(); return }
        newsViewController.displayType = .news
        self.show(newsViewController, sender: nil)
    }
    
    @IBAction func viewMyKudos() {
        guard let kudosVC = UIStoryboard(name: "Kudos", bundle: Constants.bundle).instantiateViewController(withIdentifier: "MyKudosViewController") as? MyKudosViewController else { assertionFailure(); return }
        self.show(kudosVC, sender: nil)
    }
    
    @IBAction func giveKudo() {
        guard let giveKudoVC = UIStoryboard(name: "Kudos", bundle: Constants.bundle).instantiateViewController(withIdentifier: "GiveKudosViewController") as? GiveKudosViewController else { assertionFailure(); return }
        self.show(giveKudoVC, sender: nil)
    }
}

//MARK: - StackView Data Source
extension HomeStreamViewController: StackViewDataSource {
    
    func arrangedSubviewsForStackView(_ stackView: DataSourcedStackView) -> [UIView] {
        
        if stackView == noticesStackView, let notice = homeStream?.notice {
            return [noticesHeaderView, NoticeStreamView(notice: notice, delegate: self), additionalNoticesView]
        }
        
        if stackView == eventsStackView {
            let eventViews = homeStream?.events.map({ EventStreamView(event: $0, delegate: self) }) ?? []
            return [eventsHeaderView] + eventViews + [additionalEventsView]
        }
        
        if stackView == newsStackView {
            let newsViews = homeStream?.news.map({ NewsStreamView(news: $0, delegate: self) }) ?? []
            return [newsHeaderView] + newsViews
        }
        
        if stackView == kudoStackView {
            let piaViews = homeStream?.kudos.map({ KudoStreamView(kudo: $0, delegate: self) }) ?? []
            return [kudoHeaderView, giveKudoView] + piaViews
        }
        
        return []
    }
}


//MARK: - SFSafariViewControllerDelegate

extension HomeStreamViewController: SFSafariViewControllerDelegate {
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        self.dismiss(animated: true, completion: nil)
    }
    
}


//MARK: - NoticeStreamViewDelegate
extension HomeStreamViewController: NoticeStreamViewDelegate {
    
    func noticeStreamView(_ view: NoticeStreamView, didSelectNotice notice: Notice) {
        self.showNoticeDetail(notice: notice)
    }
}

//MARK: - EventStreamViewDelegate
extension HomeStreamViewController: EventStreamViewDelegate {
    
    func eventStreamView(_ view: EventStreamView, didSelectEvent event: Notice) {
        self.showNoticeDetail(notice: event)
    }
}

//MARK: - EventStreamViewDelegate
extension HomeStreamViewController: NewsStreamViewDelegate {
    
    func newsStreamView(_ view: NewsStreamView, didSelectNews news: Notice) {
        self.showNoticeDetail(notice: news)
    }
}

//MARK: - KudoStreamViewDelegate
extension HomeStreamViewController: KudoStreamViewDelegate {
    
    func kudoStreamView(_ view: KudoStreamView, didSelectMoreOptions kudo: Kudo) {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.modalPresentationStyle = .overFullScreen
        alert.addAction(UIAlertAction(
            title: "Report as Inappropriate",
            style: .destructive,
            handler: { [weak self] (_) in
                let confirm = UIAlertController(
                    title: "Confirm Report as Inappropriate",
                    message: "Are you sure you want to report this \(Constants.Settings.kudosSingularShort) as inappropriate? It will be removed immedaitely and your name will be recorded as the reporter.",
                    preferredStyle: .alert
                )
                confirm.addAction(UIAlertAction(
                    title: "Report as Inappropriate",
                    style: .destructive,
                    handler: { (_) in
                        kudo.flag().then({ [weak self] (flaggedKudo) in
                            self?.getHomeStream()
                        })
                }
                ))
                confirm.addAction(UIAlertAction(
                    title: "Cancel",
                    style: .cancel,
                    handler: nil
                ))
                self?.present(confirm, animated: true, completion: nil)
            }
        ))
        alert.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: nil
        ))
        
        self.present(alert, animated: true, completion: nil)
        
    }

    func kudoStreamView(_ view: KudoStreamView, didSelectPerson person: Person) {
        let vc = UIStoryboard(name: "Directory", bundle: Constants.bundle).instantiateViewController(withIdentifier: "PersonProfileViewController") as! PersonProfileViewController
        vc.person = person
        vc.delegate = self
        self.show(vc, sender: self)
    }
}

// MARK: - PersonProfileViewControllerDelegate

extension HomeStreamViewController: PersonProfileViewControllerDelegate {

    func shouldShowAndStartDirectMessage(_ directMessage: VillageCore.Stream, controller: ContactPersonViewController) {
        let dataSource = DirectMessageStreamDataSource(stream: directMessage)
        let vc = StreamViewController(dataSource: dataSource)
        self.show(UINavigationController(rootViewController: vc), sender: self)
    }

}
