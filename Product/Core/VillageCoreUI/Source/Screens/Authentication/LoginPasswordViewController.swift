//
//  LoginPasswordViewController.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 2/10/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit
import Promises
import VillageCore
import Nantes

final class LoginPasswordViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var backgroundImageView: UIImageView! {
        didSet {
            backgroundImageView.setImage(named: "app-background")
        }
    }
    
    @IBOutlet private weak var detailLabel: UILabel!
    @IBOutlet private weak var passwordField: TintedTextField!
    @IBOutlet private weak var showPasswordButton: UIButton!
    
    @IBOutlet private weak var invalidPasswordLabel: UILabel! {
        didSet {
            invalidPasswordLabel.isHidden = true
        }
    }
    
    @IBOutlet private weak var submitButton: UIButton!
    
    @IBOutlet private weak var forgotPasswordLabel: NantesLabel! {
        didSet {
            forgotPasswordLabel.attributedText = {
                let text = NSMutableAttributedString(
                    string: "Trouble signing in? ",
                    attributes: [
                        NSAttributedString.Key.foregroundColor: UIColor.white,
                        NSAttributedString.Key.font: UIFont(name: "ProximaNova-Regular", size: 16)!
                    ]
                )
                let resetText = NSAttributedString(
                    string: "Reset your password.",
                    attributes: [
                        NSAttributedString.Key.font: UIFont(name: "ProximaNova-SemiBold", size: 16)!
                    ]
                )

                text.append(resetText)
                return text
            }()
            
            forgotPasswordLabel.labelTappedBlock = { [weak self] in
                self?.performSegue(withIdentifier: "showForgotPassword", sender: self)
            }
        }
    }
    
}

// MARK: - UIViewController Overrides

extension LoginPasswordViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureBackButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.vlg_setNavigationBarBackgroundVisible(false, animated: animated)
    }
    
}

// MARK: - Public Methods

extension LoginPasswordViewController {
    
}

// MARK: Target/Action

private extension LoginPasswordViewController {
    
    @IBAction func onShowPassword(_ sender: Any? = nil) {
        let toggledSecureTextEntry = !passwordField.isSecureTextEntry
        
        // Set the Show/Hide button copy
        let buttonCopy = toggledSecureTextEntry ? "Show" : "Hide"
        showPasswordButton.setTitle(buttonCopy, for: .normal)
        
        // HACK: http://stackoverflow.com/a/7137588
        // "It must be input-focus issue: when focused, UITextField can change only ON->OFF."
        // Toggle secure entry state.
        passwordField.resignFirstResponder()
        passwordField.isSecureTextEntry = toggledSecureTextEntry
        passwordField.becomeFirstResponder()
    }
    
    @IBAction func onSubmit(_ sender: Any? = nil) {
        guard validateForm() else {
            return
        }

        firstly { () -> Promise<User> in
            view.endEditing(true)
            setLoading(true)
            User.current.password = passwordField.text
            return User.current.loginWithDetails()
        }.then { [weak self] _ in
            self?.performSegue(withIdentifier: "unwindToVillageContainer", sender: self)
        }.catch { [weak self] _ in
            let alert = UIAlertController(title: "Invalid Email", message: "The email you entered is invalid or does not exist.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self?.present(alert, animated: true, completion: nil)
        }.always { [weak self] in
            self?.setLoading(false)
        }
    }
    
    @IBAction func unwindToLoginPasswordController(segue: UIStoryboardSegue) {
        switch segue.source {
        case is ForgotPasswordViewController:
            self.navigationController?.popViewController(animated: true)
            
        default:
            assertionFailure("Unable to handle unwind from \(String(describing: segue.source))")
            break
        }
    }
}

// MARK: - Private Methods

private extension LoginPasswordViewController {
    
    func configureBackButton() {
        // Hide the actual back button text
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        // Modify the back indicator image
        let backImage = UIImage.named("back-button")
        navigationController?.navigationBar.backIndicatorImage = backImage
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = backImage
        
        // Maintain swipe-to-go-back gesture behavior
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }

    @discardableResult func validateForm() -> Bool {
        if let password = passwordField.text, !password.isEmpty {
            invalidPasswordLabel.isHidden = true
            return true
        } else {
            invalidPasswordLabel.isHidden = false
            
            DispatchQueue.main.async {
                let rect = self.invalidPasswordLabel.convert(self.invalidPasswordLabel.bounds, to: self.scrollView)
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

extension LoginPasswordViewController: UITextFieldDelegate {
    
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
