//
//  Optional+Utils.swift
//  VillageCore
//
//  Created by Rob Feldmann on 3/1/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation

public extension Optional {

    /// Returns the wrapped value or the expression in case it contains nil
    ///
    /// - Parameter expression: The expression to evaluate if nil
    /// - Returns: The wrapped value if not nil, else the expression's value
    func or<T>(_ expression: @autoclosure () -> T) -> T {
        return self as? T ?? expression()
    }
    
    /// Returns the wrapped value or throws an error in case it containe nil
    ///
    /// Example usage:
    ///
    /// ```
    /// let optionalString: String? = nil
    /// return try optionalString.orThrow(ErrorType.reason)
    /// ```
    ///
    /// - Parameter errorExpression: The error expression to evaluate if nil
    /// - Returns: The wrapped value, if not nil
    /// - Throws: If nil, returns the `errorExpression`
    func orThrow(_ errorExpression: @autoclosure () -> Error) throws -> Wrapped {
        guard let value = self else {
            throw errorExpression()
        }
        return value
    }
    
}
