
import Foundation

struct MyCalendar {
    var calendar = Calendar(identifier: .iso8601)
    var today: Date // Let VM handle this
    var currentDate: Date //Let VM handle this
    var startOfYear: Date //Let Init handle this
    
    
    init() {
        today = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: Date())) ?? Date()
        currentDate = today
        startOfYear = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        
    }
    
    mutating func setCurrentDate(to dateStr: String) {//VM
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        if let d = dateFormatter.date(from: dateStr) {
            currentDate = d
        }
    }
    
    mutating func setCurrentDate(to date: Date) {//VM
        currentDate = date
    }
    
    //init / load dates
    func datesInYear() -> [Date] {//Init
        let range = calendar.range(of: .day, in: .year, for: startOfYear)!
        let datesArrInYear = range.compactMap({ i in
            calendar.date(byAdding:.day, value: i - 1, to: startOfYear)
        })
        return datesArrInYear
    }
    
    func datesInWeek(from date: Date) -> [Date]{//Init
        let range = calendar.range(of: .weekday, in: .weekOfYear, for: date)!
        let dateArrInWeek = range.compactMap{
            calendar.date(byAdding: .day, value: $0 - 1, to: date)
        }
        return dateArrInWeek
    }
    
    func startDateOfWeeksInAYear() -> [Date]{//Init
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
