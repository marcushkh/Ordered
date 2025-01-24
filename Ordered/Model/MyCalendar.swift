
import Foundation

// This Class is adapted from Coding In A Nutshell Youtube Channel
// Source: https://www.youtube.com/watch?v=PZySRHE783s&t=845s&ab_channel=CodingInANutshell
// Modifications: I made modification to make the jumpTo looks better when it is changed from the outside
struct MyCalendar {
    var calendar = Calendar(identifier: .iso8601)
    var today: Date
    var currentDate: Date
    var startOfYear: Date
    let dateFormatter = DateFormatter()
    
    init() {
//        calendar.timeZone = TimeZone(identifier: "UTC")!
//        dateFormatter.timeZone = TimeZone(identifier: "UTC")!
        dateFormatter.dateFormat = "yyyyMMdd"
        
        today = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: Date())) ?? Date()
        currentDate = today
        startOfYear = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        
    }
    
    mutating func setCurrentDate(to dateStr: String) {
        if let d = dateFormatter.date(from: dateStr) {
            currentDate = d
        }
    }
    
    mutating func setCurrentDate(to date: Date) {
        currentDate = date
    }
    
    static func getDate(from dateString: String) -> Date{
        let dateFormatter = DateFormatter()
//        dateFormatter.timeZone = TimeZone(identifier: "UTC")!
        dateFormatter.dateFormat = "yyyyMMdd"
        
        return dateFormatter.date(from: dateString) ?? Date()
    }
    
    static func getDate(from date: Date) -> Date{
        var calendar = Calendar(identifier: .iso8601)
//        calendar.timeZone = TimeZone(identifier: "UTC")!
        
        return calendar.date(from: calendar.dateComponents([.year, .month, .day], from: date)) ?? Date()
    }
    
    //init / load dates
    func datesInYear() -> [Date] {
        let range = calendar.range(of: .day, in: .year, for: startOfYear)!
        let datesArrInYear = range.compactMap({ i in
            calendar.date(byAdding:.day, value: i - 1, to: startOfYear)
        })
        return datesArrInYear
    }
    
    func datesInWeek(from date: Date) -> [Date]{
        let range = calendar.range(of: .weekday, in: .weekOfYear, for: date)!
        let dateArrInWeek = range.compactMap{
            calendar.date(byAdding: .day, value: $0 - 1, to: date)
        }
        return dateArrInWeek
    }
    
    func startDateOfWeeksInAYear() -> [Date]{
        let currentWeek = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startOfYear)
        let startOfWeek = calendar.date(from: currentWeek)
        let range = calendar.range(of: .weekOfYear, in: .year, for: startOfYear)!
        let startOfWeekArr = range.compactMap{
            calendar.date(bySetting: .weekOfYear, value: $0, of: startOfWeek!)
        }
        return startOfWeekArr
    }
    
    func startDateOfWeek(from date: Date) -> Date{
        let currentWeek = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: currentWeek)!
    }
}
