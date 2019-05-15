//
//  SettingsController.swift
//  VillageContainerApp
//
//  Created by Justin Munger on 5/25/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit
import AlamofireImage
import VillageCore

protocol SettingsControllerDelegate: class {
    func savePressed(person: Person)
    func logoutPressed()
    func selectAvatarPressed()
}

class SettingsController: UITableViewController {
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var twitterTextField: UITextField!
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var avatarImageViewWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var appVersionLabel: UILabel! {
        didSet {
            appVersionLabel.text = "\(ClientConfiguration.current.applicationName) - \(Bundle.main.vlg_markingVersion) #(\(Bundle.main.vlg_buildVersion))"
        }
    }
    
    @IBOutlet weak var pushTokenLabel: UILabel! {
        didSet {
            pushTokenLabel.text = User.current.pushToken ?? "Not Registered"
        }
    }

    weak var delegate: SettingsControllerDelegate?
    
    var person: Person!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure tableview.
        tableView.rowHeight = UITableView.automaticDimension
        tableView.allowsSelection = false
        
        avatarImageView.backgroundColor = UIColor.vlgGray
        
        if let avatarImageView = self.avatarImageView, let avatarImageViewWidthConstraint = self.avatarImageViewWidthConstraint {
            avatarImageView.layer.masksToBounds = true
            avatarImageView.layer.cornerRadius = avatarImageViewWidthConstraint.constant / 2.0
        }
        
        firstly {
            User.current.getPerson()
        }.then { (person) in
            self.person = person
            self.populatePersonData()
        }.catch { (error) in
            let alert = UIAlertController.dismissable(title: "Error", message: "Could not retrieve user data")
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func populatePersonData() {
        firstNameTextField.text = person.firstName
        lastNameTextField.text = person.lastName
        titleTextField.text = person.jobTitle
        emailTextField.text = person.emailAddress
        phoneTextField.text = person.phone
        twitterTextField.text = person.twitter
        
        if let url = person.avatarURL {
            let filter = AspectScaledToFillSizeWithRoundedCornersFilter(
                size: avatarImageView.frame.size,
                radius: avatarImageViewWidthConstraint.constant / 2
            )
            
            avatarImageView.af_setImage(withURL: url, filter: filter)
        }
        
        userNameLabel.text = person.displayName
        titleLabel.text = person.jobTitle
    }
    
    func populateAvatarImage(_ image: UIImage) {
        UIView.transition(with: avatarImageView, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.avatarImageView.image = image
            }, completion: nil)        
    }
    
    @IBAction func selectAvatarButtonPressed(_ sender: UIButton) {
        delegate?.selectAvatarPressed()
    }
    
    @IBAction func saveButtonPressed(_ sender: UIButton) {
        guard let person = self.person else { return }
        delegate?.savePressed(person: person)
    }
    
    @IBAction func logoutButtonPressed(_ sender: UIButton) {
        delegate?.logoutPressed()
    }
}
