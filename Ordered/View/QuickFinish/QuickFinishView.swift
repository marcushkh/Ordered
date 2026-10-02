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
            SortDescriptor(\Event.order, order: .forward)
        ],
        predicate: NSPredicate(format: "isActive == true"),
        animation: .default
    ) private var events: FetchedResults<Event>

    @State private var finishError: String?
    @State private var scrollDragAnchor: CGFloat = 0

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
        .simultaneousGesture(
            DragGesture(minimumDistance: 3, coordinateSpace: .global)
                .onChanged { value in
                    guard abs(value.translation.height) > abs(value.translation.width) else { return }
                    let movement = value.translation.height - scrollDragAnchor
                    scrollDragAnchor = value.translation.height
                    // Track the finger directly. Global coordinates avoid feedback as the header resizes.
                    var transaction = Transaction(animation: nil)
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        viewModel.resizePlanBar(by: movement)
                    }
                }
                .onEnded { _ in scrollDragAnchor = 0 }
        )
        .onAppear { viewModel.planBarExpansion = 1 }
        .sheet(isPresented: $viewModel.showQuickFinishEditor) {
            QuickFinishEditor(
                categories: Array(categories),
                events: Array(events),
                viewModel: viewModel
            )
        }
        .alert("Couldn't Save Changes", isPresented: Binding(
            get: { finishError != nil },
            set: { if !$0 { finishError = nil } }
        )) {
            Button("OK", role: .cancel) { finishError = nil }
        } message: {
            Text(finishError ?? "Please try again.")
        }
        .onChange(of: viewModel.refresh) { _, _ in }
    }

    private var filteredEvents: [Event] {
        let visibleEvents = Array(events)
            .filter { !$0.quickFinishHidden }
        guard !viewModel.quickFinishSearchText.isEmpty else {
            return visibleEvents
        }

        return visibleEvents.filter {
            ($0.name ?? "").localizedCaseInsensitiveContains(viewModel.quickFinishSearchText)
        }
    }

    private var eventGroups: [QuickFinishEventGroup] {
        var groups = categories.compactMap { category -> QuickFinishEventGroup? in
            let categoryEvents = category.orderedActiveEvents.filter { filteredEvents.contains($0) }
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

        return QuickFinishCard(event: event, color: color, finishedCount: count)
            .contentShape(RoundedRectangle(cornerRadius: 20))
            .gesture(
                LongPressGesture(minimumDuration: 0.45)
                    .exclusively(before: TapGesture())
                    .onEnded { gesture in
                        switch gesture {
                        case .first(true):
                            addToPlan(event)
                        case .second:
                            quickFinish(event)
                        default:
                            break
                        }
                    }
            )
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Tap to finish. Hold to add to your plan.")
            .accessibilityAction { quickFinish(event) }
            .accessibilityAction(named: "Add to plan") { addToPlan(event) }
    }

    private func addToPlan(_ event: Event) {
        HapticFeedback.light()
        do {
            try withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                try viewModel.plan(event)
            }
        } catch {
            finishError = error.localizedDescription
        }
    }

    private func finishedCount(for event: Event) -> Int {
        event.finished(on: dayPlannerVM.currentDate)
    }

    private func quickFinish(_ event: Event) {
        do {
            try EventActionHandler.shared.quickFinish(event, on: dayPlannerVM.currentDate)
        } catch {
            finishError = error.localizedDescription
        }
        viewModel.refresh.toggle()
    }
}

/// Shared appearance for the full event tile and its shorter planned copy.
struct QuickFinishCard: View {
    @ObservedObject var event: Event
    let color: Color
    var finishedCount: Int? = nil
    var planExpansion: CGFloat = 1

    var body: some View {
        let isFinished = (finishedCount ?? 0) > 0
        let expansion = min(1, max(0, planExpansion))
        VStack(spacing: 10 * expansion) {
            Text(event.name ?? "Event")
                .font(.subheadline)
                .foregroundStyle(.cPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .frame(height: finishedCount == nil ? 36 * expansion : nil)
                .opacity(expansion)
                .clipped()
                .accessibilityHidden(expansion < 0.01)

            Text(event.icon ?? "")
                .font(.system(size: 22 + 6 * expansion))
                .frame(width: 44 + 12 * expansion, height: 44 + 12 * expansion)
                .background(isFinished ? Color.success : color, in: Circle())

            if let count = finishedCount {
                Text(count > 0 ? "\(count) \(count == 1 ? "time" : "times") today" : "Finish")
                    .font(.caption)
                    .bold(isFinished)
                    .foregroundStyle(isFinished ? Color.cPrimary : Color.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 6 * expansion)
        .padding(.vertical, 12 * expansion)
        .frame(maxWidth: .infinity, minHeight: 44 + ((finishedCount == nil ? 118 : 142) - 44) * expansion)
        .background((isFinished ? color : Color.color5).opacity(expansion), in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct QuickFinishEventGroup: Identifiable {
    let id: String
    let icon: String
    let name: String
    let color: Color
    let events: [Event]
}

private struct QuickFinishItemDraft: Identifiable {
    let id: NSManagedObjectID
    let name: String
    let icon: String
    var isVisible: Bool
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

    init(categories: [Category], events: [Event], viewModel: ContentViewModel) {
        self.viewModel = viewModel
        func items(_ events: [Event]) -> [QuickFinishItemDraft] {
            events.map {
                QuickFinishItemDraft(
                    id: $0.objectID,
                    name: $0.name ?? "Event",
                    icon: $0.icon ?? "",
                    isVisible: !$0.quickFinishHidden
                )
            }
        }
        var drafts = categories.map { category in
            QuickFinishGroupDraft(
                id: category.objectID.uriRepresentation().absoluteString,
                categoryID: category.objectID,
                name: category.name ?? "Category",
                icon: category.icon ?? "🏷️",
                items: items(category.orderedActiveEvents)
            )
        }
        let uncategorized = events.filter { $0.activeCategories.isEmpty }
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
                    Text("Drag to reorder categories and events in both Finish Now and Library. Tap an event to show or hide it in Quick Finish.")
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
                let orderedEvents = try group.items.map { item -> Event in
                    let event = try context.existingObject(with: item.id) as! Event
                    event.quickFinishHidden = !item.isVisible
                    return event
                }
                if let id = group.categoryID {
                    let category = try context.existingObject(with: id) as! Category
                    category.order = Int16(clamping: groupIndex)
                    // Keep inactive members while updating the order shared with Library.
                    let inactiveEvents = (category.events?.array as? [Event] ?? []).filter { !$0.isActive }
                    category.events = NSOrderedSet(array: orderedEvents + inactiveEvents)
                } else {
                    for (index, event) in orderedEvents.enumerated() {
                        event.order = Int16(clamping: index)
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
