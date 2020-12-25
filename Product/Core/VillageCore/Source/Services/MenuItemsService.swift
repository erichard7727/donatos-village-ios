//
//  MenuItemsService.swift
//  VillageCore
//
//  Created by Sasho Jadrovski on 12/22/20.
//  Copyright © 2020 WillowTree. All rights reserved.
//

import Foundation
import Promises
import SwiftyJSON

public struct MenuItemsService {
    
    private init() {}
    
    public static func getMenuItems() -> Promise<MenuItems> {
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
    
    init(from response: JSON) {
        self.init(title: response["title"].string, url: response["url"].string, order: response["order"].int)
    }
}
