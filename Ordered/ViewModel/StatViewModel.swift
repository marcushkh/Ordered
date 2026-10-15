import SwiftUI
import CoreData

final class StatViewModel: ObservableObject {
    @Published var range: StatisticRange = .week
    @Published var currentDate = MyCalendar.getToday()
    @Published var selectedEvent: Event?
    @Published var searchEventName = ""

    private let calendar = Calendar.current

    func returnToCurrentPeriod() {
        currentDate = MyCalendar.getToday()
    }

    func selectRange(_ range: StatisticRange) {
        self.range = range
        currentDate = MyCalendar.getToday()
    }

    func selectEvent(_ event: Event) {
        selectedEvent = event
    }

    func clearSelectedEvent() {
        selectedEvent = nil
    }

    func currentDates(dayPlannerVM: DayPlannerViewModel) -> [Date] {
        dates(for: currentDate, range: range, dayPlannerVM: dayPlannerVM)
    }

    func previousDates(dayPlannerVM: DayPlannerViewModel) -> [Date] {
        let anchor = calendar.date(
            byAdding: range.calendarComponent,
            value: -1,
            to: currentDate
        ) ?? currentDate
        return dates(for: anchor, range: range, dayPlannerVM: dayPlannerVM)
    }

    func chartDateGroups(dayPlannerVM: DayPlannerViewModel) -> [[Date]] {
        let dates = currentDates(dayPlannerVM: dayPlannerVM)
        if range == .week {
            return dates.map { [$0] }
        }
        return stride(from: 0, to: dates.count, by: 7).map {
            Array(dates[$0..<min($0 + 7, dates.count)])
        }
    }

    func chartColumns(
        completedEvents: [Event_Cal],
        dayPlannerVM: DayPlannerViewModel
    ) -> [StatisticColumn] {
        chartDateGroups(dayPlannerVM: dayPlannerVM).enumerated().map { index, dates in
            StatisticColumn(
                id: index,
                label: range == .week
                    ? (dates.first?.weekDayAbbrev() ?? "")
                    : "W\(index + 1)",
                shortLabel: range == .week
                    ? String((dates.first?.weekDayAbbrev() ?? " ").prefix(1))
                    : "W\(index + 1)",
                count: completionCount(completedEvents: completedEvents, dates: dates)
            )
        }
    }

    func percentChange(
        completedEvents: [Event_Cal],
        dayPlannerVM: DayPlannerViewModel
    ) -> Int {
        let current = completionCount(
            completedEvents: completedEvents,
            dates: currentDates(dayPlannerVM: dayPlannerVM)
        )
        let previous = completionCount(
            completedEvents: completedEvents,
            dates: previousDates(dayPlannerVM: dayPlannerVM)
        )
        guard previous > 0 else { return current == 0 ? 0 : 100 }
        return Int((Double(current - previous) / Double(previous) * 100).rounded())
    }

    func rankedStatistics(
        allEvents: [Event],
        completedEvents: [Event_Cal],
        dayPlannerVM: DayPlannerViewModel
    ) -> [EventStatistic] {
        allEvents.map {
            statistics(
                for: $0,
                completedEvents: completedEvents,
                dayPlannerVM: dayPlannerVM
            )
        }
        .sorted {
            if $0.event.isFavourite != $1.event.isFavourite {
                return $0.event.isFavourite
            }
            if $0.total == $1.total {
                return $0.event.order < $1.event.order
            }
            return $0.total > $1.total
        }
    }

    func statistics(
        for event: Event,
        completedEvents: [Event_Cal],
        dayPlannerVM: DayPlannerViewModel
    ) -> EventStatistic {
        let counts = chartDateGroups(dayPlannerVM: dayPlannerVM).map {
            completionCount(event: event, completedEvents: completedEvents, dates: $0)
        }
        let total = counts.reduce(0, +)
        let previous = completionCount(
            event: event,
            completedEvents: completedEvents,
            dates: previousDates(dayPlannerVM: dayPlannerVM)
        )
        return EventStatistic(
            event: event,
            columnCounts: counts,
            total: total,
            previousTotal: previous,
            delta: total - previous
        )
    }

    func eventColumns(
        for event: Event,
        completedEvents: [Event_Cal],
        dayPlannerVM: DayPlannerViewModel
    ) -> [StatisticColumn] {
        chartDateGroups(dayPlannerVM: dayPlannerVM).enumerated().map { index, dates in
            StatisticColumn(
                id: index,
                label: range == .week
                    ? String((dates.first?.weekDayAbbrev() ?? " ").prefix(1))
                    : "W\(index + 1)",
                shortLabel: "",
                count: completionCount(
                    event: event,
                    completedEvents: completedEvents,
                    dates: dates
                )
            )
        }
    }

    func completionCount(
        event: Event? = nil,
        completedEvents: [Event_Cal],
        dates: [Date]
    ) -> Int {
        let dateKeys = Set(dates.map { $0.getYYMMDD() })
        return completedEvents.reduce(into: 0) { result, completion in
            guard let key = completion.cal?.date,
                  dateKeys.contains(key) else { return }
            guard event == nil || completion.parent == event else { return }
            result += 1
        }
    }

    func currentStreak(for event: Event, completedEvents: [Event_Cal]) -> Int {
        let completedDateKeys = Set(completedEvents.compactMap { completion -> String? in
            guard completion.parent == event else { return nil }
            return completion.cal?.date
        })
        var cursor = MyCalendar.getToday()
        if !completedDateKeys.contains(cursor.getYYMMDD()) {
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        var streak = 0
        while completedDateKeys.contains(cursor.getYYMMDD()) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previous
        }
        return streak
    }

    func activeDayCount(
        for event: Event,
        completedEvents: [Event_Cal],
        dayPlannerVM: DayPlannerViewModel
    ) -> Int {
        currentDates(dayPlannerVM: dayPlannerVM).filter {
            completionCount(
                event: event,
                completedEvents: completedEvents,
                dates: [$0]
            ) > 0
        }
        .count
    }

    func bestDay(
        for event: Event,
        completedEvents: [Event_Cal],
        dayPlannerVM: DayPlannerViewModel
    ) -> String {
        let values = currentDates(dayPlannerVM: dayPlannerVM).map {
            (
                $0,
                completionCount(
                    event: event,
                    completedEvents: completedEvents,
                    dates: [$0]
                )
            )
        }
        guard let best = values.max(by: { $0.1 < $1.1 }), best.1 > 0 else {
            return "—"
        }
        return range == .week
            ? best.0.formatted(.dateTime.weekday(.wide))
            : best.0.formatted(.dateTime.month(.abbreviated).day())
    }

    func shareLabel(
        for event: Event,
        completedEvents: [Event_Cal],
        dayPlannerVM: DayPlannerViewModel
    ) -> String {
        let dates = currentDates(dayPlannerVM: dayPlannerVM)
        let total = completionCount(completedEvents: completedEvents, dates: dates)
        guard total > 0 else { return "0%" }
        let eventTotal = completionCount(
            event: event,
            completedEvents: completedEvents,
            dates: dates
        )
        let share = Double(eventTotal) / Double(total) * 100
        return "\(Int(share.rounded()))%"
    }

    func usualTickTime(
        for event: Event,
        completedEvents: [Event_Cal],
        dayPlannerVM: DayPlannerViewModel
    ) -> String {
        let dateKeys = Set(currentDates(dayPlannerVM: dayPlannerVM).map { $0.getYYMMDD() })
        let minutes = completedEvents.compactMap { completion -> Int? in
            guard completion.parent == event,
                  let key = completion.cal?.date,
                  dateKeys.contains(key),
                  let time = completion.aEndTime ?? completion.aStartTime else {
                return nil
            }
            let parts = time.split(separator: ":").compactMap { Int($0) }
            guard parts.count >= 2 else { return nil }
            return parts[0] * 60 + parts[1]
        }
        guard !minutes.isEmpty else { return "—" }
        let average = minutes.reduce(0, +) / minutes.count
        return String(format: "%02d:%02d", average / 60, average % 60)
    }

    func periodLabel(dayPlannerVM: DayPlannerViewModel) -> String {
        let dates = currentDates(dayPlannerVM: dayPlannerVM)
        guard let first = dates.first, let last = dates.last else { return "" }
        if range == .month {
            return first.formatted(.dateTime.month(.wide).year())
        }
        return "\(first.formatted(.dateTime.month(.abbreviated).day())) – \(last.formatted(.dateTime.month(.abbreviated).day()))"
    }

    func canStepForward(dayPlannerVM: DayPlannerViewModel) -> Bool {
        guard let currentStart = currentDates(dayPlannerVM: dayPlannerVM).first,
              let todayStart = dates(
                for: MyCalendar.getToday(),
                range: range,
                dayPlannerVM: dayPlannerVM
              ).first else {
            return false
        }
        return currentStart < todayStart
    }

    func stepPeriod(_ direction: Int, dayPlannerVM: DayPlannerViewModel) {
        guard direction < 0 || canStepForward(dayPlannerVM: dayPlannerVM) else {
            return
        }
        currentDate = calendar.date(
            byAdding: range.calendarComponent,
            value: direction,
            to: currentDate
        ) ?? currentDate
    }

    func eventHeadline(
        for event: Event,
        completedEvents: [Event_Cal],
        dayPlannerVM: DayPlannerViewModel
    ) -> String {
        let delta = statistics(
            for: event,
            completedEvents: completedEvents,
            dayPlannerVM: dayPlannerVM
        ).delta
        if delta > 0 { return "Up \(delta) on last \(range.unit)!!" }
        if delta < 0 { return "Down \(abs(delta)) on last \(range.unit)" }
        return "Steady as last \(range.unit)"
    }

    func eventColor(_ event: Event) -> Color {
        if let categoryColor = event.activeCategories.first?.color {
            return Color(hex: categoryColor)
        }
        let palette = K.categoryColors
        return Color(hex: palette[Int(event.order) % palette.count])
    }

    func deltaColor(_ delta: Int) -> Color {
        if delta > 0 { return Color(hex: "BBF3BB") }
        if delta < 0 { return Color(hex: "F8CACF") }
        return .color1
    }

    func signed(_ value: Int) -> String {
        value >= 0 ? "+\(value)" : "−\(abs(value))"
    }

    private func dates(
        for anchor: Date,
        range: StatisticRange,
        dayPlannerVM: DayPlannerViewModel
    ) -> [Date] {
        switch range {
        case .week:
            let start = dayPlannerVM.startDateOfWeek(from: anchor)
            return (0..<7).compactMap {
                calendar.date(byAdding: .day, value: $0, to: start)
            }
        case .month:
            guard let interval = calendar.dateInterval(of: .month, for: anchor),
                  let dayRange = calendar.range(of: .day, in: .month, for: anchor) else {
                return []
            }
            return dayRange.compactMap {
                calendar.date(byAdding: .day, value: $0 - 1, to: interval.start)
            }
        }
    }
}

enum StatisticRange: String, CaseIterable, Identifiable {
    case week
    case month

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var unit: String { rawValue }
    var calendarComponent: Calendar.Component {
        self == .week ? .weekOfYear : .month
    }
}

struct StatisticColumn: Identifiable {
    let id: Int
    let label: String
    let shortLabel: String
    let count: Int
}

struct EventStatistic: Identifiable {
    let event: Event
    let columnCounts: [Int]
    let total: Int
    let previousTotal: Int
    let delta: Int

    var id: NSManagedObjectID { event.objectID }
}
