//
//  NewHomeStreamViewController.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 9/14/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit
import VillageCore

final class NewHomeStreamViewController: UIViewController {

    fileprivate var homeStream: NewHomeStream?
    fileprivate var unreads: Unread?
    
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
    
    @IBOutlet private weak var piaStackView: DataSourcedStackView!
    @IBOutlet private weak var piaHeaderView: UIView!
    @IBOutlet private weak var givePiaView: UIView!
}

// MARK: - UIViewController Overrides

extension NewHomeStreamViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        addBehaviors([
            LeftBarButtonBehavior(showing: .menuOrBack)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        getHomeStream()
    }

}

// MARK: - Private Methods

private extension NewHomeStreamViewController {

    func getHomeStream() {
        
        // load stream content
        firstly {
            NewHomeStream.fetch()
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
        
        // Hide StackView if data is not loaded
        guard let homeStream = self.homeStream else {
            self.stackView.isHidden = true
            return
        }
        self.stackView.isHidden = false
        
        
        // Configure Notices Section
        noticesStackView.isHidden = (homeStream.notice?.acknowledgeRequired ?? false) == false
        noticesStackView.reloadData()
        
        if let unreadNotices = unreads?.notices {
            additionalNoticesView.isHidden = false
            additionalNoticesLabel.text = "\(unreadNotices) OTHER NOTICE\(unreadNotices == 1 ? "":"S") NEED\(unreadNotices == 1 ? "S":"") ACTION"
        } else {
            additionalNoticesView.isHidden = true
            additionalNoticesLabel.text = nil
        }
        
        
        // Configure Events Section
        eventsStackView.reloadData()
        eventsStackView.isHidden = homeStream.events.isEmpty
        
        if let unreadNotices = unreads?.events {
            additionalEventsView.isHidden = false
            additionalEventsLabel.text = "\(unreadNotices) OTHER EVENT\(unreadNotices == 1 ? "":"S") NEED\(unreadNotices == 1 ? "S":"") ACTION"
        } else {
            additionalEventsView.isHidden = true
            additionalEventsLabel.text = nil
        }
        
        
        // Configure News Section
        newsStackView.reloadData()
        newsStackView.isHidden = homeStream.news.isEmpty
        
        
        // Configure PIA section
        piaStackView.reloadData()
        piaStackView.isHidden = homeStream.kudos.isEmpty
    }

}

//MARK: - StackView Data Source
extension NewHomeStreamViewController: StackViewDataSource {
    
    func arrangedSubviewsForStackView(_ stackView: DataSourcedStackView) -> [UIView] {
        
        if stackView == noticesStackView, let notice = homeStream?.notice {
            return [noticesHeaderView, NoticeStreamView(notice: notice), additionalNoticesView]
        }
        
        if stackView == eventsStackView {
            let eventViews = homeStream?.events.map({ EventStreamView(event: $0) }) ?? []
            return [eventsHeaderView] + eventViews + [additionalEventsView]
        }
        
        if stackView == newsStackView {
            let newsViews = homeStream?.news.map({ NewsStreamView(news: $0) }) ?? []
            return [newsHeaderView] + newsViews
        }
        
        if stackView == piaStackView {
            let piaViews = homeStream?.kudos.map({ PIAStreamView(kudo: $0) }) ?? []
            return [piaHeaderView] + piaViews
        }
        
        return []
    }
}
