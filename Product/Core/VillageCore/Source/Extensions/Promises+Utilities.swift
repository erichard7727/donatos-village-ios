//
//  Promises+Utilities.swift
//  VillageCore
//
//  Created by Rob Feldmann on 2/9/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Promises

/// Syntatic sugar to make executing the first promise in a chain look nicer
/// and more apparent that it is the beginning of the chain.
///
/// - Parameter execute: The Promise to execute
/// - Returns: The resolved Promise
public func firstly<T>(_ execute: (() -> Promise<T>)) -> Promise<T> {
    return execute()
}

/// Syntatic sugar to make executing the first promise in a chain look nicer
/// and more apparent that it is the beginning of the chain.
///
/// - Parameter execute: The Promise to execute
/// - Returns: The resolved Promise
public func firstly<T>(_ execute: (() -> T)) -> Promise<T> {
    let result = execute()
    return Promise(result)
}

extension Promise {
    
    /// Easily converts a Promise<T> to Promise<Void>
    ///
    /// - Returns: A Void Promise
    public func asVoid() -> Promise<Void> {
        return self.then { _ -> Void in
            ()
        }
    }
    
    /// Allows a block of code to be run if the promise chain has not resolved after a certain period of time.
    ///
    /// This is useful for delaying a spinner in cases where the request normally resolves quickly.
    ///
    /// - Parameters:
    ///   - after: The period of time to wait before executing `work`
    ///   - queue: The `DispatchQueue` to use. Default dispatch queue used for
    ///       `Promise`, which is `main` if a queue is not specified.
    ///   - work: The block of code to perform
    /// - Returns: The promise so this function can be part of the chain
    public func ifNotResolved(after: TimeInterval, on queue: DispatchQueue = .promises, _ work: @escaping (() -> Void)) -> Promise {
        
        var resolved: Bool = false
        
        // observe always to get notified of resolution
        self.always {
            resolved = true
        }
        
        // wait the delay period, then check if the promise has not resolved & run the work block
        DispatchQueue.main.asyncAfter(deadline: .now() + after) {
            if !resolved {
                work()
            }
        }
        
        // return this promise so this function can be part of the chain
        return self
    }
}
