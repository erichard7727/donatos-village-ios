//
//  HomeViewController.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 2/10/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit
import Promises
import VillageCore

final class HomeViewController: UIViewController {
    
}

// MARK: - UIViewController Overrides

extension HomeViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        firstly {
            People.getDirectory()
        }.then { people in
            people.first!.getDetails()
        }.then { person in
            person.kudosReceived().then { (person, $0) }
        }.then { (person, kudos) in
            person.kudosGiven().then { (person, $0) }
        }.then { (person, kudos) in
            print(kudos)
        }.catch { (error) in
            print(error)
        }
        
    }
    
}
