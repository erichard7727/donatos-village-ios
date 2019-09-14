//
//  NewHomeStreamViewController.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 9/14/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit
import VillageCore

final class NewHomeStreamViewController: UIViewController {

    fileprivate var homeStream: NewHomeStream?

}

// MARK: - UIViewController Overrides

extension NewHomeStreamViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        addBehaviors([
            LeftBarButtonBehavior(showing: .menuOrBack)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        getHomeStream()
    }

}

// MARK: - Private Methods

private extension NewHomeStreamViewController {

    func getHomeStream() {

        if homeStream == nil {
//            progressIndicator.show()
        }

        firstly {
            NewHomeStream.fetch()
        }.then { [weak self] homeStream in
            self?.homeStream = homeStream
//            self?.displayUI(homeStream: homeStream)
        }.catch { [weak self] error in
            let alert = UIAlertController(title: "Error", message: "There was a problem downloading your data.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { _ in self?.getHomeStream() }))
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
            self?.present(alert, animated: true, completion: nil)
        }.always { /*[weak self] in*/
//            self?.progressIndicator.hide()
        }
    }

}
