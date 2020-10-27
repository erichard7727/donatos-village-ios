
//
//  DirectMessagesViewController.swift
//  VillageCore
//
//  Created by Michael Miller on 1/25/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import Foundation
import UIKit
//import FirebaseAnalytics
import AlamofireImage
import VillageCore

// MARK: DirectMessagesViewController
final class DMViewController: UIViewController, NavBarDisplayable {
    
    var directMessages: VillageCore.Streams = []
        
    fileprivate var selectedDirectMessage: VillageCore.Stream?
    
    var preloadGroupId: String!
    var unreadCounts: [String: Int]?
    fileprivate var shouldShowDM: Bool = false
    
    lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.tintColor = UIColor.darkGray
        control.addTarget(self, action: #selector(onRefresh(_:)), for: .valueChanged)
        return control
    }()

    let progressIndicator = UIActivityIndicatorView(style: .gray)
    
    @IBOutlet fileprivate weak var tableView: UITableView! {
        didSet {
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 90.0
            tableView.addSubview(refreshControl)
            tableView.separatorStyle = .none
            displayProgressFooterView()
        }
    }
    
    @IBOutlet weak var emptyTableViewLabel: UILabel!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBehaviors([
            LeftBarButtonBehavior(showing: .menuOrBack)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setOpaqueNavbarAppearance(for: navigationItem, in: navigationController)
        refreshTableView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            if identifier == "PushNewMessagesSegue" {
                guard let controller = segue.destination as? SelectPeopleViewController else {
                    fatalError("SelectPeopleViewController not set")
                }
                controller.delegate = self
            }
        }
    }

    /// Unwind segue point.
    @IBAction func unwindToSegue(_ segue: UIStoryboardSegue) {}
    
    // MARK: Refreshing
    
    @objc internal func onRefresh(_ sender: Any? = nil) {
        refreshControl.beginRefreshing()
        refreshTableView() { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }
    
    fileprivate func refreshTableView(completionHandler: (() -> Void)? = nil) {
        
        if directMessages.isEmpty {
            activityIndicator.startAnimating()
        }
        
        progressIndicator.startAnimating()
        
        firstly {
            Streams.directMessages()
        }.then { [weak self] streams in
            guard let `self` = self else { return }
            
            self.emptyTableViewLabel.text = "You haven't sent or received any direct messages yet."
            self.emptyTableViewLabel.isHidden = !streams.isEmpty
            
            self.directMessages = streams.sorted{
                let firstLastMessageDate = villageCoreAPIDateFormatter.date(from: $0.details?.lastMessageDate ?? "") ?? Date.distantPast
                let secondLastMessageDate = villageCoreAPIDateFormatter.date(from: $1.details?.lastMessageDate ?? "") ?? Date.distantPast
                
                if self.preloadGroupId != nil && $0.id == self.preloadGroupId {
                    self.selectedDirectMessage = $0
                } else if self.preloadGroupId != nil && $0.id == self.preloadGroupId {
                    self.selectedDirectMessage = $1
                }
                
                return firstLastMessageDate.compare(secondLastMessageDate) == .orderedDescending
            }
            var currentUnreadCounts = [String: Int]()
            
            for directMessage in self.directMessages {
                currentUnreadCounts[directMessage.id] = 0
            }
            
            self.unreadCounts = currentUnreadCounts
            
            self.tableView.reloadSections([0], with: .automatic)
            
            if self.preloadGroupId != nil && self.selectedDirectMessage != nil {
                self.showDMConversation()
            }
            
        }.catch { [weak self] error in
            self?.emptyTableViewLabel.text = "There was a problem getting your direct messages. Please try again."
            self?.emptyTableViewLabel.isHidden = false
        }.always { [weak self] in
            self?.activityIndicator.stopAnimating()
            self?.progressIndicator.stopAnimating()
            completionHandler?()
            AnalyticsService.logEvent(name: "view_message", parameters: ["message_type": "direct_message_inbox"])
        }
    }
    
    private func showDMConversation() {
        let dataSource = DirectMessageStreamDataSource(stream: self.selectedDirectMessage!)
        let vc = StreamViewController(dataSource: dataSource)
        self.show(vc, sender: self)
    }
    
}

extension DMViewController: UITableViewDelegate {
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let directMessage = directMessages[indexPath.row]
        selectedDirectMessage = directMessage
        
        let threadCell = tableView.cellForRow(at: indexPath) as? DMListCell
        threadCell?.messageState = .read
        
        showDMConversation()
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? DMListCell {
            cell.initializeCell()
        }
    }
    
}

// MARK: DYTFetchedResultsDataSourceDelegate
extension DMViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return directMessages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let threadCell = tableView.dequeueReusableCell(withIdentifier: "DirectMessagesCell") as! DMListCell
        let thread = directMessages[indexPath.row]
        
        let currentUser = User.current
        
        let otherParticipants = thread.details?.closedParties.filter({ $0.id != currentUser.personId }) ?? []
        
        let threadIsRead = thread.details?.isRead ?? true
        
        if threadIsRead {
            threadCell.messageState = .read
        } else {
            threadCell.messageState = .unread
        }
        
        if let firstOtherPerson = otherParticipants.first {
            threadCell.personID = String(firstOtherPerson.id)
            
            if let url = firstOtherPerson.avatarURL {
                let filter = AspectScaledToFillSizeWithRoundedCornersFilter(
                    size: threadCell.avatarImageView.frame.size,
                    radius: threadCell.avatarImageView.frame.size.height / 2
                )
                
                threadCell.avatarImageView.vlg_setImage(withURL: url, filter: filter)
            }
        }
        
        threadCell.username = otherParticipants.compactMap({ $0.displayName }).joined(separator: ", ")
        
        threadCell.time = villageCoreAPIDateFormatter.date(from: thread.details?.lastMessageDate ?? "")
        threadCell.message = thread.details?.lastMessageText ?? ""
        threadCell.messageState = threadIsRead ? .read : .unread
        
        return threadCell
    }
}

extension DMViewController: SelectPeopleViewControllerDelegate {
    
    func didSelectPeople(_ people: People) {
        if let directMessage = existingDirectMessage(people) {
            selectedDirectMessage = directMessage
            self.navigationController?.popViewController(animated: true)
            DispatchQueue.main.async {
                self.showDMConversation()
            }
        } else {
            self.navigationController?.popViewController(animated: true)
            DispatchQueue.main.async {
                self.activityIndicator.startAnimating()
                
                firstly {
                    User.current.getPerson().then { people + [$0] }
                }.then { participants in
                    Stream.startDirectMessage(with: participants)
                }.then { [weak self] directMessage in
                    self?.selectedDirectMessage = directMessage
                    self?.showDMConversation()
                }.catch { [weak self] error in
                    let alert = UIAlertController.dismissable(title: "Error", message: error.vlg_userDisplayableMessage)
                    self?.present(alert, animated: true, completion: nil)
                }.always { [weak self] in
                    self?.activityIndicator.stopAnimating()
                }
            }
        }
    }
    
    func existingDirectMessage(_ people: People) -> VillageCore.Stream? {
        let directMessagesWithRecipients = directMessages.filter { directMessage in
            let currentUser = User.current
            let otherParticipants = directMessage.details?.closedParties.filter({ $0.id != currentUser.personId }) ?? []
            return otherParticipants == people
        }
        return directMessagesWithRecipients.first
    }
}

// MARK: Actions
extension DMViewController {

    func displayProgressFooterView() {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: (self.tableView?.frame.width)!, height: 44))
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
    
}

//extension DMViewController: ContextWatcherDelegate {
//    func contextUpdated(_ impact: [String : [NSManagedObject]]) {
//        if let directMessages = self.fetchedResultsController.fetchedObjects {
//            var currentUnreadCounts = [String: Int]()
//
//            for directMessage in directMessages {
//                currentUnreadCounts[directMessage.streamID] = Int(directMessage.unreadCount)
//            }
//            
//            if let unreadCounts = self.unreadCounts, unreadCounts != currentUnreadCounts {
//                refreshTableView()
//            }
//            
//            self.unreadCounts = currentUnreadCounts
//        }
//    }
//}
