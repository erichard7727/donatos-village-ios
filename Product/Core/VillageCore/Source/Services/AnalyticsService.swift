//
//  AnalyticsService.swift
//  VillageCore
//
//  Created by Rob Feldmann on 3/14/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation
//import FirebaseAnalytics

public let AnalyticsEventViewItem: String = "AnalyticsEventViewItem"
public let AnalyticsParameterItemLocationID: String = "AnalyticsParameterItemLocationID"
public let AnalyticsParameterItemCategory: String = "AnalyticsParameterItemCategory"
public let AnalyticsParameterItemName: String = "AnalyticsParameterItemName"

public struct AnalyticsService {
    
    public static func logEvent(name: String, parameters: [String: Any]? = nil) {
//        Analytics.logEvent(name, parameters: parameters)
    }
    
}
