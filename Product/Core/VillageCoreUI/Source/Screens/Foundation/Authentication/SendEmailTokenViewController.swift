//
//  SendEmailTokenViewController.swift
//  VillageCoreUI
//
//  Created by Mechelle Sieglitz on 11/12/15.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit
import Promises
import VillageCore
import Nantes

final class SendEmailTokenViewController: UIViewController, UIGestureRecognizerDelegate {
    
    func configure(mode: User.DomainInitiationMode, emailAddress: String) {
        loadViewIfNeeded()
        
        self.mode = mode
        self.emailAddress = emailAddress
        
        let regularAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.font: UIFont(name: "ProximaNova-Regular", size: 17.0)!
        ]
        
        let boldAttriburtes = [
            NSAttributedString.Key.font: UIFont(name: "ProximaNova-SemiBold", size: 17.0)!
        ]
        
        let detailText = NSMutableAttributedString(
            string: "We'll confirm your account by sending an email to ",
            attributes: regularAttributes
        )
        
        detailText.append(NSAttributedString(
            string: User.current.identity,
            attributes: boldAttriburtes
        ))
        
        detailText.append(NSAttributedString(
            string: ". Please activate your account by clicking on the confirmation button in the email.\n\nDon't see an email? Check your spam filter to allow emails from ",
            attributes: regularAttributes
        ))
        
        detailText.append(NSAttributedString(
            string: "villageapp.com",
            attributes: boldAttriburtes
        ))
        
        detailText.append(NSAttributedString(
            string: ".",
            attributes: regularAttributes
        ))
        
        detailLabel.attributedText = detailText
    }
    
    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var backgroundImageView: UIImageView! {
        didSet {
            backgroundImageView.setImage(named: "app-background")
        }
    }
    
    @IBOutlet private weak var titleLabel: UILabel!
    
    @IBOutlet private weak var detailLabel: UILabel!
    
    @IBOutlet private weak var confirmButton: UIButton!
    
    private var mode: User.DomainInitiationMode!
    private var emailAddress: String!
    
}

// MARK: - UIViewController Overrides

extension SendEmailTokenViewController {
    
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

private extension SendEmailTokenViewController {
    
    @IBAction func onInitiateConfirmation(_ sender: Any? = nil) {
        
        view.endEditing(true)
        setLoading(true)

        firstly {
            User.initiateDomatin(mode: self.mode, emailAddress: self.emailAddress)
        }.then { [weak self] in
            let alert: UIAlertController = UIAlertController(title: "Success", message: "Email sent", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self?.present(alert, animated: true, completion: nil)
        }.catch { [weak self] error in
            let alert: UIAlertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self?.present(alert, animated: true, completion: nil)
        }.always { [weak self] in
           self?.setLoading(false)
        }
    }
    
}

// MARK: - Private Methods

private extension SendEmailTokenViewController {
    
    func setLoading(_ isLoading: Bool) {
        view.isUserInteractionEnabled = !isLoading
        confirmButton.vlg_setLoading(isLoading)
    }
    
}
