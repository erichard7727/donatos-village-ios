//
//  Bundle+Version.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 3/24/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation

extension Bundle {
    
    var vlg_markingVersion: String {
        return (self.infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""
    }
    
    var vlg_buildVersion: String {
        return (self.infoDictionary?["CFBundleVersion"] as? String) ?? ""
    }
    
}
