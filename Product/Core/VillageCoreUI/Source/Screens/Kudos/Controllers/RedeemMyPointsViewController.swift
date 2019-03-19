//
//  RedeemMyPointsViewController.swift
//  VillageContainerApp
//
//  Created by Russell Stephenson on 9/27/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit

class RedeemMyPointsViewController: UIViewController {
    var context: AppContext!
    
    @IBOutlet weak var pointsLabel: UILabel!
    @IBOutlet weak var listTab: TabItemView!
    @IBOutlet weak var gridTab: TabItemView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var firstTimeLoad: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cellNib = UINib(nibName: "RedeemPointsCollectionViewCell", bundle: Constants.bundle)
        collectionView.register(cellNib, forCellWithReuseIdentifier: "RedeemPointsCell")
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        listTab.tabButton.setTitle("List", for: .normal)
        listTab.tabButton.addTarget(self, action: #selector(tabButtonClicked), for: .touchUpInside)
        gridTab.tabButton.setTitle("Grid", for: .normal)
        gridTab.tabButton.addTarget(self, action: #selector(tabButtonClicked), for: .touchUpInside)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if firstTimeLoad {
            gridTab.selectInitialTab()
            firstTimeLoad = false
        }
    }
    
    func tabButtonClicked(_ sender: UITapGestureRecognizer) {
        if sender == listTab.tabButton {
            listTab.changeHighlight(sender: listTab.tabButton)
            gridTab.removeHighlight(sender: gridTab.tabButton)
        } else {
            gridTab.changeHighlight(sender: gridTab.tabButton)
            listTab.removeHighlight(sender: listTab.tabButton)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "RedeemPointsSegue" {
            guard segue.destination is RedeemMyPointsSelectionViewController else {
                fatalError("RedeemMyPointsSelectionViewController not found")
            }
            
            //controller.context = context
        }
    }
    
    @IBAction func menuItemPressed(_ sender: UIBarButtonItem!) {
        guard let sideMenuController = sideMenuController else {
            return
        }
        sideMenuController.showLeftMenuController(true)
    }
}

extension RedeemMyPointsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        self.performSegue(withIdentifier: "RedeemPointsSegue", sender: self)
        
    }
}

extension RedeemMyPointsViewController: UICollectionViewDataSource {
    private func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RedeemPointsCell", for: indexPath) as! RedeemPointsCollectionViewCell
        
        switch indexPath.row {
        case 0:
            cell.rewardLabel.text = "1 Day Off"
            cell.pointLabel.text = "500"
        case 1:
            cell.rewardLabel.text = "Half Day"
            cell.pointLabel.text = "210"
        case 2:
            cell.rewardLabel.text = "Applebee's Free Lunch"
            cell.pointLabel.text = "175"
        default:
            break
        }
        
        return cell
    }
}
