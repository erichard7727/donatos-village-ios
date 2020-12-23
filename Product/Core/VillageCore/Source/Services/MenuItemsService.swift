//
//  MenuItemsService.swift
//  VillageCore
//
//  Created by Sasho Jadrovski on 12/22/20.
//  Copyright © 2020 Dynamit. All rights reserved.
//

import Foundation
import Promises
import SwiftyJSON

struct MenuItemsService {
    
    private init() {}
    
    static func getMenuItems() -> Promise<MenuItems> {
        return firstly {
            let menuItems = VillageCoreAPI.menuItems
            return VillageService.shared.request(target: menuItems)
        }.then { (json: JSON) -> MenuItems in
            let menuItems = json["menuItems"].arrayValue.compactMap(MenuItem.init)
            return menuItems
        }
    }
}

// MARK: - SwiftyJSON Extensions

internal extension MenuItem {
    
    init?(from response: JSON) {
        guard let url = response["url"].url else { return nil }
        self.init(title: response["title"].stringValue, url: url, order: response["order"].intValue)
    }
}
