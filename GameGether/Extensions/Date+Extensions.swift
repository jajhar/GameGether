//
//  Date+Extensions.swift
//  GameGether
//
//  Created by James Ajhar on 6/24/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation

extension Date {
    
    static var now: Date {
        return Date()
    }
    
    static var today: Date {
        let calendar = Calendar.current
        let today = Date()
        return calendar.startOfDay(for: today)
    }
    
    static var tomorrow: Date? {
        let calendar = Calendar.current
        let today = Date()
        let midnight = calendar.startOfDay(for: today)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: midnight)
        return tomorrow
    }
    
    func normalized() -> Date? {
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: self)
        return midnight
    }
    
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date? {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)
    }
    
    func iso8601Format() -> String {
        return Formatter.iso8601.string(from: self)
    }
    
    func monthDayYearFormat() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter.string(from: self)
    }
    
    func schedulingFormattedString(shorthandWeekday: Bool = false, includeTime: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"

        var dateString = ""

        guard let sevenFromNow = Date().addDays(7) else {
            formatter.dateFormat = "MMM dd, YYYY"
            dateString = formatter.string(from: self)
            return dateString
        }
        
        let timeFormat = minutes > 0 ? "h:mma" : "ha"
        
        if self.normalized() == Date.today.normalized() {
            // Today
            formatter.dateFormat = timeFormat
            dateString = includeTime ? "\(formatter.string(from: self)) Today" : "Today"
        } else if self.normalized() == Date.tomorrow?.normalized() {
            // Tomorrow
            formatter.dateFormat = timeFormat
            dateString = includeTime ? "\(formatter.string(from: self)) Tmrw" : "Tmrw"
        } else if self < sevenFromNow {
            // This week
            let weekdayFormat = shorthandWeekday ? "EEE" : "EEEE"
            formatter.dateFormat = includeTime ? "\(timeFormat) \(weekdayFormat)" : weekdayFormat
            dateString = formatter.string(from: self)
        } else if self.years(from: Date.now) > 1 {
            // next year?
            formatter.dateFormat = includeTime ? "\(timeFormat) EEE, MMM dd YYYY" : "EEE, MMM dd YYYY"
            dateString = formatter.string(from: self)

        } else {
            // This year
            formatter.dateFormat = includeTime ? "\(timeFormat) EEE, MMM dd" : "EEE, MMM dd"
            dateString = formatter.string(from: self)
        }
        
        return dateString
    }
    
    func ggTimestampFormat() -> String {
        let formatter = DateFormatter()
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        
        let dateString: String

        guard let today = Date().normalized(),
            let twoDaysAgo = Date().normalized()?.subtractDays(1),
            let sevenDaysAgo = Date().normalized()?.subtractDays(6) else {
            formatter.dateFormat = "MMM dd, YYYY"
            dateString = formatter.string(from: self)
            return dateString
        }
        
        if self >= today {
            formatter.dateFormat = "h:mm a"
            dateString = "today at " + formatter.string(from: self)
            
        } else if self > twoDaysAgo {
            formatter.dateFormat = "h:mm a"
            dateString = "yesterday at " + formatter.string(from: self)
            
        } else if self > sevenDaysAgo {
            formatter.dateFormat = "EEE h:mm a"
            dateString = formatter.string(from: self)
            
        } else {
            formatter.dateFormat = "MMM dd, YYYY"
            dateString = formatter.string(from: self)
        }
        
        return dateString
    }
    
    func schedulingCountdownString() -> String {
               
        var dateString = ""
        
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.day, .hour, .minute], from: self)
        let nowComponents = calendar.dateComponents([.day, .hour, .minute], from: Date())

        let difference = calendar.dateComponents([.day, .hour, .minute], from: nowComponents, to: timeComponents)
        
        if let day = difference.day, day > 2 {
            // Greater than 2 days from now
            dateString = "\(day) days"
            
        } else if let day = difference.day, day > 0 {
            // Less than 2 days, greater than 1 day
            dateString = "\(day) day"
            
        } else {
            // Today
            if let hour = difference.hour, hour > 0 {
                dateString = "\(hour) hrs"
            }
            
            if let min = difference.minute, min > 0 {
                dateString = "\(dateString) \(min) min\(min > 1 ? "s" : "")"
            }
        }
        
        return dateString
    }

    
    func partyCreatedTimestampFormat() -> String {
        
        /*
        Less than 1 hour, display by minutes
        Greater 1 hour, display "an hour ago"
        Greater than 2 hours, then display "recently today"
        If it's yesterday, then display "yesterday"
        Older than yesterday, then display the date only "mmm dd"
         */
        
        let formatter = DateFormatter()
        
        let dateString: String
        
        guard let oneHourAgo = Date().subtractHours(1),
            let twoHoursAgo = Date().subtractHours(2),
            let today = Date().normalized(),
            let twoDaysAgo = Date().normalized()?.subtractDays(1) else {
                formatter.dateFormat = "MMM dd, YYYY"
                dateString = formatter.string(from: self)
                return dateString
        }
        
        if self > oneHourAgo {
            formatter.dateFormat = "mm"
            
            let calendar = Calendar.current
            let timeComponents = calendar.dateComponents([.hour, .minute], from: self)
            let nowComponents = calendar.dateComponents([.hour, .minute], from: Date())
            
            let difference = calendar.dateComponents([.minute], from: timeComponents, to: nowComponents).minute
            dateString = "\(difference ?? 1) mins ago"
            
        } else if self > twoHoursAgo {
            dateString = "an hour ago"
            
        } else if self < twoHoursAgo, self >= today {
            dateString = "recently today"
            
        } else if self < today, self > twoDaysAgo {
            dateString = "yesterday"
        } else {
            formatter.dateFormat = "MMM dd"
            dateString = formatter.string(from: self)
        }
        
        return dateString
    }
    
    func userStatusTimestampFormat() -> String {
        
        /*
         Online = active in-app and under 5 mins out-of-app
         “active now”
         
         Away = over 5 mins and less than 30 minutes out-of-app
         “active 5m ago” to “active 30m ago”
         
         Offline = greater than 30 mins
         "active 30m" ago to "active 59m ago"
         "active 1h ago" to "active 23h ago"
         "active 1d ago" to "active 6d ago"
         "active 1w ago" to "active #w ago"         */
        
        let formatter = DateFormatter()
        let dateString: String
        let now = Date()
        
        let cal = Calendar.current
        let components = cal.dateComponents([.minute, .hour, .day, .weekOfYear, .year], from: self, to: now)
        
        guard let hoursAgo = components.hour,
            let daysAgo = components.day,
            let yearsAgo = components.year
        else {
                formatter.dateFormat = "active MMM dd, YYYY"
                dateString = formatter.string(from: self)
                return dateString
        }
        
        if hoursAgo < 1 {
            dateString = "active \(components.minute ?? 0)m ago"
            
        } else if daysAgo < 1 {
            dateString = "active \(components.hour ?? 0)h ago"

        } else if daysAgo <= 7 {
            dateString = "active \(components.day ?? 0)d ago"

        } else if yearsAgo < 1 {
            dateString = "active \(components.weekOfYear ?? 0)w ago"
            
        } else {
            dateString = "active \(components.year ?? 0)y ago"
        }
        
        return dateString
    }
    
    func addNanoseconds(_ nanoseconds: Int) -> Date? {
        return Calendar.current.date(byAdding: .nanosecond, value: nanoseconds, to: self)
    }
    
    func addSeconds(_ seconds: Int) -> Date? {
        return Calendar.current.date(byAdding: .second, value: seconds, to: self)
    }
    
    func addMinutes(_ minutes: Int) -> Date? {
        return Calendar.current.date(byAdding: .minute, value: minutes, to: self)
    }
    
    func addHours(_ hours: Int) -> Date? {
        return Calendar.current.date(byAdding: .hour, value: hours, to: self)
    }
    
    func addDays(_ days: Int) -> Date? {
        return Calendar.current.date(byAdding: .day, value: days, to: self)
    }
    
    func addMonths(_ months: Int) -> Date? {
        return Calendar.current.date(byAdding: .month, value: months, to: self)
    }
    
    func subtractNanoseconds(_ nanoseconds: Int) -> Date? {
        return Calendar.current.date(byAdding: .nanosecond, value: -nanoseconds, to: self)
    }
    
    func subtractSeconds(_ seconds: Int) -> Date? {
        return Calendar.current.date(byAdding: .second, value: -seconds, to: self)
    }
    
    func subtractMinutes(_ minutes: Int) -> Date? {
        return Calendar.current.date(byAdding: .minute, value: -minutes, to: self)
    }
    
    func subtractHours(_ hours: Int) -> Date? {
        return Calendar.current.date(byAdding: .hour, value: -hours, to: self)
    }
    
    func subtractDays(_ days: Int) -> Date? {
        return Calendar.current.date(byAdding: .day, value: -days, to: self)
    }
    
    func subtractYears(_ years: Int) -> Date? {
        return Calendar.current.date(byAdding: .year, value: -years, to: self)
    }
    
    /// Returns the amount of years from another date
    func years(from date: Date) -> Int {
        return abs(Calendar.current.dateComponents([.year], from: date, to: self).year ?? 0)
    }
    /// Returns the amount of months from another date
    func months(from date: Date) -> Int {
        return abs(Calendar.current.dateComponents([.month], from: date, to: self).month ?? 0)
    }
    /// Returns the amount of weeks from another date
    func weeks(from date: Date) -> Int {
        return abs(Calendar.current.dateComponents([.weekOfMonth], from: date, to: self).weekOfMonth ?? 0)
    }
    /// Returns the amount of days from another date
    func days(from date: Date) -> Int {
        return abs(Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0)
    }
    /// Returns the amount of hours from another date
    func hours(from date: Date) -> Int {
        return abs(Calendar.current.dateComponents([.hour], from: date, to: self).hour ?? 0)
    }
    /// Returns the amount of minutes from another date
    func minutes(from date: Date) -> Int {
        return abs(Calendar.current.dateComponents([.minute], from: date, to: self).minute ?? 0)
    }
    /// Returns the amount of seconds from another date
    func seconds(from date: Date) -> Int {
        return abs(Calendar.current.dateComponents([.second], from: date, to: self).second ?? 0)
    }
    /// Returns the a custom time interval description from another date
    func offset(from date: Date) -> String {
        if years(from: date)   > 0 { return "\(years(from: date))y"   }
        if months(from: date)  > 0 { return "\(months(from: date))M"  }
        if weeks(from: date)   > 0 { return "\(weeks(from: date))w"   }
        if days(from: date)    > 0 { return "\(days(from: date))d"    }
        if hours(from: date)   > 0 { return "\(hours(from: date))h"   }
        if minutes(from: date) > 0 { return "\(minutes(from: date))m" }
        if seconds(from: date) > 0 { return "\(seconds(from: date))s" }
        return ""
    }
    
    var nanoseconds: Int {
        return Calendar.current.component(.nanosecond, from: self)
    }
    
    var seconds: Int {
        return Calendar.current.component(.second, from: self)
    }
    
    var minutes: Int {
        return Calendar.current.component(.minute, from: self)
    }
    
    var hour: Int {
        return Calendar.current.component(.hour, from: self)
    }
    
    var day: Int {
        return Calendar.current.component(.day, from: self)
    }
}

extension Formatter {
    
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
