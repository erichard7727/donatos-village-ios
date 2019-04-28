//
//  NSDate+TimeAgo.swift
//  VillageCore
//
//  Created by Colin Drake on 2/24/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit

public extension Date {
    
    /// Swift port from DateTools library (MIT).
    static func timeAgoSinceDate(_ date:Date, numericDates:Bool) -> String {
        let calendar = Calendar.current
        let now = Date()
        let earliest = (now as NSDate).earlierDate(date)
        let latest = (earliest == now) ? date : now
        let components:DateComponents = (calendar as NSCalendar).components([NSCalendar.Unit.minute , NSCalendar.Unit.hour , NSCalendar.Unit.day , NSCalendar.Unit.weekOfYear , NSCalendar.Unit.month , NSCalendar.Unit.year , NSCalendar.Unit.second], from: earliest, to: latest, options: NSCalendar.Options())
        
        if let year = components.year, year >= 2 {
            return "\(year) years ago"
        } else if let year = components.year, year >= 1 {
            if numericDates {
                return "1 year ago"
            } else {
                return "Last year"
            }
        } else if let month = components.month, month >= 2 {
            return "\(month) months ago"
        } else if let month = components.month, month >= 1 {
            if numericDates {
                return "1 month ago"
            } else {
                return "Last month"
            }
        } else if let weekOfYear = components.weekOfYear, weekOfYear >= 2 {
            return "\(weekOfYear) weeks ago"
        } else if let weekOfYear = components.weekOfYear, weekOfYear >= 1 {
            if numericDates {
                return "1 week ago"
            } else {
                return "Last week"
            }
        } else if let day = components.day, day >= 2 {
            return "\(day) days ago"
        } else if let day = components.day, day >= 1 {
            if numericDates {
                return "1 day ago"
            } else {
                return "Yesterday"
            }
        } else if let hour = components.hour, hour >= 2 {
            return "\(hour) hours ago"
        } else if let hour = components.hour, hour >= 1 {
            if numericDates {
                return "1 hour ago"
            } else {
                return "An hour ago"
            }
        } else if let minute = components.minute, minute >= 2 {
            return "\(minute) minutes ago"
        } else if let minute = components.minute, minute >= 1 {
            if numericDates {
                return "1 minute ago"
            } else {
                return "A minute ago"
            }
        } else if let second = components.second, second >= 3 {
            return "\(second) seconds ago"
        } else {
            return "Just now"
        }
    }
    
}
