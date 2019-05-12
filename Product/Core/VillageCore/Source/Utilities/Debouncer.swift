//
//  Debouncer.swift
//  VillageCore
//
//  Created by Rob Feldmann on 5/12/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation

/// A utility to limit the rate at which a function can fire.
public class Debouncer {
    
    private var timer: Timer? {
        willSet {
            // Invalidate the existing timer
            timer?.invalidate()
        }
    }
    
    public init() { }

    /// Perform a given task after the given TimeInterval.
    ///
    /// Usage Example:
    /// ```
    /// let searchDebouncer = Debouncer()
    ///
    /// func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    ///     searchDebouncer.debounce(afterTimeInterval: 3) {
    ///         print("Performing a search request...")
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - afterTimeInterval: The number of seconds to wait before performing
    ///                        the task.
    ///   - task: The task to perform.
    public func debounce(afterTimeInterval seconds: TimeInterval, task performTask: @escaping () -> Void ) {
        timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false, block: { _ in
            performTask()
        })
    }
    
}
