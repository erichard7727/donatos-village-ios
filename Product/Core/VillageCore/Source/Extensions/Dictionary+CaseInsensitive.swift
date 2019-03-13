//
//  Dictionary+CaseInsensitive.swift
//  VillageCore
//
//  Created by Rob Feldmann on 2/7/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation

extension Dictionary {
    
    /// Returns the first instance of a value for the provided key
    /// (comparing case insensitive)
    ///
    /// - Parameter searchKey: The key to look for
    /// - Returns: The value, if any
    func valueForCaseInsensitiveKey(_ searchKey: String) -> Any? {
        
        for (_, element) in self.enumerated() {
            if let stringKey = element.key as? String, stringKey.lowercased() == searchKey.lowercased() {
                return element.value
            }
        }
        return nil
    }
}
