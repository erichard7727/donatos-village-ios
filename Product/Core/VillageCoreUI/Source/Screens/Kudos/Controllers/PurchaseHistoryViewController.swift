//
//  PurchaseHistoryViewController.swift
//  VillageContainerApp
//
//  Created by Russell Stephenson on 9/27/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit

class PurchaseHistoryViewController: UIViewController {
    var context: AppContext!
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad(){
        super.viewDidLoad()
        let purchaseHistoryNib = UINib(nibName: "PurchaseHistoryCell", bundle: Constants.bundle)
        tableView.register(purchaseHistoryNib, forCellReuseIdentifier: "PurchaseHistoryCell")
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 75.0
        automaticallyAdjustsScrollViewInsets = false
    }
    
    @IBAction func menuTapped(_ sender: UIBarButtonItem) {
        guard let sideMenuController = sideMenuController else {
            return
        }
        sideMenuController.showLeftMenuController(true)
    }
}

extension PurchaseHistoryViewController: UITableViewDelegate {
}

extension PurchaseHistoryViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PurchaseHistoryCell", for: indexPath) as! PurchaseHistoryCell
        cell.selectionStyle = .none
        switch indexPath.row {
        case 0:
            cell.rewardLabel.text = "Free Lunch"
            cell.pointLabel.text = "Redeemed 175 points"
            cell.dateLabel.text = "Today"
        case 1:
            cell.rewardLabel.text = "Half Day"
            cell.pointLabel.text = "Redeemed 210 points"
            cell.dateLabel.text = "Apr 4"
        case 2:
            cell.rewardLabel.text = "Day Off"
            cell.pointLabel.text = "Redeemed 500 points"
            cell.dateLabel.text = "Mar 20"
        default:
            break
        }
        
        return cell
    }
}
