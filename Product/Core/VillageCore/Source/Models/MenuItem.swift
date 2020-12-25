//
//  MenuItem.swift
//  VillageCore
//
//  Created by Sasho Jadrovski on 12/22/20.
//  Copyright © 2020 WillowTree. All rights reserved.
//

import Foundation

/// An alias name that represents a list of menu items
public typealias MenuItems = [MenuItem]

public struct MenuItem {
    public let title: String?
    public let url: String?
    public let order: Int?
}
