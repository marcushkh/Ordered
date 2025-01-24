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
}
