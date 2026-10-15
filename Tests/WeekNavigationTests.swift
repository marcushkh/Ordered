import Foundation

@main
struct WeekNavigationTests {
    static func main() {
        for zone in ["Asia/Hong_Kong", "America/New_York"] {
            for firstWeekday in [1, 2] {
                var calendar = Calendar(identifier: .iso8601)
                calendar.timeZone = TimeZone(identifier: zone)!
                calendar.firstWeekday = firstWeekday

                func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
                    calendar.date(from: DateComponents(year: year, month: month, day: day))!
                }
                func navigate(_ selected: Date, by offset: Int, today: Date) -> Date {
                    let start = calendar.dateInterval(of: .weekOfYear, for: selected)!.start
                    let target = calendar.date(byAdding: .weekOfYear, value: offset, to: start)!
                    let result = MyCalendar.selection(inWeekContaining: target, preserving: selected,
                                                      today: today, calendar: calendar)
                    precondition(calendar.dateInterval(of: .weekOfYear, for: result)!.start == target)
                    return result
                }

                let today = date(2026, 10, 15)
                // Every selected weekday stays stable across repeated swipes and year boundaries.
                let base = date(2025, 12, 21)
                for day in 0..<7 {
                    var selected = calendar.date(byAdding: .day, value: day, to: base)!
                    let weekday = calendar.component(.weekday, from: selected)
                    for _ in 0..<15 {
                        selected = navigate(selected, by: 1, today: today)
                        precondition(calendar.component(.weekday, from: selected) == weekday)
                    }
                    for _ in 0..<30 {
                        selected = navigate(selected, by: -1, today: today)
                        precondition(calendar.component(.weekday, from: selected) == weekday)
                    }
                }
                // Entering the current week from either side always selects today.
                let currentStart = calendar.dateInterval(of: .weekOfYear, for: today)!.start
                for direction in [-1, 1] {
                    for day in 0..<7 {
                        let adjacentStart = calendar.date(byAdding: .weekOfYear, value: direction, to: currentStart)!
                        let selected = calendar.date(byAdding: .day, value: day, to: adjacentStart)!
                        precondition(navigate(selected, by: -direction, today: today) == today)
                    }
                }
                // Moving out of the current week follows today's weekday again.
                for direction in [-1, 1] {
                    let selected = navigate(today, by: direction, today: today)
                    precondition(calendar.component(.weekday, from: selected) == calendar.component(.weekday, from: today))
                }
                // Spring and autumn DST transitions preserve Sunday and local midnight.
                for sunday in [date(2026, 3, 1), date(2026, 10, 25)] {
                    let selected = navigate(sunday, by: 1, today: today)
                    precondition(calendar.component(.weekday, from: selected) == 1)
                    precondition(calendar.component(.hour, from: selected) == 0)
                }
            }
        }
        print("PASS: weekday preservation, current-week selection, year boundaries, and DST for Sunday/Monday starts")
    }
}
