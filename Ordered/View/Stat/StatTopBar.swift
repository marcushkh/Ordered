import SwiftUI
import CoreData

/// The complete Statistics experience, based on the final 2a direction in
/// Ordered Statistic Redesign.html and backed by stored tick completions.
struct StatTopBar: View {
    @ObservedObject var viewModel: ContentViewModel
    @ObservedObject var dayPlannerVM: DayPlannerViewModel

    @FetchRequest(
        entity: Event.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Event.isFavourite, ascending: false),
            NSSortDescriptor(keyPath: \Event.order, ascending: true)
        ],
        predicate: NSPredicate(format: "isActive == true")
    ) private var allEvents: FetchedResults<Event>

    @FetchRequest(
        entity: Event_Cal.entity(),
        sortDescriptors: [],
        predicate: NSPredicate(format: "aEndTime != nil")
    ) private var completedEvents: FetchedResults<Event_Cal>

    @State private var range: StatisticRange = .week
    @State private var currentDate = MyCalendar.getToday()
    @State private var selectedEvent: Event?

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 0) {
            if let selectedEvent {
                detailHeader(for: selectedEvent)
                    .transition(.move(edge: .top).combined(with: .opacity))
                ScrollView {
                    eventDetail(for: selectedEvent)
                        .padding(.horizontal, K.horizontal_padding)
                        .padding(.top, 20)
                        .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
            } else {
                overviewHeader
                    .transition(.move(edge: .top).combined(with: .opacity))
                ScrollView {
                    overview
                        .padding(.horizontal, K.horizontal_padding)
                        .padding(.top, 18)
                        .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
            }
        }
        .background(Color.cBackground)
    }

    private var overviewHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Statistic")
                    .font(.title2.bold())
                Spacer()
                Button {
                    HapticFeedback.light()
                    withAnimation { currentDate = MyCalendar.getToday() }
                } label: {
                    Image(systemName: "calendar")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.color3)
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel("Return to current period")
            }

            Picker("Range", selection: $range) {
                ForEach(StatisticRange.allCases) { value in
                    Text(value.title).tag(value)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: range) { _, _ in
                HapticFeedback.light()
                withAnimation { currentDate = MyCalendar.getToday() }
            }
        }
        .padding(.horizontal, K.horizontal_padding)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(.color1)
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 30, bottomTrailingRadius: 30))
        .background(Color.color1.ignoresSafeArea(edges: .top))
    }

    private func detailHeader(for event: Event) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button {
                    HapticFeedback.light()
                    withAnimation { selectedEvent = nil }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.color3)
                        .frame(width: 32, height: 32, alignment: .leading)
                }
                Spacer()
                Text(periodLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                eventBubble(event, size: 36)
                Text(event.name ?? "Event")
                    .font(.title.bold())
                    .lineLimit(1)
            }

            Text(eventHeadline(for: event))
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, K.horizontal_padding)
        .padding(.top, 12)
        .padding(.bottom, 18)
        .background(.color1)
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 30, bottomTrailingRadius: 30))
        .background(Color.color1.ignoresSafeArea(edges: .top))
    }

    private var overview: some View {
        VStack(spacing: 18) {
            keptAliveCard
            periodStepper
            periodChart
            rankedEvents
        }
    }

    private var keptAliveCard: some View {
        HStack(spacing: 12) {
            Text("Kept alive on").font(.subheadline)
            Spacer(minLength: 4)
            HStack(spacing: 6) {
                ForEach(chartColumns) { column in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(column.count > 0 ? Color.color3 : Color.color2)
                            .frame(width: 12, height: 12)
                        Text(column.shortLabel)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.color1, in: RoundedRectangle(cornerRadius: 20))
    }

    private var periodStepper: some View {
        HStack {
            Button { stepPeriod(-1) } label: {
                Image(systemName: "play.fill")
                    .rotationEffect(.degrees(180))
                    .font(.system(size: 12))
                    .foregroundStyle(.primary)
                    .frame(width: 32, height: 32)
            }
            Spacer()
            Text(periodLabel).font(.body)
            Spacer()
            Button { stepPeriod(1) } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(canStepForward ? Color.primary : Color.secondary.opacity(0.4))
                    .frame(width: 32, height: 32)
            }
            .disabled(!canStepForward)
        }
        .padding(.horizontal, 6)
        .frame(height: 40)
        .background(.color5, in: RoundedRectangle(cornerRadius: 15))
    }

    private var periodChart: some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("This \(range.unit)").font(.headline)
                Spacer()
                Text("\(signed(percentChange))% vs last \(range.unit)")
                    .font(.footnote.bold())
                    .foregroundStyle(.color3)
            }
            barChart(columns: chartColumns, height: 104)
        }
    }

    private var rankedEvents: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Ranked").font(.title3.bold())
                Spacer()
                Text("this \(range.unit) · change")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 8)

            Rectangle().fill(.color3).frame(height: 2)

            if rankedStatistics.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar").font(.title).foregroundStyle(.color3)
                    Text("Tick an event to begin your statistics.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ForEach(rankedStatistics) { statistic in
                    Button {
                        HapticFeedback.light()
                        withAnimation { selectedEvent = statistic.event }
                    } label: {
                        rankedRow(statistic)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func rankedRow(_ statistic: EventStatistic) -> some View {
        HStack(spacing: 10) {
            eventBubble(statistic.event, size: 36)
            Text(statistic.event.name ?? "Event")
                .font(.body)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 3) {
                ForEach(Array(statistic.columnCounts.enumerated()), id: \.offset) { _, count in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(count > 0 ? Color.color4 : Color.color2.opacity(0.55))
                        .frame(width: 7, height: 18)
                }
            }
            Text("\(statistic.total)")
                .font(.body.bold())
                .frame(width: 28, alignment: .trailing)
            deltaChip(statistic.delta).frame(width: 40)
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
        }
    }

    private func eventDetail(for event: Event) -> some View {
        let statistic = statistics(for: event)

        return VStack(spacing: 20) {
            HStack(spacing: 10) {
                detailMiniCard(
                    title: "This \(range.unit)",
                    value: "\(statistic.total)",
                    delta: statistic.delta
                )
                detailMiniCard(
                    title: "Streak",
                    value: "\(currentStreak(for: event))",
                    delta: nil
                )
            }

            VStack(spacing: 12) {
                HStack {
                    Text("Day by Day").font(.headline)
                    Spacer()
                    Text("\(activeDayCount(for: event)) of \(currentDates.count) days")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                barChart(columns: eventColumns(for: event), height: 100)
            }

            VStack(spacing: 12) {
                detailValueRow("Last \(range.unit)", "\(statistic.previousTotal) times")
                detailValueRow("Best day", bestDay(for: event))
                detailValueRow("Share of your \(range.unit)", shareLabel(for: event))
                detailValueRow("Usual tick time", usualTickTime(for: event))
            }
            .padding(16)
            .background(.color5, in: RoundedRectangle(cornerRadius: 24))
        }
    }

    private func detailMiniCard(title: String, value: String, delta: Int?) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            HStack(alignment: .bottom, spacing: 6) {
                Text(value)
                    .font(.title.bold())
                    .foregroundStyle(delta == nil ? Color.color3 : Color.primary)
                if let delta { deltaChip(delta) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.color5, in: RoundedRectangle(cornerRadius: 24))
    }

    private func detailValueRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.subheadline.bold())
        }
    }

    private func barChart(columns: [StatisticColumn], height: CGFloat) -> some View {
        let maximum = max(1, columns.map(\.count).max() ?? 0)
        return HStack(alignment: .bottom, spacing: 8) {
            ForEach(columns) { column in
                VStack(spacing: 6) {
                    Text("\(column.count)").font(.system(size: 10)).foregroundStyle(.secondary)
                    ZStack(alignment: .bottom) {
                        Color.clear.frame(height: height)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.color4)
                            .frame(height: column.count == 0 ? 0 : max(3, CGFloat(column.count) / CGFloat(maximum) * height))
                    }
                    Text(column.label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func deltaChip(_ delta: Int) -> some View {
        Text(signed(delta))
            .font(.caption2.bold())
            .foregroundStyle(.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(deltaColor(delta), in: Capsule())
    }

    private func eventBubble(_ event: Event, size: CGFloat) -> some View {
        Circle()
            .fill(eventColor(event))
            .frame(width: size, height: size)
            .overlay { Text(event.icon ?? "💡").font(.system(size: size * 0.72)) }
    }

    private var currentDates: [Date] { dates(for: currentDate, range: range) }

    private var previousDates: [Date] {
        let anchor = calendar.date(byAdding: range.calendarComponent, value: -1, to: currentDate) ?? currentDate
        return dates(for: anchor, range: range)
    }

    private var chartDateGroups: [[Date]] {
        if range == .week { return currentDates.map { [$0] } }
        return stride(from: 0, to: currentDates.count, by: 7).map {
            Array(currentDates[$0..<min($0 + 7, currentDates.count)])
        }
    }

    private var chartColumns: [StatisticColumn] {
        chartDateGroups.enumerated().map { index, dates in
            StatisticColumn(
                id: index,
                label: range == .week ? (dates.first?.weekDayAbbrev() ?? "") : "W\(index + 1)",
                shortLabel: range == .week ? String((dates.first?.weekDayAbbrev() ?? " ").prefix(1)) : "W\(index + 1)",
                count: completionCount(dates: dates)
            )
        }
    }

    private var totalCurrent: Int { completionCount(dates: currentDates) }
    private var totalPrevious: Int { completionCount(dates: previousDates) }

    private var percentChange: Int {
        guard totalPrevious > 0 else { return totalCurrent == 0 ? 0 : 100 }
        return Int((Double(totalCurrent - totalPrevious) / Double(totalPrevious) * 100).rounded())
    }

    private var rankedStatistics: [EventStatistic] {
        allEvents.map(statistics(for:)).sorted {
            if $0.total == $1.total { return $0.event.order < $1.event.order }
            return $0.total > $1.total
        }
    }

    private func statistics(for event: Event) -> EventStatistic {
        let counts = chartDateGroups.map { completionCount(event: event, dates: $0) }
        let total = counts.reduce(0, +)
        let previous = completionCount(event: event, dates: previousDates)
        return EventStatistic(event: event, columnCounts: counts, total: total, previousTotal: previous, delta: total - previous)
    }

    private func eventColumns(for event: Event) -> [StatisticColumn] {
        chartDateGroups.enumerated().map { index, dates in
            StatisticColumn(
                id: index,
                label: range == .week ? String((dates.first?.weekDayAbbrev() ?? " ").prefix(1)) : "W\(index + 1)",
                shortLabel: "",
                count: completionCount(event: event, dates: dates)
            )
        }
    }

    private func completionCount(event: Event? = nil, dates: [Date]) -> Int {
        let dateKeys = Set(dates.map { $0.getYYMMDD() })
        return completedEvents.reduce(into: 0) { result, completion in
            guard let key = completion.section_cal?.cal?.date, dateKeys.contains(key) else { return }
            guard event == nil || completion.parent == event else { return }
            result += 1
        }
    }

    private func currentStreak(for event: Event? = nil) -> Int {
        let completedDateKeys = Set(completedEvents.compactMap { completion -> String? in
            guard event == nil || completion.parent == event else { return nil }
            return completion.section_cal?.cal?.date
        })
        var cursor = MyCalendar.getToday()
        if !completedDateKeys.contains(cursor.getYYMMDD()) {
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        var streak = 0
        while completedDateKeys.contains(cursor.getYYMMDD()) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    private func activeDayCount(for event: Event) -> Int {
        currentDates.filter { completionCount(event: event, dates: [$0]) > 0 }.count
    }

    private func bestDay(for event: Event) -> String {
        let values = currentDates.map { ($0, completionCount(event: event, dates: [$0])) }
        guard let best = values.max(by: { $0.1 < $1.1 }), best.1 > 0 else { return "—" }
        return range == .week
            ? best.0.formatted(.dateTime.weekday(.wide))
            : best.0.formatted(.dateTime.month(.abbreviated).day())
    }

    private func shareLabel(for event: Event) -> String {
        guard totalCurrent > 0 else { return "0%" }
        let share = Double(completionCount(event: event, dates: currentDates)) / Double(totalCurrent) * 100
        return "\(Int(share.rounded()))%"
    }

    private func usualTickTime(for event: Event) -> String {
        let dateKeys = Set(currentDates.map { $0.getYYMMDD() })
        let minutes = completedEvents.compactMap { completion -> Int? in
            guard completion.parent == event,
                  let key = completion.section_cal?.cal?.date,
                  dateKeys.contains(key),
                  let time = completion.aEndTime ?? completion.aStartTime else { return nil }
            let parts = time.split(separator: ":").compactMap { Int($0) }
            guard parts.count >= 2 else { return nil }
            return parts[0] * 60 + parts[1]
        }
        guard !minutes.isEmpty else { return "—" }
        let average = minutes.reduce(0, +) / minutes.count
        return String(format: "%02d:%02d", average / 60, average % 60)
    }

    private func dates(for anchor: Date, range: StatisticRange) -> [Date] {
        switch range {
        case .week:
            let start = dayPlannerVM.startDateOfWeek(from: anchor)
            return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
        case .month:
            guard let interval = calendar.dateInterval(of: .month, for: anchor),
                  let dayRange = calendar.range(of: .day, in: .month, for: anchor) else { return [] }
            return dayRange.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: interval.start) }
        }
    }

    private var periodLabel: String {
        guard let first = currentDates.first, let last = currentDates.last else { return "" }
        if range == .month { return first.formatted(.dateTime.month(.wide).year()) }
        return "\(first.formatted(.dateTime.month(.abbreviated).day())) – \(last.formatted(.dateTime.month(.abbreviated).day()))"
    }

    private var canStepForward: Bool {
        guard let currentStart = currentDates.first,
              let todayStart = dates(for: MyCalendar.getToday(), range: range).first else { return false }
        return currentStart < todayStart
    }

    private func stepPeriod(_ direction: Int) {
        guard direction < 0 || canStepForward else { return }
        HapticFeedback.light()
        withAnimation {
            currentDate = calendar.date(byAdding: range.calendarComponent, value: direction, to: currentDate) ?? currentDate
        }
    }

    private func eventHeadline(for event: Event) -> String {
        let delta = statistics(for: event).delta
        if delta > 0 { return "Up \(delta) on last \(range.unit)!!" }
        if delta < 0 { return "Down \(abs(delta)) on last \(range.unit)" }
        return "Steady as last \(range.unit)"
    }

    private func eventColor(_ event: Event) -> Color {
        if let categoryColor = event.activeCategories.first?.color { return Color(hex: categoryColor) }
        let palette = K.defaultSectionColor
        return Color(hex: palette[Int(event.order) % palette.count])
    }

    private func deltaColor(_ delta: Int) -> Color {
        if delta > 0 { return Color(hex: "BBF3BB") }
        if delta < 0 { return Color(hex: "F8CACF") }
        return .color1
    }

    private func signed(_ value: Int) -> String {
        value >= 0 ? "+\(value)" : "−\(abs(value))"
    }
}

private enum StatisticRange: String, CaseIterable, Identifiable {
    case week
    case month

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var unit: String { rawValue }
    var calendarComponent: Calendar.Component { self == .week ? .weekOfYear : .month }
}

private struct StatisticColumn: Identifiable {
    let id: Int
    let label: String
    let shortLabel: String
    let count: Int
}

private struct EventStatistic: Identifiable {
    let event: Event
    let columnCounts: [Int]
    let total: Int
    let previousTotal: Int
    let delta: Int

    var id: NSManagedObjectID { event.objectID }
}
