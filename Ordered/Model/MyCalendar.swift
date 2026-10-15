import Foundation

// This Class is adapted from Coding In A Nutshell Youtube Channel
// Source: https://www.youtube.com/watch?v=PZySRHE783s&t=845s&ab_channel=CodingInANutshell
// Modifications: I made modification to make the jumpTo looks better when it is changed from the outside
struct MyCalendar {
    var calendar: Calendar { Self.weekCalendar }

    /// Zero follows iOS; 1 selects Sunday and 2 selects Monday.
    static func resolvedFirstWeekday(_ preference: Int, systemCalendar: Calendar = .autoupdatingCurrent) -> Int {
        (1...2).contains(preference) ? preference : systemCalendar.firstWeekday
    }

    static var weekCalendar: Calendar {
        var calendar = Calendar(identifier: .iso8601)
        calendar.firstWeekday = resolvedFirstWeekday(UserDefaults.standard.integer(forKey: "FirstWeekday"))
        return calendar
    }
    var today: Date
    var currentDate: Date
    var startDate: Date
    var endDate: Date
    let dateFormatter = DateFormatter()
    
    init() {
        let calendar = Self.weekCalendar
        dateFormatter.dateFormat = "yyyyMMdd"
        
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
        let calendar = weekCalendar
        
        let isoWeekdays = [0, 1, 2, 3, 4, 5, 6]
        let firstWeekdayIndex = calendar.firstWeekday - 1
        
        let weekdayNumbers: [Int] = Array(isoWeekdays[firstWeekdayIndex...] + isoWeekdays[..<firstWeekdayIndex])
        
        return weekdayNumbers
    }
    
    static let defaultDayStartHour = 4

    static var dayStartHour: Int {
        let saved = UserDefaults.standard.object(forKey: "DayStartTime") as? Int
        return min(23, max(0, saved ?? defaultDayStartHour))
    }

    static func getToday() -> Date {
        day(containing: .now, startingAt: dayStartHour)
    }

    /// Week navigation keeps the selected weekday, but returning to this week selects today.
    static func selection(inWeekContaining target: Date, preserving selected: Date,
                          today: Date, calendar: Calendar) -> Date {
        let start = calendar.dateInterval(of: .weekOfYear, for: target)?.start
            ?? calendar.startOfDay(for: target)
        if let currentWeek = calendar.dateInterval(of: .weekOfYear, for: today),
           currentWeek.start == start {
            return calendar.startOfDay(for: today)
        }
        let weekday = calendar.component(.weekday, from: selected)
        let offset = (weekday - calendar.component(.weekday, from: start) + 7) % 7
        return calendar.date(byAdding: .day, value: offset, to: start) ?? start
    }

    /// Compare local clock hours instead of subtracting elapsed hours across DST changes.
    static func day(containing date: Date, startingAt hour: Int, calendar: Calendar = .current) -> Date {
        let midnight = calendar.startOfDay(for: date)
        guard calendar.component(.hour, from: date) < hour else { return midnight }
        return calendar.date(byAdding: .day, value: -1, to: midnight) ?? midnight
    }
}
