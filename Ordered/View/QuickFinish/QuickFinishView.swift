//
//  QuickFinishView.swift
//  Ordered
//

import SwiftUI
import CoreData

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
        .sheet(isPresented: $viewModel.showQuickFinishEditor) {
            QuickFinishEditor(
                categories: Array(categories),
                events: Array(events),
                viewModel: viewModel
            )
        }
        .onChange(of: viewModel.refresh) { _, _ in }
    }

    private var filteredEvents: [Event] {
        let visibleEvents = quickFinishSorted(Array(events), order: { $0.quickFinishOrder })
            .filter { !$0.quickFinishHidden }
        guard !viewModel.quickFinishSearchText.isEmpty else {
            return visibleEvents
        }

        return visibleEvents.filter {
            ($0.name ?? "").localizedCaseInsensitiveContains(viewModel.quickFinishSearchText)
        }
    }

    private var eventGroups: [QuickFinishEventGroup] {
        var groups = quickFinishSorted(Array(categories), order: { $0.quickFinishOrder }).compactMap { category -> QuickFinishEventGroup? in
            let categoryEvents = quickFinishSorted(
                (category.events?.array as? [Event] ?? []).filter { filteredEvents.contains($0) },
                order: { $0.quickFinishOrder }
            )
            guard !categoryEvents.isEmpty else { return nil }

            return QuickFinishEventGroup(
                id: category.objectID.uriRepresentation().absoluteString,
                icon: category.icon ?? "🏷️",
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
                    icon: "🏷️",
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
                Text(group.icon)
                    .font(.title3)

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

        if let destination = event.quickFinishSection, destination.isActive {
            let sections = cal.section_cals?.array as? [Section_Cal] ?? []
            // Prefer the latest occurrence if this section appears more than once.
            let section = sections.last(where: { $0.parent == destination }) ?? {
                let section = Section_Cal.new()
                section.parent = destination
                cal.addSection(section)
                return section
            }()
            section.add(event: newEvent)
        }
        else if let lastFinishedEvent,
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
    let icon: String
    let name: String
    let color: Color
    let events: [Event]
}

// Unconfigured entries keep their Library order, after explicitly ordered entries.
private func quickFinishSorted<T>(_ items: [T], order: (T) -> Int64) -> [T] {
    items.enumerated().sorted { lhs, rhs in
        let left = order(lhs.element) < 0 ? Int64.max : order(lhs.element)
        let right = order(rhs.element) < 0 ? Int64.max : order(rhs.element)
        return left == right ? lhs.offset < rhs.offset : left < right
    }.map(\.element)
}

private struct QuickFinishItemDraft: Identifiable {
    let id: NSManagedObjectID
    let name: String
    let icon: String
    var isVisible: Bool
    var sectionID: NSManagedObjectID?
}

private struct QuickFinishGroupDraft: Identifiable {
    let id: String
    let categoryID: NSManagedObjectID?
    let name: String
    let icon: String
    var items: [QuickFinishItemDraft]
}

private struct QuickFinishEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var viewModel: ContentViewModel
    @State private var groups: [QuickFinishGroupDraft]
    @State private var saveError: String?

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\Section.order, order: .forward)],
        predicate: NSPredicate(format: "isActive == true")
    ) private var sections: FetchedResults<Section>

    init(categories: [Category], events: [Event], viewModel: ContentViewModel) {
        self.viewModel = viewModel
        let orderedEvents = quickFinishSorted(events, order: { $0.quickFinishOrder })
        func items(_ events: [Event]) -> [QuickFinishItemDraft] {
            events.map {
                QuickFinishItemDraft(
                    id: $0.objectID,
                    name: $0.name ?? "Event",
                    icon: $0.icon ?? "",
                    isVisible: !$0.quickFinishHidden,
                    sectionID: $0.quickFinishSection?.isActive == true ? $0.quickFinishSection?.objectID : nil
                )
            }
        }
        var drafts = quickFinishSorted(categories, order: { $0.quickFinishOrder }).map { category in
            QuickFinishGroupDraft(
                id: category.objectID.uriRepresentation().absoluteString,
                categoryID: category.objectID,
                name: category.name ?? "Category",
                icon: category.icon ?? "🏷️",
                items: items(quickFinishSorted(
                    (category.events?.array as? [Event] ?? []).filter(\.isActive),
                    order: { $0.quickFinishOrder }
                ))
            )
        }
        let uncategorized = orderedEvents.filter { $0.activeCategories.isEmpty }
        if !uncategorized.isEmpty {
            drafts.append(QuickFinishGroupDraft(
                id: "uncategorized", categoryID: nil, name: "Uncategorized", icon: "🏷️",
                items: items(uncategorized)
            ))
        }
        _groups = State(initialValue: drafts)
    }

    var body: some View {
        NavigationStack {
            List {
                SwiftUI.Section {
                    Text("Drag to reorder categories and events. Tap an event to choose its Plan section or hide it from Quick Finish.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                SwiftUI.Section("Category Order") {
                    ForEach(groups.filter { $0.categoryID != nil }) { group in
                        Text("\(group.icon) \(group.name)")
                    }
                    .onMove { source, destination in
                        // Uncategorized always stays below named categories.
                        var categories = groups.filter { $0.categoryID != nil }
                        categories.move(fromOffsets: source, toOffset: destination)
                        groups = categories + groups.filter { $0.categoryID == nil }
                    }
                }

                ForEach($groups) { $group in
                    SwiftUI.Section("\(group.icon) \(group.name)") {
                        ForEach($group.items) { $item in
                            NavigationLink {
                                itemEditor($item)
                            } label: {
                                HStack {
                                    Text(item.icon)
                                    Text(item.name)
                                }
                            }
                        }
                        .onMove { source, destination in
                            group.items.move(fromOffsets: source, toOffset: destination)
                        }
                    }
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Edit Quick Finish")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                }
            }
            .alert("Couldn't Save Quick Finish", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "Please try again.")
            }
        }
        .interactiveDismissDisabled()
    }

    private func itemEditor(_ item: Binding<QuickFinishItemDraft>) -> some View {
        Form {
            SwiftUI.Section {
                Toggle("Show in Quick Finish", isOn: item.isVisible)
            }
            SwiftUI.Section {
                Picker("Plan Section", selection: item.sectionID) {
                    Text("Automatic").tag(nil as NSManagedObjectID?)
                    ForEach(sections) { section in
                        Text("\(section.icon ?? "📁") \(section.name ?? "Section")")
                            .tag(Optional(section.objectID))
                    }
                }
            } footer: {
                Text("Automatic places the event after the last finished event. A selected section receives the event and is added to the day if needed.")
            }
        }
        .environment(\.editMode, .constant(.inactive))
        .navigationTitle(item.wrappedValue.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func save() {
        // A separate context keeps Cancel and failed saves from changing live data.
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = viewContext.persistentStoreCoordinator
        do {
            for (groupIndex, group) in groups.enumerated() {
                if let id = group.categoryID {
                    let category = try context.existingObject(with: id) as! Category
                    category.quickFinishOrder = Int64(groupIndex)
                }
                for (itemIndex, item) in group.items.enumerated() {
                    let event = try context.existingObject(with: item.id) as! Event
                    event.quickFinishOrder = Int64(itemIndex)
                    event.quickFinishHidden = !item.isVisible
                    if let id = item.sectionID {
                        let section = try context.existingObject(with: id) as! Section
                        event.quickFinishSection = section.isActive ? section : nil
                    } else {
                        event.quickFinishSection = nil
                    }
                }
            }
            try context.save()
            viewModel.refresh.toggle()
            dismiss()
        } catch {
            context.rollback()
            saveError = error.localizedDescription
        }
    }
}
