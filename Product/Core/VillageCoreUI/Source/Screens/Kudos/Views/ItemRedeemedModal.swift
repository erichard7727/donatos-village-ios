//
//  ItemRedeemedModal.swift
//  VillageContainerApp
//
//  Created by Russell Stephenson on 9/27/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit

class ItemRedeemedModal: UIViewController {
    var context: AppContext!
    
    @IBOutlet weak var itemLabel: UILabel!
    @IBOutlet weak var itemImageView: UIImageView!
    
    var dismissModal : (() -> ())?
    var transitionToPurchaseHistory : (() -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @IBAction func cancelAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: {
            self.dismissModal!()
        })
    }
    
    @IBAction func continueAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: {
            self.transitionToPurchaseHistory!()
        })
    }
}
