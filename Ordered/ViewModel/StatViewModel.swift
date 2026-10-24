import SwiftUI
import CoreData

final class StatViewModel: ObservableObject {
    @Published var range: StatisticRange = .week
    @Published var currentDate = MyCalendar.getToday()
    @Published var selectedEvent: Event?
    @Published var searchEventName = ""

    private var calendar: Calendar { .autoupdatingCurrent }

    private struct PeriodKey: Equatable {
        let anchor: Date
        let range: StatisticRange
        let firstWeekday: Int
        let timeZone: String
        let calendar: String
    }
    private struct EventRankKey: Equatable {
        let id: NSManagedObjectID
        let pinned: Bool
        let order: Int16
    }
    private struct RankingKey: Equatable {
        let snapshotID: UUID
        let period: PeriodKey
        let events: [EventRankKey]
    }
    private var periodCache: (key: PeriodKey, current: [Date], previous: [Date])?
    private var rankingCache: (key: RankingKey, rows: [EventStatistic])?
    private var chartCache: (snapshotID: UUID, period: PeriodKey, columns: [StatisticColumn])?
    private(set) var rankingBuildCount = 0

    private var periodKey: PeriodKey {
        PeriodKey(anchor: currentDate, range: range,
                  firstWeekday: MyCalendar.weekCalendar.firstWeekday,
                  timeZone: calendar.timeZone.identifier,
                  calendar: String(describing: calendar.identifier))
    }

    private func preparePeriod(dayPlannerVM: DayPlannerViewModel) {
        let key = periodKey
        guard periodCache?.key != key else { return }
        let previous = calendar.date(byAdding: range.calendarComponent, value: -1, to: currentDate) ?? currentDate
        periodCache = (key, dates(for: currentDate, range: range, dayPlannerVM: dayPlannerVM),
                       dates(for: previous, range: range, dayPlannerVM: dayPlannerVM))
    }

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
        preparePeriod(dayPlannerVM: dayPlannerVM)
        return periodCache?.current ?? []
    }

    func previousDates(dayPlannerVM: DayPlannerViewModel) -> [Date] {
        preparePeriod(dayPlannerVM: dayPlannerVM)
        return periodCache?.previous ?? []
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
        completions: CompletionSnapshot,
        dayPlannerVM: DayPlannerViewModel
    ) -> [StatisticColumn] {
        let key = periodKey
        if let cache = chartCache, cache.snapshotID == completions.identity, cache.period == key {
            return cache.columns
        }
        let columns = chartDateGroups(dayPlannerVM: dayPlannerVM).enumerated().map { index, dates in
            StatisticColumn(
                id: index,
                label: range == .week
                    ? (dates.first?.weekDayAbbrev() ?? "")
                    : "W\(index + 1)",
                shortLabel: range == .week
                    ? String((dates.first?.weekDayAbbrev() ?? " ").prefix(1))
                    : "W\(index + 1)",
                count: completionCount(completions: completions, dates: dates)
            )
        }
        chartCache = (completions.identity, key, columns)
        return columns
    }

    func percentChange(
        completions: CompletionSnapshot,
        dayPlannerVM: DayPlannerViewModel
    ) -> Int {
        let current = completionCount(
            completions: completions,
            dates: currentDates(dayPlannerVM: dayPlannerVM)
        )
        let previous = completionCount(
            completions: completions,
            dates: previousDates(dayPlannerVM: dayPlannerVM)
        )
        guard previous > 0 else { return current == 0 ? 0 : 100 }
        return Int((Double(current - previous) / Double(previous) * 100).rounded())
    }

    func rankedStatistics(
        allEvents: [Event],
        completions: CompletionSnapshot,
        dayPlannerVM: DayPlannerViewModel
    ) -> [EventStatistic] {
        let key = RankingKey(snapshotID: completions.identity, period: periodKey,
                             events: allEvents.map { EventRankKey(id: $0.objectID, pinned: $0.isFavourite, order: $0.order) })
        if let cached = rankingCache, cached.key == key { return cached.rows }
        let columnDays = chartDateGroups(dayPlannerVM: dayPlannerVM).map { $0.map { $0.getYYMMDD() } }
        let previousDays = previousDates(dayPlannerVM: dayPlannerVM).map { $0.getYYMMDD() }
        let rows = allEvents.map { event in
            let counts = columnDays.map { completions.count(eventID: event.objectID, days: $0) }
            let total = counts.reduce(0, +)
            let previous = completions.count(eventID: event.objectID, days: previousDays)
            return EventStatistic(event: event, columnCounts: counts, total: total,
                                  previousTotal: previous, delta: total - previous)
        }.sorted {
            if $0.event.isFavourite != $1.event.isFavourite { return $0.event.isFavourite }
            if $0.total == $1.total { return $0.event.order < $1.event.order }
            return $0.total > $1.total
        }
        rankingBuildCount += 1
        rankingCache = (key, rows)
        return rows
    }

    func statistics(
        for event: Event,
        completions: CompletionSnapshot,
        dayPlannerVM: DayPlannerViewModel
    ) -> EventStatistic {
        let counts = chartDateGroups(dayPlannerVM: dayPlannerVM).map {
            completionCount(event: event, completions: completions, dates: $0)
        }
        let total = counts.reduce(0, +)
        let previous = completionCount(
            event: event,
            completions: completions,
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
        completions: CompletionSnapshot,
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
                    completions: completions,
                    dates: dates
                )
            )
        }
    }

    func completionCount(
        event: Event? = nil,
        completions: CompletionSnapshot,
        dates: [Date]
    ) -> Int {
        completions.count(eventID: event?.objectID, days: dates.map { $0.getYYMMDD() })
    }

    func currentStreak(for event: Event, completions: CompletionSnapshot) -> Int {
        let completedDateKeys = Set(completions.countsByEvent[event.objectID]?.keys.map { $0 } ?? [])
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
        completions: CompletionSnapshot,
        dayPlannerVM: DayPlannerViewModel
    ) -> Int {
        currentDates(dayPlannerVM: dayPlannerVM).filter {
            completionCount(
                event: event,
                completions: completions,
                dates: [$0]
            ) > 0
        }
        .count
    }

    func bestDay(
        for event: Event,
        completions: CompletionSnapshot,
        dayPlannerVM: DayPlannerViewModel
    ) -> String {
        let values = currentDates(dayPlannerVM: dayPlannerVM).map {
            (
                $0,
                completionCount(
                    event: event,
                    completions: completions,
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
        completions: CompletionSnapshot,
        dayPlannerVM: DayPlannerViewModel
    ) -> String {
        let dates = currentDates(dayPlannerVM: dayPlannerVM)
        let total = completionCount(completions: completions, dates: dates)
        guard total > 0 else { return "0%" }
        let eventTotal = completionCount(
            event: event,
            completions: completions,
            dates: dates
        )
        let share = Double(eventTotal) / Double(total) * 100
        return "\(Int(share.rounded()))%"
    }

    func usualTickTime(
        for event: Event,
        completions: CompletionSnapshot,
        dayPlannerVM: DayPlannerViewModel
    ) -> String {
        let days = currentDates(dayPlannerVM: dayPlannerVM).map { $0.getYYMMDD() }
        guard let average = completions.averageTickMinutes(eventID: event.objectID, days: days) else { return "—" }
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
        completions: CompletionSnapshot,
        dayPlannerVM: DayPlannerViewModel
    ) -> String {
        let delta = statistics(
            for: event,
            completions: completions,
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
