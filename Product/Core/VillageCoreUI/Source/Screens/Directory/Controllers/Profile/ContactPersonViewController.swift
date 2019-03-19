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
    
    /// Person to display information for.
    var person: Person!
    var currentPerson: Person?
    
    /// Delegated object.
    var delegate: PersonProfileViewControllerDelegate?
    
    /// Types of rows to display.
    enum Rows: Int {
        case directMessage, email, phone, twitter
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        firstly {
            self.person.getDetails()
        }.then { [weak self] person in
            self?.person = person
            self?.tableView.reloadSections([0] , with: .automatic)
        }.catch { error in
            assertionFailure(error.localizedDescription)
        }
    }
    
    // MARK: UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if Constants.Settings.directMessagesEnabled {
            return 4
        } else {
            return 3
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ContactPersonTableViewCell") as? ContactPersonTableViewCell else { fatalError("Type mismatch") }
        
        if Constants.Settings.directMessagesEnabled,
           let row = Rows(rawValue: (indexPath as NSIndexPath).row) {
            
            switch row {
            case .directMessage:
                guard let currentPerson = self.currentPerson else {
                    fatalError("currentPerson not set")
                }
                
                guard let person = self.person else {
                    fatalError("person not set")
                }
                
                let directMessageEnabled = currentPerson.id != person.id
                cell.isUserInteractionEnabled = directMessageEnabled
                cell.buttonTextLabel.alpha = directMessageEnabled ? 1.0 : 0.5
                cell.iconImageView.alpha = directMessageEnabled ? 1.0 : 0.5
                cell.buttonTextLabel.text = "Send Direct Message"
                cell.iconImageView.image = UIImage.named("profile-email-icon")

            case .email:
                cell.buttonTextLabel.text = person.emailAddress
                cell.iconImageView.image = UIImage.named("profile-email-icon")

            case .phone:
                cell.buttonTextLabel.text = (person.phone == "" ? "<No Phone Number>" : person.phone)
                cell.buttonTextLabel.textColor = (person.phone == "" ? UIColor.lightGray : UIColor.darkGray)
                cell.iconImageView.image = UIImage.named("profile-phone-icon")

            case .twitter:
                cell.buttonTextLabel.text = person.twitter == "" ? "<No Twitter Profile>" : person.twitter
                cell.buttonTextLabel.textColor = (person.twitter == "" ? UIColor.lightGray : UIColor.darkGray)
                cell.iconImageView.image = UIImage.named("profile-twitter-icon")
            }
            
        } else if !Constants.Settings.directMessagesEnabled,
               let row = Rows(rawValue: (indexPath as NSIndexPath).row + 1) {
            
            switch row {
            case .email:
                cell.buttonTextLabel.text = person.emailAddress
                cell.iconImageView.image = UIImage.named("profile-email-icon")
            case .phone:
                cell.buttonTextLabel.text = (person.phone == "" ? "<No Phone Number>" : person.phone)
                cell.buttonTextLabel.textColor = (person.phone == "" ? UIColor.lightGray : UIColor.darkGray)
                cell.iconImageView.image = UIImage.named("profile-phone-icon")
            case .twitter:
                cell.buttonTextLabel.text = (person.twitter == "" ? "<No Twitter Profile>" : person.twitter)
                cell.buttonTextLabel.textColor = (person.twitter == "" ? UIColor.lightGray : UIColor.darkGray)
                cell.iconImageView.image = UIImage.named("profile-twitter-icon")
            default:
                break
            }
            
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
        
        if Constants.Settings.directMessagesEnabled,
           let row = Rows(rawValue: (indexPath as NSIndexPath).row) {
            
            switch row {
            case .directMessage:
                self.shouldShowAndStartDirectMessage(person, controller: self)
            case .email:
                attemptURL("mailto:\(person.emailAddress)")
            case .phone where person.phone?.isEmpty == false:
                attemptURL("tel://\(person.phone!)")
            case .twitter where person.twitter?.isEmpty == false:
                attemptURL("https://twitter.com/\(person.twitter!)")
            default:
                attemptURL("")
            }
            
        } else if !Constants.Settings.directMessagesEnabled,
                  let row = Rows(rawValue: (indexPath as NSIndexPath).row + 1) {
            
            switch row {
            case .email:
                attemptURL("mailto:\(person.emailAddress)")
            case .phone where person.phone?.isEmpty == false:
                attemptURL("tel://\(person.phone!)")
            case .twitter where person.twitter?.isEmpty == false:
                attemptURL("https://twitter.com/\(person.twitter!)")
            default:
                attemptURL("")
            }
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
