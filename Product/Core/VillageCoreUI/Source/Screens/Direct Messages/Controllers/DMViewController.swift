
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

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


// MARK: DirectMessagesViewController
final class DMViewController: UIViewController {
    
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
        
        activityIndicator.startAnimating()
        progressIndicator.startAnimating()
        
        firstly {
            Streams.directMessages()
        }.then { [weak self] streams in
            guard let `self` = self else { return }
            
            self.emptyTableViewLabel.text = "You haven't sent or received any direct messages yet."
            self.emptyTableViewLabel.isHidden = !streams.isEmpty
            
            self.directMessages = streams.sorted{
                let firstLastMessageDate = villageCoreAPIDateFormatter.date(from: $0.details?.directMessage?.lastMessageDate ?? "") ?? Date.distantPast
                let secondLastMessageDate = villageCoreAPIDateFormatter.date(from: $1.details?.directMessage?.lastMessageDate ?? "") ?? Date.distantPast
                
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
                self.performSegue(withIdentifier: "ShowDMConversation", sender: nil)
            }
            
        }.catch { [weak self] error in
            self?.emptyTableViewLabel.text = "There was a problem getting your direct messages. Please try again."
            self?.emptyTableViewLabel.isHidden = false
        }.always { [weak self] in
            self?.activityIndicator.stopAnimating()
            self?.progressIndicator.stopAnimating()
            AnalyticsService.logEvent(name: "view_message", parameters: ["message_type": "direct_message_inbox"])
        }

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            if identifier == "PushNewMessagesSegue" {
                guard let navController = segue.destination as? UINavigationController, let controller = navController.viewControllers.first as? SelectPeopleViewController else {
                    fatalError("SelectPeopleViewController not found")
                }
                controller.delegate = self
            } else if identifier == "ShowDMConversation" {
                guard let controller = segue.destination as? DMConversationViewController else {
                    fatalError("DMConversationViewController not set")
                }
                
                guard let selectedDirectMessage = self.selectedDirectMessage else {
                    fatalError("selectedDirectMessage not set")
                }
                
                controller.directMessageThread = selectedDirectMessage
            }
        }
    }

    /// Unwind segue point.
    @IBAction func unwindToSegue(_ segue: UIStoryboardSegue) {}
    
    // MARK: Refreshing
    
    func showRefreshControl(show: Bool) {
        if show {
            refreshControl.beginRefreshing()
            tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: true)
        } else {
            refreshControl.endRefreshing()
        }
    }
    
    @objc internal func onRefresh(_ sender: AnyObject? = nil) {
        refreshTableView() { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }
    
    fileprivate func refreshTableView(completionHandler: (() -> Void)? = nil) {
        // Perform animations for refreshing if we're not initiated by the user.
        // This is needed for the initial fetch case to show activity to the user.
        if !refreshControl.isRefreshing {
            refreshControl.beginRefreshing()
        }
        
//        context.fetchDirectMessages() { result in
//            self.refreshControl?.endRefreshing()
//            self.progressIndicator.alpha = 0
//            switch result {
//                case .success:
//                    break
//                case .error(let error):
//                    var errorMessage: String
//                    if let localizedFailure = error.userInfo[NSLocalizedFailureReasonErrorKey] as? [String: AnyObject], let error = localizedFailure["error"] as? [String: AnyObject], let code = error["code"], let errorDescription = error["description"] as? String {
//                        errorMessage = "E" + String(describing: code) + " - " + String(describing: errorDescription)
//                    } else {
//                        errorMessage = "Could not fetch direct message threads."
//                    }
//                    let alert = UIAlertController.dismissableAlert("Error", message: errorMessage)
//                    self.present(alert, animated: true, completion: nil)
//            }
//        }
    }
}

extension DMViewController: UITableViewDelegate {
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let directMessage = directMessages[indexPath.row]
        
        guard let threadCell = tableView.cellForRow(at: indexPath) as? DMListCell else {
            return
        }
        
        threadCell.messageState = .read
        
        
        selectedDirectMessage = directMessage
        self.performSegue(withIdentifier: "ShowDMConversation", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? DMListCell {
            cell.initializeCell()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
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
        
        let threadIsRead = thread.details?.directMessage?.isRead ?? true
        
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
                
                threadCell.avatarImageView.af_setImage(withURL: url, filter: filter)
            }
        }
        
        threadCell.username = otherParticipants.compactMap({ $0.displayName }).joined(separator: ", ")
        
        threadCell.time = villageCoreAPIDateFormatter.date(from: thread.details?.directMessage?.lastMessageDate ?? "")
        threadCell.message = thread.details?.directMessage?.lastMessageText ?? ""
        threadCell.messageState = threadIsRead ? .read : .unread
        
        return threadCell
    }
}

extension DMViewController: SelectPeopleViewControllerDelegate {
    
    func didSelectPeople(_ people: People) {
        if let directMessage = existingDirectMessage(people) {
            self.dismiss(animated: true, completion: nil)
            selectedDirectMessage = directMessage
            performSegue(withIdentifier: "ShowDMConversation", sender: nil)
        } else {
            
            activityIndicator.startAnimating()
            
            firstly {
                User.current.getPerson().then { people + [$0] }
            }.then { participants in
                Stream.startDirectMessage(with: participants)
            }.then { [weak self] directMessage in
                self?.selectedDirectMessage = directMessage
                self?.performSegue(withIdentifier: "ShowDMConversation", sender: nil)
            }.catch { [weak self] error in
                let alert = UIAlertController.dismissable(title: "Error", message: error.vlg_userDisplayableMessage)
                self?.present(alert, animated: true, completion: nil)
            }.always { [weak self] in
                self?.activityIndicator.stopAnimating()
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
