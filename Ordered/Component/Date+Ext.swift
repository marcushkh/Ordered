//
//  Date+Ext.swift
//  Ordered
//
//  Created by Kai Hin Hung on 12/8/2024.
//

import Foundation

extension Date {
    func monthYYYY() -> String {
        return self.formatted(.dateTime.month(.wide).year())
    }
    
    static func intToWeekAbbreviation(_ weekday: Int) -> String? {
        let calendar = Calendar(identifier: .iso8601)
        return calendar.shortWeekdaySymbols[weekday % 7]
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
    
    func getHHMM() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: self)
    }
    
    static func getDateFromHHMM(_ str: String) -> Date{
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        let d = formatter.date(from: str)
        return d ?? Date()
    }
    
    static func greaterHHMM(_ str1: String, _ str2: String) -> Bool{
        let date1 = getDateFromHHMM(str1)
        let date2 = getDateFromHHMM(str2)
        
        if date1 >= date2 {
            return true
        } else {
            return false
        }
    }
}
