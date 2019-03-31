//
//  RedeemMyPointsSelectionViewController.swift
//  VillageContainerApp
//
//  Created by Russell Stephenson on 9/27/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit

class RedeemMyPointsSelectionViewController: UIViewController {
    var context: AppContext!
    
    @IBOutlet weak var pointsLabel: UILabel!
    @IBOutlet weak var bannerImageView: UIImageView!
    @IBOutlet weak var rewardImageView: UIImageView!
    
    @IBOutlet weak var rewardPointsLabel: UILabel!
    @IBOutlet weak var rewardDescriptionLabel: UILabel!
    @IBOutlet weak var rewardTitleLabel: UILabel!
    @IBOutlet weak var dimView: UIView!
    
    override func viewDidLoad(){
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dimView.alpha = 0
        dimView.backgroundColor = UIColor.black
    }

    
    @IBAction func claimAction(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Are you sure you want to redeem 175 points?", message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
            alertController.dismiss(animated: false, completion: nil)
            self.acceptReward()
        }))
        present(alertController, animated: true, completion: nil)
    }
    
    func acceptReward() {
        self.modalPresentationStyle = .overCurrentContext
        self.animateDim()
        
        let vc = ItemRedeemedModal(nibName: "ItemRedeemedModal", bundle: .main)
        vc.modalPresentationStyle = .overCurrentContext
        vc.context = context
        vc.dismissModal = { _ in
            self.removeDim()
        }
        vc.transitionToPurchaseHistory = { _ in
            if let menuController = self.sideMenuController {
                let controller = UIStoryboard(name: "Kudos", bundle: Constants.bundle).instantiateViewController(withIdentifier: "PurchaseHistoryViewController") as! PurchaseHistoryViewController
                controller.context = self.context
                let nav = VillageNavigationController(rootViewController: controller)
                menuController.swapOutCenterViewController(nav, animated: true)
            }
        }
        self.present(vc, animated: true, completion: nil)
    }
    
    func animateDim() {
        UIView.animate(withDuration: 0.3, animations: {
            self.dimView.alpha = 0.5
        })
    }
    
    func removeDim() {
        UIView.animate(withDuration: 0.3, animations: {
            self.dimView.alpha = 0
        })
    }
    
    @IBAction func backAction(_ sender: UIBarButtonItem) {
        if let navController = navigationController {
            navController.popViewController(animated: true)
        }
    }
    
}
