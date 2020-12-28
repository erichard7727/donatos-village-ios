//
//  LinkMenuItemModel.swift
//  VillageCoreUI
//
//  Created by Nikola Angelkovik on 12/21/20.
//  Copyright © 2020 Dynamit. All rights reserved.
//

import Foundation
import VillageCore

struct LinkMenuItemModel {
    
    let title: String
    let url: URL
    private let order: Int?
}

// MARK: - Convenience Initializers

extension LinkMenuItemModel {
    
    init?(from menuItem: MenuItem) {
        guard
            let title = menuItem.title,
            let urlString = menuItem.url,
            let url = URL(string: urlString)
            else {
                return nil
        }
        self.init(title: title, url: url, order: menuItem.order)
    }
}

// MARK: - Comparable

extension LinkMenuItemModel: Comparable {
    
    static func < (lhs: LinkMenuItemModel, rhs: LinkMenuItemModel) -> Bool {
        if let lhsOrder = lhs.order, let rhsOrder = rhs.order {
            return lhsOrder < rhsOrder
        }
        return lhs.title < rhs.title
    }
}
