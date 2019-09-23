//
//  DataSourcedStackView.swift
//  ClubCorp
//
//  Created by Jack Miller on 5/15/18.
//  Copyright © 2018 Dynamit. All rights reserved.
//

import UIKit

@objc protocol StackViewDataSource: class {
    func arrangedSubviewsForStackView(_ stackView: DataSourcedStackView) -> [UIView]
}

///A `UIStackView` subclass that uses a datasource to populate the arranged subviews.
///
/// * Note: If your stackview has a mix of static views & dynamically populated views, you can still add static views to the stackview in a Storyboard, just be sure to connect an IBOutlet to the UIViewController class, and return the static views in the appropriate position in the StackViewDataSource method (otherwise calling `reloadData()` would remove these views)
class DataSourcedStackView: UIStackView {

    @IBOutlet weak var dataSource: StackViewDataSource?
    
    ///Updates the arrangeSubviews of the UIStackView to match those provided by the `StackViewDataSource.arrangedSubviewsForStackView(:)` method. *Always runs on the main thread
    func reloadData() {
        guard let dataSource = self.dataSource else { return }
        let subviews = dataSource.arrangedSubviewsForStackView(self)
        self.updateArrangedSubviews(with: subviews)
    }
    
    private func updateArrangedSubviews(with newArrangedSubviews:[UIView]) {
        //If array is empty, clear all views & return
        guard newArrangedSubviews.count > 0 else {
            //print("removing all arranged subviews")
            self.arrangedSubviews.forEach({ $0.removeFromSuperview() })
            return
        }
        
        //remove existing subviews that shouldn't be there anymore
        self.arrangedSubviews.filter({ newArrangedSubviews.contains($0) == false }).forEach {
            //print("removed: \($0.description)")
            $0.removeFromSuperview()
        }
        
        //insert new views that don't exist in the stackview currently in the correct position
        newArrangedSubviews.filter({ self.arrangedSubviews.contains($0) == false }).forEach {
            //print("added: \($0.description)")
            self.insertArrangedSubview($0, at: newArrangedSubviews.index(of: $0) ?? 0)
        }
        
        //make sure views are ordred correctly
        newArrangedSubviews.forEach({
            if let newIndex = newArrangedSubviews.index(of: $0), let currentIndex = arrangedSubviews.index(of: $0), newIndex != currentIndex {
                //print("moved (from: \(currentIndex), to: \(newIndex)): \($0.description)")
                self.removeArrangedSubview($0)
                self.insertArrangedSubview($0, at: newIndex)
            }
        })
    }

}
