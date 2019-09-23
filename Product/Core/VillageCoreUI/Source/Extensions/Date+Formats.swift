//
//  Date+Formats.swift
//  VillageCoreUI
//
//  Created by Jack Miller on 9/18/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation

extension Date {
    
    var longformFormat: String {
        return self.custom(format: "MMMM d, yyyy")
    }
    
    func custom(format: String) -> String {
        let df = DateFormatter()
        df.dateFormat = format
        return df.string(from: self)
    }
}
