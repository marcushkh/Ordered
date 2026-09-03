//
//  QuickFinishView.swift
//  Ordered
//

import SwiftUI

struct QuickFinishView: View {
    @ObservedObject var viewModel: ContentViewModel
    @ObservedObject var dayPlannerVM: DayPlannerViewModel

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\Category.order, order: .forward)],
        predicate: NSPredicate(format: "isActive == true"),
        animation: .default
    ) private var categories: FetchedResults<Category>

    @FetchRequest(
        sortDescriptors: [
            SortDescriptor(\Event.isFavourite, order: .reverse),
            SortDescriptor(\Event.order, order: .forward)
        ],
        predicate: NSPredicate(format: "isActive == true"),
        animation: .default
    ) private var events: FetchedResults<Event>

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 14),
        count: 3
    )

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.showQuickFinishSearch {
                    TextField("Search events", text: $viewModel.quickFinishSearchText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, K.horizontal_padding)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                ForEach(eventGroups) { group in
                    eventGroup(group)
                }

                if eventGroups.isEmpty {
                    ContentUnavailableView(
                        viewModel.quickFinishSearchText.isEmpty ? "No Events" : "No Results",
                        systemImage: "checkmark.circle",
                        description: Text(
                            viewModel.quickFinishSearchText.isEmpty
                                ? "Add events from Library in Settings to use Quick Finish."
                                : "Try a different event name."
                        )
                    )
                    .padding(.top, 50)
                }
            }
            .padding(.top, K.xxxsmall_size)
            .padding(.bottom, 90)
        }
        .scrollIndicators(.hidden)
        .onChange(of: viewModel.refresh) { _, _ in }
    }

    private var filteredEvents: [Event] {
        guard !viewModel.quickFinishSearchText.isEmpty else {
            return Array(events)
        }

        return events.filter {
            ($0.name ?? "").localizedCaseInsensitiveContains(viewModel.quickFinishSearchText)
        }
    }

    private var eventGroups: [QuickFinishEventGroup] {
        var groups = categories.compactMap { category -> QuickFinishEventGroup? in
            let categoryEvents = filteredEvents.filter { $0.category == category }
            guard !categoryEvents.isEmpty else { return nil }

            return QuickFinishEventGroup(
                id: category.objectID.uriRepresentation().absoluteString,
                name: category.name ?? "Category",
                color: Color(hex: category.color),
                events: categoryEvents
            )
        }

        let uncategorizedEvents = filteredEvents.filter { $0.activeCategories.isEmpty }
        if !uncategorizedEvents.isEmpty {
            groups.append(
                QuickFinishEventGroup(
                    id: "uncategorized",
                    name: "Uncategorized",
                    color: .color1,
                    events: uncategorizedEvents
                )
            )
        }

        return groups
    }

    private var finishedEventCount: Int {
        filteredEvents.filter { finishedCount(for: $0) > 0 }.count
    }

    private func eventGroup(_ group: QuickFinishEventGroup) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Text(group.name)
                    .font(.title3)
                    .bold()

                Capsule()
                    .fill(.color3)
                    .frame(height: 2)
            }

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(group.events) { event in
                    eventTile(event, color: group.color)
                }
            }
        }
        .padding(.horizontal, K.horizontal_padding)
    }

    private func eventTile(_ event: Event, color: Color) -> some View {
        let count = finishedCount(for: event)

        return Button {
            quickFinish(event)
        } label: {
            VStack(spacing: 10) {
                Text(event.name ?? "Event")
                    .font(.subheadline)
                    .foregroundStyle(.cPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Text(event.icon ?? "")
                    .font(.title)
                    .frame(width: 56, height: 56)
                    .background(count > 0 ? Color.success : color, in: Circle())

                Text(finishedLabel(count))
                    .font(.caption)
                    .bold(count > 0)
                    .foregroundStyle(count > 0 ? Color.cPrimary : Color.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 142)
            .background(
                count > 0 ? color : Color.color5,
                in: RoundedRectangle(cornerRadius: 20)
            )
        }
        .buttonStyle(.plain)
    }

    private func finishedCount(for event: Event) -> Int {
        event.finished(on: dayPlannerVM.currentDate)
    }

    private func finishedLabel(_ count: Int) -> String {
        guard count > 0 else { return "Finish" }
        return "\(count) \(count == 1 ? "time" : "times") today"
    }

    private func quickFinish(_ event: Event) {
        let cal = Cal.getOrCreateWithDefault(date: dayPlannerVM.currentDate)
        let lastFinishedEvent = cal.getLastFinishedEvent()
        let newEvent = event.getEC()

        if let lastFinishedEvent,
           let section = lastFinishedEvent.section_cal {
            section.insert(newEvent, after: lastFinishedEvent)
        }
        else if let section = cal.section_cals?.firstObject as? Section_Cal {
            section.add(event: newEvent)
        }
        else {
            let section = Section_Cal.new()
            section.add(event: newEvent)
            cal.addSection(section)
        }

        EventActionHandler.shared.tick(ec: newEvent)
        viewModel.refresh.toggle()
    }
}

private struct QuickFinishEventGroup: Identifiable {
    let id: String
    let name: String
    let color: Color
    let events: [Event]
}

