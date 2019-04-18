//
//  ForgotPasswordViewController.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 2/10/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit
import Promises
import VillageCore
import Nantes

final class ForgotPasswordViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var backgroundImageView: UIImageView! {
        didSet {
            backgroundImageView.setImage(named: "app-background")
        }
    }
    
    @IBOutlet private weak var titleLabel: UILabel!
    
    @IBOutlet private weak var detailLabel: UILabel! {
        didSet {
            detailLabel.attributedText = {
                let detailText = NSMutableAttributedString(
                    string: "Can't remember your password? No problem. We will send you an email to reset your password.\n\nClick the \"Reset My Password\" button below to send an email to ",
                    attributes: [
                        NSAttributedString.Key.foregroundColor: UIColor.white,
                        NSAttributedString.Key.font: UIFont(name: "ProximaNova-Regular", size: 17.0)!
                    ]
                )
                let emailText = NSAttributedString(
                    string: User.current.identity + ".",
                    attributes: [
                        NSAttributedString.Key.font: UIFont(name: "ProximaNova-SemiBold", size: 17.0)!
                    ]
                )
                detailText.append(emailText)
                return detailText
            }()
        }
    }
    
    @IBOutlet private weak var resetPasswordButton: UIButton!
    
}

// MARK: - UIViewController Overrides

extension ForgotPasswordViewController {
    
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
}

// MARK: Target/Action

private extension ForgotPasswordViewController {
    
    @IBAction func onInitiateResetPassword(_ sender: Any? = nil) {
        firstly { () -> Promise<User> in
            view.endEditing(true)
            setLoading(true)
            return User.current.initiateResetPassword()
        }.then { [weak self] _ in
            self?.performSegue(withIdentifier: "unwindToLoginPasswordController", sender: self)
        }.catch { [weak self] _ in
            let alert = UIAlertController(title: "Something Went Wrong", message: "An unexpected error occured. Please try again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self?.present(alert, animated: true, completion: nil)
        }.always { [weak self] in
            self?.setLoading(false)
        }
    }
    
}

// MARK: - Private Methods

private extension ForgotPasswordViewController {
    
    func setLoading(_ isLoading: Bool) {
        view.isUserInteractionEnabled = !isLoading
        resetPasswordButton.vlg_setLoading(isLoading)
    }
    
}
