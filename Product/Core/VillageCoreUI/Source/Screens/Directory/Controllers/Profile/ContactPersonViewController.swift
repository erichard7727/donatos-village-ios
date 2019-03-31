//
//  ContactPersonViewController.swift
//  VillageCore
//
//  Created by Colin on 12/9/15.
//  Copyright © 2015 Dynamit. All rights reserved.
//

import UIKit
import Promises
import VillageCore

/// Protocol for ContactPersonViewController delegates.
protocol PersonProfileViewControllerDelegate {
    func shouldShowAndStartDirectMessage(_ directMessage: Group, controller: ContactPersonViewController)
}

/// Person contact view controller.
final class ContactPersonViewController: UITableViewController {
    
    /// Types of rows to display.
    private enum Row {
        case directMessage
        case email(String)
        case phone(String)
        case twitter(String)
    }
    
    private var rows: [Row] = []
    
    /// Person to display information for.
    var person: Person! {
        didSet {
            configureRows()
        }
    }
    
    var currentPerson: Person? {
        didSet {
            configureRows()
        }
    }
    
    private func configureRows() {
        let directMessageEnabled: Bool = {
            if Constants.Settings.directMessagesEnabled,
                let currentPerson = self.currentPerson,
                let otherPerson = self.person,
                currentPerson.id != otherPerson.id {
                return true
            } else {
                return false
            }
        }()
        
        self.rows = [
            (directMessageEnabled ? Row.directMessage : nil),
            Row.email(person.emailAddress),
            person.phone.flatMap({ $0.isEmpty ? nil : $0 }).map({ Row.phone($0) }),
            person.twitter.flatMap({ $0.isEmpty ? nil : $0 }).map({ Row.twitter($0) }),
        ].compactMap({ $0 })
    }
    
    /// Delegated object.
    var delegate: PersonProfileViewControllerDelegate?
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
    }
    
    // MARK: UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ContactPersonTableViewCell") as? ContactPersonTableViewCell else {
            fatalError("Type mismatch")
        }
        
        let row = self.rows[indexPath.row]
        
        switch row {
        case .directMessage:
            cell.buttonTextLabel.text = "Send Direct Message"
            cell.iconImageView.image = UIImage.named("profile-email-icon")
            
        case .email(let emailAddress):
            cell.buttonTextLabel.text = emailAddress
            cell.iconImageView.image = UIImage.named("profile-email-icon")
            
        case .phone(let phoneNumber):
            cell.buttonTextLabel.text = phoneNumber
            cell.buttonTextLabel.textColor = UIColor.darkGray
            cell.iconImageView.image = UIImage.named("profile-phone-icon")
            
        case .twitter(let twitter):
            cell.buttonTextLabel.text = twitter
            cell.buttonTextLabel.textColor = UIColor.darkGray
            cell.iconImageView.image = UIImage.named("profile-twitter-icon")
        }

        return cell
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Get a full-width separator.
        cell.separatorInset = UIEdgeInsets.zero
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let attemptURL = { (urlString: String) in
            let app = UIApplication.shared
            
            if let url = URL(string: urlString), app.canOpenURL(url) {
                app.open(url, options: [:], completionHandler: nil)
            } else {
                let alert = UIAlertController.dismissable(title: "Error", message: "Could not open contact method.")
                self.present(alert, animated: true, completion: nil)
            }
        }
        
        let row = self.rows[indexPath.row]
        
        switch row {
        case .directMessage:
            self.shouldShowAndStartDirectMessage(person, controller: self)
            
        case .email(let emailAddress):
            attemptURL("mailto:\(emailAddress)")
            
        case .phone(let phoneNumber):
            attemptURL("tel://\(phoneNumber)")
            
        case .twitter(let twitter):
            attemptURL("https://twitter.com/\(twitter)")
        }
        
        tableView.selectRow(at: nil, animated: true, scrollPosition: .none)
    }
}

extension ContactPersonViewController {
    
    func shouldShowAndStartDirectMessage(_ otherPerson: Person, controller: ContactPersonViewController) {
        firstly {
            User.current.getPerson()
        }.then { me in
            return [otherPerson, me]
        }.then { conversationParticipants in
            #warning("TODO - Implement initiate direct messages")
            assertionFailure()
//            self.directMessageService.publishGroupRequest(people: conversationParticipants) {
//                result in
//
//                switch result {
//                case .success(let directMessage):
//                    if let message = directMessage {
//                        self.delegate?.shouldShowAndStartDirectMessage(message, controller: self)
//                    }
//
//                case .error(let error):
//                    var errorMessage: String
//                    if let localizedFailure = error.userInfo[NSLocalizedFailureReasonErrorKey] as? [String: AnyObject], let error = localizedFailure["error"] as? [String: AnyObject], let code = error["code"], let errorDescription = error["description"] as? String {
//                        errorMessage = "E" + String(describing: code) + " - " + String(describing: errorDescription)
//                    } else {
//                        errorMessage = "Could not start direct message."
//                    }
//                    let alert = UIAlertController.dismissableAlert("Error", message: errorMessage)
//                    self.present(alert, animated: true, completion: nil)
//                }
//            }
        }.catch { error in
            assertionFailure(error.localizedDescription)
        }
    }
    
}
