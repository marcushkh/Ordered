import SwiftUI
import CoreData

/// The scrollable Statistics content displayed below `StatTopBar`.
struct Stat: View {
    @ObservedObject var appViewModel: ContentViewModel
    @ObservedObject var viewModel: StatViewModel
    @ObservedObject var dayPlannerVM: DayPlannerViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @State private var pinError: String?

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

    var body: some View {
        ScrollViewReader { proxy in
        ScrollView {
            Group {
                if let selectedEvent = viewModel.selectedEvent {
                    eventDetail(for: selectedEvent)
                } else {
                    overview
                }
            }
            .padding(.horizontal, K.horizontal_padding)
            .padding(.top, viewModel.selectedEvent == nil ? 18 : 20)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
        .onChange(of: appViewModel.tutorial.step, initial: true) { _, step in
            if step == .pinEvent || step == .unpinEvent {
                viewModel.selectedEvent = nil
                if let id = appViewModel.tutorial.pinEventID { proxy.scrollTo(id, anchor: .center) }
            }
        }
        .onChange(of: allEvents.map(\.objectID)) { _, _ in
            if appViewModel.tutorial.step == .pinEvent || appViewModel.tutorial.step == .unpinEvent,
               let id = appViewModel.tutorial.pinEventID { proxy.scrollTo(id, anchor: .center) }
        }
        }
        .alert("Couldn't Save Pin", isPresented: Binding(
            get: { pinError != nil },
            set: { if !$0 { pinError = nil } }
        )) {
            Button("OK", role: .cancel) { pinError = nil }
        } message: {
            Text(pinError ?? "Please try again.")
        }
    }

    private var chartColumns: [StatisticColumn] {
        viewModel.chartColumns(
            completedEvents: Array(completedEvents),
            dayPlannerVM: dayPlannerVM
        )
    }

    private var rankedStatistics: [EventStatistic] {
        viewModel.rankedStatistics(
            allEvents: Array(allEvents),
            completedEvents: Array(completedEvents),
            dayPlannerVM: dayPlannerVM
        )
    }

    private var overview: some View {
        VStack(spacing: 18) {
            periodStepper
            periodChart
            rankedEvents
        }
    }

    private var periodStepper: some View {
        HStack {
            Button {
                HapticFeedback.light()
                withAnimation {
                    viewModel.stepPeriod(-1, dayPlannerVM: dayPlannerVM)
                }
            } label: {
                Image(systemName: "play.fill")
                    .rotationEffect(.degrees(180))
                    .font(.system(size: 12))
                    .foregroundStyle(.primary)
                    .frame(width: 32, height: 32)
            }
            Spacer()
            Text(viewModel.periodLabel(dayPlannerVM: dayPlannerVM)).font(.body)
            Spacer()
            Button {
                HapticFeedback.light()
                withAnimation {
                    viewModel.stepPeriod(1, dayPlannerVM: dayPlannerVM)
                }
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(viewModel.canStepForward(dayPlannerVM: dayPlannerVM) ? Color.primary : Color.secondary.opacity(0.4))
                    .frame(width: 32, height: 32)
            }
            .disabled(!viewModel.canStepForward(dayPlannerVM: dayPlannerVM))
        }
        .padding(.horizontal, 6)
        .frame(height: 40)
        .background(.color5, in: RoundedRectangle(cornerRadius: 15))
    }

    private var periodChart: some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("This \(viewModel.range.unit)").font(.headline)
                Spacer()
            }
            barChart(columns: chartColumns, height: 104)
        }
    }

    private var rankedEvents: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Ranked").font(.title3.bold())
                Spacer()
                Text("this \(viewModel.range.unit)")
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
                    HStack(spacing: 4) {
                        Button {
                            HapticFeedback.light()
                            withAnimation { viewModel.selectEvent(statistic.event) }
                        } label: {
                            rankedRow(statistic)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Button {
                            togglePin(statistic.event)
                        } label: {
                            Image(systemName: (statistic.event.isFavourite || (appViewModel.tutorial.step == .unpinEvent && statistic.event.objectID.uriRepresentation().absoluteString == appViewModel.tutorial.pinEventID)) ? "pin.fill" : "pin")
                                .foregroundStyle(statistic.event.isFavourite ? Color.color3 : Color.secondary)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .showCase(.pinEvent, enabled: statistic.event.objectID.uriRepresentation().absoluteString == appViewModel.tutorial.pinEventID)
                        .showCase(.unpinEvent, enabled: statistic.event.objectID.uriRepresentation().absoluteString == appViewModel.tutorial.pinEventID)
                        .accessibilityLabel("\(statistic.event.isFavourite ? "Unpin" : "Pin") \(statistic.event.name ?? "event")")
                        .accessibilityValue(statistic.event.isFavourite ? "Pinned" : "Not pinned")
                    }
                    .id(statistic.event.objectID.uriRepresentation().absoluteString)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                    }
                }
            }
        }
    }

    private func rankedRow(_ statistic: EventStatistic) -> some View {
        let todayIndex = viewModel.range == .week
            ? viewModel.currentDates(dayPlannerVM: dayPlannerVM).firstIndex {
                Calendar.current.isDate($0, inSameDayAs: MyCalendar.getToday())
            }
            : nil

        return HStack(spacing: 10) {
            eventBubble(statistic.event, size: 36)
            Text(statistic.event.name ?? "Event")
                .font(.body)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 3) {
                ForEach(Array(statistic.columnCounts.enumerated()), id: \.offset) { index, count in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(finishMarkColor(for: count))
                        .frame(width: viewModel.range == .week ? 11 : 7, height: 18)
                        .overlay {
                            if index == todayIndex {
                                RoundedRectangle(cornerRadius: 2)
                                    .strokeBorder(Color(hex: "FF6B6B"), lineWidth: 1.5)
                            }
                        }
                }
            }
            Text("\(statistic.total)")
                .font(.body.bold())
                .frame(width: 28, alignment: .trailing)
        }
        .padding(.vertical, 12)
    }

    private func togglePin(_ event: Event) {
        let wasPinned = event.isFavourite
        do {
            try withAnimation {
                event.isFavourite.toggle()
                try viewContext.save()
            }
            HapticFeedback.light()
        } catch {
            event.isFavourite = wasPinned
            pinError = error.localizedDescription
        }
    }

    private func finishMarkColor(for count: Int) -> Color {
        switch count {
        case ...0: return Color.color2.opacity(0.55)
        case 1: return .color4
        case 2: return Color(hex: "56678C")
        default: return .color3
        }
    }

    private func eventDetail(for event: Event) -> some View {
        let statistic = viewModel.statistics(for: event, completedEvents: Array(completedEvents), dayPlannerVM: dayPlannerVM)

        return VStack(spacing: 20) {
            HStack(spacing: 10) {
                detailMiniCard(
                    title: "This \(viewModel.range.unit)",
                    value: "\(statistic.total)"
                )
                detailMiniCard(
                    title: "Streak",
                    value: "\(viewModel.currentStreak(for: event, completedEvents: Array(completedEvents)))",
                    valueColor: .color3
                )
            }

            VStack(spacing: 12) {
                HStack {
                    Text("Day by Day").font(.headline)
                    Spacer()
                    Text("\(viewModel.activeDayCount(for: event, completedEvents: Array(completedEvents), dayPlannerVM: dayPlannerVM)) of \(viewModel.currentDates(dayPlannerVM: dayPlannerVM).count) days")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                barChart(columns: viewModel.eventColumns(for: event, completedEvents: Array(completedEvents), dayPlannerVM: dayPlannerVM), height: 100)
            }

            VStack(spacing: 12) {
                detailValueRow("Last \(viewModel.range.unit)", "\(statistic.previousTotal) times")
                detailValueRow("Best day", viewModel.bestDay(for: event, completedEvents: Array(completedEvents), dayPlannerVM: dayPlannerVM))
                detailValueRow("Share of your \(viewModel.range.unit)", viewModel.shareLabel(for: event, completedEvents: Array(completedEvents), dayPlannerVM: dayPlannerVM))
                detailValueRow("Usual tick time", viewModel.usualTickTime(for: event, completedEvents: Array(completedEvents), dayPlannerVM: dayPlannerVM))
            }
            .padding(16)
            .background(.color5, in: RoundedRectangle(cornerRadius: 24))
        }
    }

    private func detailMiniCard(title: String, value: String, valueColor: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value)
                .font(.title.bold())
                .foregroundStyle(valueColor)
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
        return HStack(alignment: .bottom, spacing: viewModel.range == .week ? 6 : 8) {
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

    private func eventBubble(_ event: Event, size: CGFloat) -> some View {
        Circle()
            .fill(viewModel.eventColor(event))
            .frame(width: size, height: size)
            .overlay { Text(event.icon ?? "💡").font(.system(size: size * 0.72)) }
    }

}
