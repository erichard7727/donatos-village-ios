//
//  URL+StaticString.swift
//  DonatosKit
//
//  Created by Rob Feldmann on 12/26/18.
//  Copyright © 2018 Donatos. All rights reserved.
//

import Foundation

extension URL {
    
    init(staticString string: StaticString) {
        guard let url = URL(string: "\(string)") else {
            preconditionFailure("Invalid static URL string: \(string)")
        }
        self = url
    }
    
}
