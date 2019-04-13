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
            return People.getDirectory().then { $0.first! }
        }.then { person in
            person.achievements().then { (person, $0.first!) }
        }.then { (person, achievement) in
            person.giveKudo(for: achievement, reason: "Testing networking.").then { person }
        }.then { person in
            person.kudosReceived()
        }.then { kudos -> Promise<People> in
            print(kudos)
            return Kudos.weeklyLeaderboard()
        }.then { people -> Promise<People> in
            print(people)
            return Kudos.leaderboard()
        }.then { people in
            print(people)
        }
    }
    
}
