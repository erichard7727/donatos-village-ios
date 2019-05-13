//
//  CreateGroupViewController.swift
//  VillageCore
//
//  Created by Colin on 12/7/15.
//  Copyright © 2015 Dynamit. All rights reserved.
//

import Foundation
import UIKit
import VillageCore

// MARK: CreateGroupViewController
final class CreateGroupViewController: UIViewController {
    
    var groupTypeViewController: CreateGroupTypeViewController!
    
    lazy var progressIndicator: ProgressIndicator = {
        return ProgressIndicator.progressIndicatorInView(self.view)
    }()
    
    /// Group name textfield.
    @IBOutlet var groupNameTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBehaviors([
            LeftBarButtonBehavior(showing: .menuOrBack)
        ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        groupNameTextField.becomeFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "CreateGroupType",
           let createGroupTypeVC = segue.destination as? CreateGroupTypeViewController {
            groupTypeViewController = createGroupTypeVC
        }
    }
    
    @IBAction func createNewGroupButtonPressed(_ sender: UIButton) {
        attemptToCreateGroup()
    }
    
    @IBAction func containerViewTapped(_ sender: AnyObject) {
        groupNameTextField.resignFirstResponder()
    }
    
    func attemptToCreateGroup() {
        guard
            let groupName = groupNameTextField.text,
            !groupName.isEmpty
        else {
            let alert = UIAlertController.dismissable(title: "Error", message: "Please enter a name for this group.")
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        view.endEditing(true)
        
        progressIndicator.show()
        
        let groupType = groupTypeViewController.selectedGroupType
        
        firstly {
            User.current.getPerson()
        }.then { owner in
            VillageCore.Stream.new(type: groupType, name: groupName, description: "", owner: owner)
        }.then { group in
            group.subscribe().then { group }
        }.then { [weak self] group in
            let vc = UIStoryboard(name: "Groups", bundle: Constants.bundle).instantiateViewController(withIdentifier: "GroupViewController") as! GroupViewController
            vc.group = group
            self?.sideMenuController?.setContentViewController(UINavigationController(rootViewController: vc), fadeAnimation: true)
        }.catch { [weak self] _ in
            let alert = UIAlertController.dismissable(title: "Error", message: "There was a problem creating this group. Please try again.")
            self?.present(alert, animated: true, completion: nil)
        }.always { [weak self] in
            self?.progressIndicator.hide()
        }
    }
}

extension CreateGroupViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        attemptToCreateGroup()

        return true
    }
}
