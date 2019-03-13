//
//  Optional+Utils.swift
//  VillageCore
//
//  Created by Rob Feldmann on 3/1/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation

extension Optional {
    
    /// Returns the wrapped value or throws an error in case it containes nil
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
