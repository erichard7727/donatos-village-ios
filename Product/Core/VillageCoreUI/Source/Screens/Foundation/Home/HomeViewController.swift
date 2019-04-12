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
            ContentLibrary.getRootDirectory(page: 1)
        }.then { (library) -> Promise<ContentLibrary> in
            guard let rpd = library.first(where: { $0.name == "Root Parent Directory" }) else { throw PromiseError.validationFailure }
            return rpd.getDirectory()
        }.then { (library) -> Promise<ContentLibrary> in
            guard let cd = library.first(where: { $0.name == "Child Directory" }) else { throw PromiseError.validationFailure }
            return cd.getDirectory()
        }.then { (library) in
            guard let ecp = library.first(where: { $0.name == "Example Content Page" }) else { throw PromiseError.validationFailure }
            print(try ecp.request().url?.absoluteString ?? "Unknown")
        }.catch { (error) in
            print(error.localizedDescription)
        }
    }
    
}
