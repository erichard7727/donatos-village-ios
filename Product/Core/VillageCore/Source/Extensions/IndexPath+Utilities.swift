//
//  IndexPath+Utilities.swift
//  VillageCore
//
//  Created by Rob Feldmann on 5/14/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation

/// Int <=> NSIndexPath conversion specific to tableview.
/// Used to tag textfields to find place in form.
/// Formula is: (section * 100) + row  --  simple division/modulo can pull apart later.

public extension Int {
    var indexPathRepresentation: IndexPath {
        let section = self / 100
        let row = self % 100
        return IndexPath(row: row, section: section)
    }
}

public extension IndexPath {
    var integerRepresentation: Int {
        return (section * 100) + row
    }
}
