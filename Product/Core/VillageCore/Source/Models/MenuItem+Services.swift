//
//  MenuItem+Services.swift
//  VillageCore
//
//  Created by Sasho Jadrovski on 12/22/20.
//  Copyright © 2020 Dynamit. All rights reserved.
//

import Foundation
import Promises

// MARK: - MenuItemsService

extension MenuItem {
    
    public static func getMenuItems() -> Promise<MenuItems> {
        return MenuItemsService.getMenuItems()
    }
}
