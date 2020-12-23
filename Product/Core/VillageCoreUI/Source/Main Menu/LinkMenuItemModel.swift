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
    let order: Int
}

// MARK: - Convenience Initializers

extension LinkMenuItemModel {
    
    init(from menuItem: MenuItem) {
        self.init(title: menuItem.title, url: menuItem.url, order: menuItem.order)
    }
}

// MARK: - Comparable

extension LinkMenuItemModel: Comparable {
    
    static func < (lhs: LinkMenuItemModel, rhs: LinkMenuItemModel) -> Bool {
        return lhs.order < rhs.order
    }
}
