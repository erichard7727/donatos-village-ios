//
//  LoginIdentityViewController.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 2/10/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit
import Promises
import VillageCore
import Nantes

final class LoginIdentityViewController: UIViewController {
    
    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var backgroundImageView: UIImageView! {
        didSet {
            backgroundImageView.setImage(named: "app-background")
        }
    }
    
    @IBOutlet private weak var clientLogoImageView: UIImageView! {
        didSet {
            clientLogoImageView.setImage(named: "client_logo")
        }
    }
    
    @IBOutlet private weak var titleLabel: UILabel!
    
    @IBOutlet private weak var detailLabel: NantesLabel! {
        didSet {
            detailLabel.attributedText = {
                let detailText = NSMutableAttributedString(
                    string: "Enter your email address below to log in to ",
                    attributes: [
                        NSAttributedString.Key.foregroundColor: UIColor.white,
                        NSAttributedString.Key.font: UIFont(name: "ProximaNova-Regular", size: 17.0)!
                    ]
                )
                let applicationNameText = NSAttributedString(
                    string: ClientConfiguration.current.applicationName,
                    attributes: [
                        NSAttributedString.Key.font: UIFont(name: "ProximaNova-SemiBold", size: 17.0)!
                    ]
                )
                let period = NSMutableAttributedString(
                    string: ".",
                    attributes: [
                        NSAttributedString.Key.foregroundColor: UIColor.white,
                        NSAttributedString.Key.font: UIFont(name: "ProximaNova-Regular", size: 17.0)!
                    ]
                )
                detailText.append(applicationNameText)
                detailText.append(period)
                return detailText
            }()
        }
    }
    
    @IBOutlet private weak var identityField: TintedTextField!
    
    @IBOutlet private weak var invalidIdentityLabel: UILabel! {
        didSet {
            invalidIdentityLabel.isHidden = true
        }
    }
    
    @IBOutlet private weak var submitButton: UIButton!
    
}

// MARK: - UIViewController Overrides

extension LoginIdentityViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBehaviors([
            LeftBarButtonBehavior(showing: .back)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.vlg_setNavigationBarBackgroundVisible(false, animated: animated)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "loginPassword"?:
            // No config necessary
            break
            
        case "confirmEmail"? where segue.destination is SendEmailTokenViewController:
            let vc = segue.destination as! SendEmailTokenViewController
            vc.configure(mode: .confirmation, emailAddress: User.current.emailAddress)
            
        case "createAccount"? where segue.destination is SendEmailTokenViewController:
            let vc = segue.destination as! SendEmailTokenViewController
            vc.configure(mode: .invitation, emailAddress: User.current.emailAddress)
            
        default:
            assertionFailure("Unhandle segue")
            break
        }
    }
}

// MARK: Target/Action

private extension LoginIdentityViewController {
    
    @IBAction func onSubmit(_ sender: Any? = nil) {
        guard validateForm() else {
            return
        }

        firstly { () -> Promise<User.ValidateIdentityNextStep> in
            view.endEditing(true)
            setLoading(true)
            User.current = User(identity: identityField.text!)
            return User.current.validateIdentity()
        }.then { [weak self] nextStep in
            switch nextStep {
            case .enterPassword:
                self?.performSegue(withIdentifier: "loginPassword", sender: self)
            case .confirmEmail:
                self?.performSegue(withIdentifier: "confirmEmail", sender: self)
            case .createAccount:
                self?.performSegue(withIdentifier: "createAccount", sender: self)
            }
        }.catch { [weak self] _ in
            let alert = UIAlertController(title: "Invalid Email", message: "The email you entered is invalid or does not exist.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self?.present(alert, animated: true, completion: nil)
        }.always { [weak self] in
            self?.setLoading(false)
        }
    }
    
}

// MARK: - Private Methods

private extension LoginIdentityViewController {
    
    @discardableResult func validateForm() -> Bool {
        if let identity = identityField.text, !identity.isEmpty {
            invalidIdentityLabel.isHidden = true
            return true
        } else {
            invalidIdentityLabel.isHidden = false
            
            DispatchQueue.main.async {
                let rect = self.invalidIdentityLabel.convert(self.invalidIdentityLabel.bounds, to: self.scrollView)
                self.scrollView.scrollRectToVisible(rect, animated: true)
            }

            return false
        }
    }
    
    func setLoading(_ isLoading: Bool) {
        view.isUserInteractionEnabled = !isLoading
        submitButton.vlg_setLoading(isLoading)
    }
    
}

// MARK: - UITextFieldDelegate

extension LoginIdentityViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard validateForm() else {
            return false
        }
        onSubmit()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        validateForm()
    }
    
}
