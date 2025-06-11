import Foundation

// This Class is adapted from Coding In A Nutshell Youtube Channel
// Source: https://www.youtube.com/watch?v=PZySRHE783s&t=845s&ab_channel=CodingInANutshell
// Modifications: I made modification to make the jumpTo looks better when it is changed from the outside
struct MyCalendar {
    var calendar = Calendar(identifier: .iso8601)
    var today: Date
    var currentDate: Date
    var startDate: Date
    var endDate: Date
    let dateFormatter = DateFormatter()
    
    init() {
        calendar.firstWeekday = Calendar.autoupdatingCurrent.firstWeekday
        dateFormatter.dateFormat = "yyyyMMdd"
        
        let dayStartTime = UserDefaults.standard.integer(forKey: "DayStartTime")
        
        today = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: MyCalendar.getToday())) ?? Date.now
        currentDate = today
        
        // Set a practical date range around current date
        // Get current year and extend range by 50 years in each direction
        let currentYear = calendar.component(.year, from: today)
        let startYear = max(1970, currentYear - 50)  // Don't go before 1970
        let endYear = min(2100, currentYear + 50)    // Don't go past 2100
        
        startDate = calendar.date(from: DateComponents(year: startYear, month: 1, day: 1))!
        endDate = calendar.date(from: DateComponents(year: endYear, month: 12, day: 31))!
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
        dateFormatter.dateFormat = "yyyyMMdd"
        
        return dateFormatter.date(from: dateString) ?? Date()
    }
    
    static func getDate(from date: Date) -> Date{
        let calendar = Calendar(identifier: .iso8601)
        
        return calendar.date(from: calendar.dateComponents([.year, .month, .day], from: date)) ?? Date()
    }
    
    // Generate dates efficiently using DateInterval and stride
    func datesInRange() -> [Date] {
        let interval = DateInterval(start: startDate, end: endDate)
        let dayInterval: TimeInterval = 24 * 60 * 60 // 1 day in seconds
        
        var dates: [Date] = []
        var currentDate = interval.start
        
        while currentDate <= interval.end {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return dates
    }
    
    // Keep the old function name for backward compatibility but redirect to new implementation
    func datesInYear() -> [Date] {
        return datesInRange()
    }
    
    func datesInWeek(from date: Date) -> [Date]{
        let range = calendar.range(of: .weekday, in: .weekOfYear, for: date)!
        let dateArrInWeek = range.compactMap{
            calendar.date(byAdding: .day, value: $0 - 1, to: date)
        }
        return dateArrInWeek
    }
    
    func startDateOfWeeksInRange() -> [Date]{
        var weekStarts: [Date] = []
        
        // Find the first Monday (or first day of week based on locale) at or before startDate
        let firstWeek = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startDate)
        var weekStart = calendar.date(from: firstWeek)!
        
        // Ensure we don't start before our startDate
        if weekStart < startDate {
            weekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
        }
        
        while weekStart <= endDate {
            weekStarts.append(weekStart)
            if let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) {
                weekStart = nextWeek
            } else {
                break
            }
        }
        
        return weekStarts
    }
    
    // Keep the old function name for backward compatibility but redirect to new implementation
    func startDateOfWeeksInAYear() -> [Date]{
        return startDateOfWeeksInRange()
    }
    
    func startDateOfWeek(from date: Date) -> Date{
        let currentWeek = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: currentWeek)!
    }
    
    static func getWeekOrder() -> [Int] {
        var calendar = Calendar(identifier: .iso8601)
        calendar.firstWeekday = Calendar.autoupdatingCurrent.firstWeekday
        
        let isoWeekdays = [0, 1, 2, 3, 4, 5, 6]
        let firstWeekdayIndex = calendar.firstWeekday - 1
        
        let weekdayNumbers: [Int] = Array(isoWeekdays[firstWeekdayIndex...] + isoWeekdays[..<firstWeekdayIndex])
        
        return weekdayNumbers
    }
    
    static func getToday() -> Date{
        let calendar = Calendar.current
        let dayStartTime = UserDefaults.standard.integer(forKey: "DayStartTime")
        
        return calendar.date(from: calendar.dateComponents([.year, .month, .day], from: calendar.date(byAdding: .hour, value: dayStartTime * -1, to: Date.now) ?? Date())) ?? Date()
    }
}
