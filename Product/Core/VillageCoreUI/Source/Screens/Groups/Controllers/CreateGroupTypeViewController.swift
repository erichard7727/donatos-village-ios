//
//  CreateGroupTypeViewController.swift
//  VillageCore
//
//  Created by Justin Munger on 5/2/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit
import VillageCore

class CreateGroupTypeViewController: UITableViewController {
    
    @IBOutlet weak var openButton: UIButton!
    @IBOutlet weak var openInviteButton: UIButton!
    @IBOutlet weak var closedButton: UIButton!
    
    var selectedGroupType: VillageCore.Stream.StreamType = .open
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        openButton.isSelected = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func optionSelected(_ sender: UIButton) {
        switch sender {
        case openButton:
            selectedGroupType = .open
            
            openButton.isSelected = true
            openInviteButton.isSelected = false
            closedButton.isSelected = false
        case openInviteButton:
            selectedGroupType = .memberInvites
            
            openButton.isSelected = false
            openInviteButton.isSelected = true
            closedButton.isSelected = false
        case closedButton:
            selectedGroupType = .closed
            
            openButton.isSelected = false
            openInviteButton.isSelected = false
            closedButton.isSelected = true
        default:
            break
        }
    }
}
