//
//  Date+Ext.swift
//  Ordered
//
//  Created by Kai Hin Hung on 12/8/2024.
//

import Foundation

extension Date {
    static func intToWeekAbbreviation(_ weekday: Int) -> String {
        let calendar = Calendar(identifier: .iso8601)
        return calendar.shortWeekdaySymbols[weekday % 7]
    }
    
    static func intToFullName(_ weekday: Int) -> String {
        var calendar = Calendar(identifier: .iso8601)
        calendar.locale = Locale(identifier: "en_US")
        return calendar.weekdaySymbols[(weekday) % 7]
    }
    
    func monthYYYY() -> String {
        return self.formatted(.dateTime.month(.wide).year())
    }
    
    func getWeekInt() -> Int {
        let calendar = Calendar(identifier: .iso8601)
        return calendar.component(.weekday, from: self) - 1
    }
    
    func weekDayAbbrev() -> String {
        return self.formatted(.dateTime .weekday(.abbreviated))
    }
    
    func dayNum() -> String{
        return self.formatted(.dateTime .day())
    }
    
    func getYYMMDD() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyMMdd"
        return dateFormatter.string(from: self)
    }
    
    static func getDateFromYYMMDD(_ str: String) -> Date{
        let formatter = DateFormatter()
        formatter.dateFormat = "yyMMdd"
        
        let d = formatter.date(from: str)
        return d ?? Date()
    }
    
    func getHHMM() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        return dateFormatter.string(from: self)
    }
    
    static func getDateFromHHMM(_ str: String) -> Date{
        let dateFormatter = DateFormatter()
        
        let currentDate = MyCalendar.getToday()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate)
        let day = calendar.component(.day, from: currentDate)
        
        let dateString = String(format: "%04d%02d%02d%@", year, month, day, str)
        
        dateFormatter.dateFormat = "yyyyMMddHH:mm:ss"
        
        return dateFormatter.date(from: dateString) ?? Date()
    }
    
    static func greaterHHMM(_ str1: String, _ str2: String) -> Bool{
        let calendar = Calendar.current
        let dayStartTime = UserDefaults.standard.integer(forKey: "DayStartTime")
        print(dayStartTime)
        
        var date1 = getDateFromHHMM(str1)
        var date2 = getDateFromHHMM(str2)
        
        if calendar.component(.hour, from: date1) < dayStartTime {
            date1 = calendar.date(byAdding: .day, value: 1, to: date1) ?? date1
        }
        if calendar.component(.hour, from: date2) < dayStartTime {
            date2 = calendar.date(byAdding: .day, value: 1, to: date2) ?? date2
        }
        
        if date1 > date2 {
            return true
        } else {
            return false
        }
    }
}
