//
//  InvitePersonController.swift
//  VillageContainerApp
//
//  Created by Justin Munger on 9/14/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit

protocol InvitePersonControllerDelegate: class {
    func personInvited(emailAddress: String?)
}

final class InvitePersonController: UIViewController, UIGestureRecognizerDelegate {
    
    weak var delegate: InvitePersonControllerDelegate?
    
}

// MARK: - UIViewController Overrides

extension InvitePersonController {
    
    
    
}

// MARK: - Target/Action

private extension InvitePersonController {
    
    @IBAction func goBack(_ sender: Any? = nil) {
        if let navigationController = self.navigationController {
            navigationController.popViewController(animated: true)
        }
    }
    
}

// MARK: - Private Methods

private extension InvitePersonController {
    
    
    
}

extension InvitePersonController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.personInvited(emailAddress: textField.text)
        return true
    }
}
