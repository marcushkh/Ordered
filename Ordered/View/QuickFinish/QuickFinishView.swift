//
//  QuickFinishView.swift
//  Ordered
//

import SwiftUI
import CoreData
import UIKit

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

    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "isOneTime == true AND aEndTime == nil AND planOrder >= 0")
    ) private var oneTimePlanEvents: FetchedResults<Event_Cal>

    @ObservedObject private var celebrations = EventCompletionCelebrations.shared
    @State private var categoryPreview: QuickFinishEventGroup?
    @State private var finishError: String?
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: []) private var categoryDisplayStates: FetchedResults<CategoryDisplayState>

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 14),
        count: 3
    )

    private var shouldTrackPlanCollapse: Bool {
        viewModel.planBarExpansion > 0
            && (!oneTimePlanEvents.isEmpty || events.contains { $0.planOrder >= 0 })
    }

    var body: some View {
        let finishedIDs = finishedGroupIDs
        let groups = eventGroups
        // Publish the capsule and collapse the category in the same layout update.
        let settledFinishedIDs = finishedIDs.subtracting(completionHeldGroupIDs)
        let finishedGroups = groups.filter { settledFinishedIDs.contains($0.id) }
        let hiddenIDs = hiddenCategoryIDs
        let pillGroups = makeEventGroups(from: Array(events), includingHiddenCategories: true).filter { group in
            hiddenIDs.contains(group.id) || finishedGroups.contains { $0.id == group.id }
        }

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if viewModel.showQuickFinishSearch {
                    TextField("Search events", text: $viewModel.quickFinishSearchText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, K.horizontal_padding)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if !pillGroups.isEmpty {
                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            ForEach(pillGroups) { group in
                                categoryPill(group, isHidden: hiddenIDs.contains(group.id))
                            }
                        }
                        .padding(.horizontal, K.horizontal_padding)
                    }
                    .scrollIndicators(.hidden)
                }

                ForEach(groups) { group in
                    eventGroup(group, isFinished: finishedIDs.contains(group.id))
                }

                if eventGroups.isEmpty && pillGroups.isEmpty {
                    ContentUnavailableView(
                        viewModel.quickFinishSearchText.isEmpty ? (events.isEmpty ? "No Events" : "No Visible Events") : "No Results",
                        systemImage: "checkmark.circle",
                        description: Text(
                            viewModel.quickFinishSearchText.isEmpty
                                ? (events.isEmpty ? "Add events from Library to see them in Home." : "Tap the pencil to show categories or events in this order.")
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
                    guard shouldTrackPlanCollapse,
                          value.translation.height < -3,
                          abs(value.translation.height) > abs(value.translation.width) else { return }
                    // Collapse once; subsequent drag updates do not publish screen changes.
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.planBarExpansion = 0
                    }
                },
            including: shouldTrackPlanCollapse ? .all : .subviews
        )
        .onAppear { viewModel.planBarExpansion = 0 }
        .sheet(item: $categoryPreview) { group in
            NavigationStack {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(group.events) { event in
                            eventTile(event, color: group.color, showsHideControls: false, showsHiddenState: true)
                        }
                    }
                    .padding()
                }
                .navigationTitle("\(group.icon) \(group.name)")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(hiddenCategoryIDs.contains(group.id) ? "Unhide" : "Hide") {
                            setCategoryHiddenForToday(group, hidden: !hiddenCategoryIDs.contains(group.id))
                        }
                        .accessibilityLabel("\(hiddenCategoryIDs.contains(group.id) ? "Unhide" : "Hide") \(group.name) for today")
                    }
                }
                .alert("Couldn't Save Changes", isPresented: Binding(
                    get: { finishError != nil },
                    set: { if !$0 { finishError = nil } }
                )) {
                    Button("OK", role: .cancel) { finishError = nil }
                } message: {
                    Text(finishError ?? "Please try again.")
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
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
        .onChange(of: finishedIDs, initial: true) { _, finishedIDs in
            clearUnfinishedExpansionOverrides(finishedIDs: finishedIDs)
        }
        .onChange(of: viewModel.quickFinishOrders.selectedID) { _, _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                expandCategoriesForSelectedOrder(includingFinished: false)
            }
        }
        .onChange(of: viewModel.expandAllCategoriesRequest) { _, _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                expandCategoriesForSelectedOrder()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: settledFinishedIDs)
    }

    private var visibleEvents: [Event] {
        Array(events).filter { !isHiddenToday($0) }
    }

    private func isHiddenToday(_ event: Event) -> Bool {
        let day = dayPlannerVM.currentDate.getYYMMDD()
        if event.hiddenDay == day { return true }
        if event.visibleDay == day { return false }
        return viewModel.quickFinishOrders.selected?.hiddenEventIDs
            .contains(event.objectID.uriRepresentation().absoluteString) == true
    }

    private var filteredEvents: [Event] {
        guard !viewModel.quickFinishSearchText.isEmpty else {
            return visibleEvents
        }

        return visibleEvents.filter {
            ($0.name ?? "").localizedCaseInsensitiveContains(viewModel.quickFinishSearchText)
        }
    }

    private var eventGroups: [QuickFinishEventGroup] {
        makeEventGroups(from: filteredEvents)
    }

    private var finishedGroupIDs: Set<String> {
        // Search only changes the displayed tiles, never category completion.
        Set(makeEventGroups(from: visibleEvents).filter { group in
            !group.events.isEmpty && group.events.allSatisfy { finishedCount(for: $0) > 0 }
        }.map(\.id))
    }

    private var completionHeldGroupIDs: Set<String> {
        // Search must not detach the capsule timing from a category's celebration.
        Set(makeEventGroups(from: visibleEvents).filter { group in
            group.events.contains { celebrations.holdsCategoryOpen(eventID: $0.objectID) }
        }.map(\.id))
    }

    private var hiddenCategoryIDs: Set<String> {
        let day = dayPlannerVM.currentDate.getYYMMDD()
        let dailyHidden = Set(categoryDisplayStates.filter { $0.hiddenDay == day }.compactMap(\.groupID))
        let dailyVisible = Set(categoryDisplayStates.filter { $0.visibleDay == day }.compactMap(\.groupID))
        let orderHidden = viewModel.quickFinishOrders.selected?.hiddenGroupIDs ?? []
        return dailyHidden.union(orderHidden.subtracting(dailyVisible))
    }

    private func makeEventGroups(from includedEvents: [Event], includingHiddenCategories: Bool = false) -> [QuickFinishEventGroup] {
        var groups = categories.compactMap { category -> QuickFinishEventGroup? in
            let categoryEvents = category.orderedActiveEvents.filter { includedEvents.contains($0) }
            guard !categoryEvents.isEmpty else { return nil }

            return QuickFinishEventGroup(
                id: category.objectID.uriRepresentation().absoluteString,
                icon: category.icon ?? "🏷️",
                name: category.name ?? "Category",
                color: Color(hex: category.color),
                events: categoryEvents
            )
        }

        let uncategorizedEvents = includedEvents.filter { $0.activeCategories.isEmpty }
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

        if let order = viewModel.quickFinishOrders.selected {
            groups = order.arranged(groups, ids: order.groupIDs, identifier: { $0.id })
                .map { group in
                    QuickFinishEventGroup(id: group.id, icon: group.icon, name: group.name, color: group.color,
                        events: order.arranged(group.events, ids: order.eventIDs[group.id] ?? [],
                            identifier: { $0.objectID.uriRepresentation().absoluteString }))
                }
        }
        return includingHiddenCategories ? groups : groups.filter { !hiddenCategoryIDs.contains($0.id) }
    }

    private var finishedEventCount: Int {
        filteredEvents.filter { finishedCount(for: $0) > 0 }.count
    }

    @ViewBuilder
    private func eventGroup(_ group: QuickFinishEventGroup, isFinished: Bool) -> some View {
        if let savedState = categoryDisplayStates.first(where: { $0.groupID == group.id }) {
            ObservedCategoryDisplayState(
                state: savedState,
                isFinished: isFinished,
                day: dayPlannerVM.currentDate.getYYMMDD()
            ) { isCollapsed in
                eventGroupContent(group, isFinished: isFinished, isCollapsed: viewModel.tutorial.step == .finishEvent ? false : isCollapsed)
            }
        } else {
            eventGroupContent(group, isFinished: isFinished, isCollapsed: viewModel.tutorial.step == .finishEvent ? false : isFinished)
        }
    }

    @ViewBuilder
    private func eventGroupContent(_ group: QuickFinishEventGroup, isFinished: Bool, isCollapsed: Bool) -> some View {
        let isCelebrating = completionHeldGroupIDs.contains(group.id)
        if !isFinished || !isCollapsed || isCelebrating {
            expandedOrUnfinishedGroup(group, isFinished: isFinished, isCollapsed: isCollapsed && !isCelebrating)
        }
    }

    private func setCategoryHiddenForToday(_ group: QuickFinishEventGroup, hidden: Bool) {
        let existing = categoryDisplayStates.first { $0.groupID == group.id }
        let state = existing ?? CategoryDisplayState(context: context)
        let previousDay = state.hiddenDay
        let previousVisibleDay = state.visibleDay
        state.groupID = group.id
        let day = dayPlannerVM.currentDate.getYYMMDD()
        state.hiddenDay = hidden ? day : nil
        state.visibleDay = hidden ? nil : day
        do {
            try context.save()
            HapticFeedback.light()
            viewModel.refresh.toggle()
            categoryPreview = nil
        } catch {
            if existing == nil {
                context.delete(state)
            } else {
                state.hiddenDay = previousDay
                state.visibleDay = previousVisibleDay
            }
            finishError = error.localizedDescription
        }
    }

    private func openCategoryPreview(_ group: QuickFinishEventGroup) {
        HapticFeedback.light()
        // Bypass both today's hidden events and the order's event visibility settings.
        categoryPreview = makeEventGroups(from: Array(events), includingHiddenCategories: true).first { $0.id == group.id }
    }

    private func categoryPill(_ group: QuickFinishEventGroup, isHidden: Bool) -> some View {
        Button {
            openCategoryPreview(group)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: isHidden ? "eye.slash" : "checkmark.circle")
                Text(group.icon)
                Text(group.name)
            }
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .foregroundStyle(.cPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(group.color, in: Capsule())
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(group.name), \(isHidden ? "hidden" : "completed")")
        .accessibilityHint("Show all category events, including hidden events")
    }

    private func expandedOrUnfinishedGroup(_ group: QuickFinishEventGroup, isFinished: Bool, isCollapsed: Bool) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Button {
                    openCategoryPreview(group)
                } label: {
                    HStack(spacing: 10) {
                        Text(group.icon)
                        Text(group.name).bold()
                    }
                    .font(.title3)
                    .foregroundStyle(.cPrimary)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Show all category events, including hidden events")

                Capsule()
                    .fill(.color3)
                    .frame(height: 2)

                if isFinished {
                    ZStack{
                        Circle()
                            .foregroundStyle(.success)

                        Image(systemName: "checkmark.circle")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.cPrimary)
                            .accessibilityLabel("Finished")
                    }
                    .frame(width: 24, height: 24)
                }

                Button {
                    HapticFeedback.light()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        saveDisplayState(for: group.id, minimized: !isCollapsed, isFinished: isFinished)
                    }
                } label: {
                    Image(systemName: isCollapsed ? "chevron.up" : "chevron.down")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.cPrimary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(isCollapsed ? "Expand" : "Minimize") \(group.name)")
                .accessibilityValue(isCollapsed ? "Collapsed" : "Expanded")
            }

            if !isCollapsed {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(group.events) { event in
                        eventTile(event, color: group.color)
                    }
                }
            }
        }
        .padding(.horizontal, K.horizontal_padding)
    }

    private func saveDisplayState(for groupID: String, minimized: Bool, isFinished: Bool) {
        let existing = categoryDisplayStates.first { $0.groupID == groupID }
        let state = existing ?? CategoryDisplayState(context: context)
        let previousMinimized = state.isMinimized
        let previousExpandedDay = state.expandedFinishedDay
        state.groupID = groupID
        state.isMinimized = minimized
        state.expandedFinishedDay = !minimized && isFinished ? dayPlannerVM.currentDate.getYYMMDD() : nil
        do {
            try context.save()
        } catch {
            if existing == nil {
                context.delete(state)
            } else {
                state.isMinimized = previousMinimized
                state.expandedFinishedDay = previousExpandedDay
            }
            finishError = error.localizedDescription
        }
    }

    private func expandCategoriesForSelectedOrder(includingFinished: Bool = true) {
        let finishedIDs = finishedGroupIDs
        let day = dayPlannerVM.currentDate.getYYMMDD()
        // Include every visible category in the order, even when search hides its tiles.
        let groupsToExpand = makeEventGroups(from: visibleEvents).filter { group in
            if includingFinished { return true }
            return !finishedIDs.contains(group.id)
                && categoryDisplayStates.contains { $0.groupID == group.id && $0.isMinimized }
        }
        guard !groupsToExpand.isEmpty else { return }
        let previousStates = groupsToExpand.map { group in
            let existing = categoryDisplayStates.first { $0.groupID == group.id }
            let state = existing ?? CategoryDisplayState(context: context)
            let previous = (state: state, isNew: existing == nil,
                            minimized: state.isMinimized, expandedDay: state.expandedFinishedDay)
            state.groupID = group.id
            state.isMinimized = false
            state.expandedFinishedDay = finishedIDs.contains(group.id) ? day : nil
            return previous
        }
        do {
            try context.save()
        } catch {
            for previous in previousStates {
                if previous.isNew {
                    context.delete(previous.state)
                } else {
                    previous.state.isMinimized = previous.minimized
                    previous.state.expandedFinishedDay = previous.expandedDay
                }
            }
            finishError = error.localizedDescription
        }
    }

    private func clearUnfinishedExpansionOverrides(finishedIDs: Set<String>) {
        // Hidden groups keep their preferences; search does not affect completion.
        let visibleIDs = Set(makeEventGroups(from: visibleEvents).map(\.id))
        let states = categoryDisplayStates.filter {
            guard let id = $0.groupID else { return false }
            return visibleIDs.contains(id) && !finishedIDs.contains(id) && $0.expandedFinishedDay != nil
        }
        guard !states.isEmpty else { return }
        let previousDays = states.map(\.expandedFinishedDay)
        states.forEach { $0.expandedFinishedDay = nil }
        do {
            try context.save()
        } catch {
            for (state, day) in zip(states, previousDays) {
                state.expandedFinishedDay = day
            }
            finishError = error.localizedDescription
        }
    }

    private func eventTile(_ event: Event, color: Color, showsHideControls: Bool = true, showsHiddenState: Bool = false) -> some View {
        let count = finishedCount(for: event)

        return QuickFinishCard(event: event, color: color, finishedCount: count)
            .showCase(.finishEvent, enabled: event.objectID == eventGroups.first?.events.first?.objectID)
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
            .overlay(alignment: .topTrailing) {
                if showsHiddenState && isHiddenToday(event) {
                    Button {
                        unhideForToday(event)
                    } label: {
                        Image(systemName: "eye.slash")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.cPrimary)
                            .frame(width: 28, height: 28)
                            .background(Color.color1, in: Circle())
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Show \(event.name ?? "event") again for today")
                } else if showsHideControls && viewModel.showEventHideControls {
                    Button {
                        hideForToday(event)
                    } label: {
                        Image(systemName: "eye")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.cPrimary)
                            .frame(width: 28, height: 28)
                            .background(Color.color1, in: Circle())
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Hide \(event.name ?? "event") for today")
                }
            }
    }

    private func unhideForToday(_ event: Event) {
        let previousHiddenDay = event.hiddenDay
        let previousVisibleDay = event.visibleDay
        HapticFeedback.light()
        withAnimation(.easeInOut(duration: 0.2)) {
            event.hiddenDay = nil
            event.visibleDay = dayPlannerVM.currentDate.getYYMMDD()
            do {
                try context.save()
                viewModel.refresh.toggle()
            } catch {
                event.hiddenDay = previousHiddenDay
                event.visibleDay = previousVisibleDay
                finishError = error.localizedDescription
            }
        }
    }

    private func hideForToday(_ event: Event) {
        let previousDay = event.hiddenDay
        HapticFeedback.light()
        withAnimation(.easeInOut(duration: 0.2)) {
            event.hiddenDay = dayPlannerVM.currentDate.getYYMMDD()
            do {
                try context.save()
                viewModel.refresh.toggle()
            } catch {
                event.hiddenDay = previousDay
                finishError = error.localizedDescription
            }
        }
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
            let today = MyCalendar.getToday()
            dayPlannerVM.setCurrentDate(to: today)
            let completion = try EventActionHandler.shared.quickFinish(event, on: today)
            viewModel.tutorial.finishedEvent(completionID: completion.objectID.uriRepresentation().absoluteString)
        } catch {
            finishError = error.localizedDescription
        }
        viewModel.refresh.toggle()
    }
}

/// Fetch results track membership; observe the record itself for repeated preference edits.
private struct ObservedCategoryDisplayState<Content: View>: View {
    @ObservedObject var state: CategoryDisplayState
    let isFinished: Bool
    let day: String
    @ViewBuilder var content: (Bool) -> Content

    var body: some View {
        content(state.isMinimized || (isFinished && state.expandedFinishedDay != day))
    }
}

/// Shared appearance for the full event tile and its shorter planned copy.
struct QuickFinishCard: View {
    @ObservedObject var event: Event
    let color: Color
    var finishedCount: Int? = nil
    var planExpansion: CGFloat = 1

    var body: some View {
        QuickFinishCardContent(name: event.name ?? "Event", icon: event.icon ?? "",
                               color: color, finishedCount: finishedCount, planExpansion: planExpansion,
                               celebrationID: event.objectID)
    }
}

struct QuickFinishCardContent: View {
    let name: String
    let icon: String
    let color: Color
    var finishedCount: Int? = nil
    var planExpansion: CGFloat = 1
    var statusText: String? = nil
    var systemIcon: String? = nil
    var celebrationID: NSManagedObjectID? = nil
    var draftCelebrationID: UUID? = nil
    var isCompletingPlan = false
    var onCelebrationFinished: (() -> Void)? = nil

    var body: some View {
        let isFinished = (finishedCount ?? 0) > 0
        let expansion = min(1, max(0, planExpansion))
        let showsName = finishedCount != nil || expansion >= 1
        VStack(spacing: 10 * expansion) {
            Text(name)
                .font(.subheadline)
                .foregroundStyle(.cPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .frame(height: finishedCount == nil ? 36 * expansion : nil)
                .opacity(showsName ? 1 : 0)
                .animation(nil, value: showsName)
                .clipped()
                .accessibilityHidden(!showsName)

            Group {
                if let systemIcon {
                    Image(systemName: systemIcon)
                } else {
                    EventCompletionIcon(icon: icon, eventID: celebrationID, fontSize: 22 + 6 * expansion,
                                        draftID: draftCelebrationID,
                                        hidesEmojiAfterCompletion: isCompletingPlan,
                                        onPlaybackFinished: onCelebrationFinished)
                }
            }
                .font(.system(size: 22 + 6 * expansion))
                .frame(width: 44 + 12 * expansion, height: 44 + 12 * expansion)
                .background(isFinished || isCompletingPlan ? Color.success : color, in: Circle())

            if let count = finishedCount {
                Text(statusText ?? (count > 0 ? "\(count) \(count == 1 ? "time" : "times") today" : "Finish"))
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

private struct QuickFinishItemDraft: Identifiable, Equatable {
    let id: NSManagedObjectID
    let name: String
    let icon: String
    var isVisible: Bool
}

private struct QuickFinishGroupDraft: Identifiable, Equatable {
    let id: String
    let categoryID: NSManagedObjectID?
    let name: String
    let icon: String
    var items: [QuickFinishItemDraft]
    var isVisible: Bool = true
}

private struct QuickFinishEditor: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var viewModel: ContentViewModel
    @State private var groups: [QuickFinishGroupDraft]
    @State private var draftName: String
    @State private var isRenaming = false
    @FocusState private var nameFocused: Bool
    @State private var saveError: String?
    @State private var hasUnsavedChanges = false
    private let orderID: UUID?

    init(categories: [Category], events: [Event], viewModel: ContentViewModel) {
        self.viewModel = viewModel
        let order = viewModel.quickFinishOrders.selected
        orderID = order?.id
        _draftName = State(initialValue: order?.name ?? "All Events")
        func items(_ events: [Event]) -> [QuickFinishItemDraft] {
            events.map { event in
                QuickFinishItemDraft(
                    id: event.objectID,
                    name: event.name ?? "Event",
                    icon: event.icon ?? "",
                    isVisible: order.map { order in !order.hiddenEventIDs.contains(event.objectID.uriRepresentation().absoluteString) } ?? true
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
        if let order {
            drafts = order.arranged(drafts, ids: order.groupIDs, identifier: { $0.id })
            for index in drafts.indices {
                drafts[index].items = order.arranged(drafts[index].items,
                    ids: order.eventIDs[drafts[index].id] ?? [],
                    identifier: { $0.id.uriRepresentation().absoluteString })
            }
        }
        let hiddenGroups = order?.hiddenGroupIDs ?? []
        for index in drafts.indices { drafts[index].isVisible = !hiddenGroups.contains(drafts[index].id) }
        _groups = State(initialValue: drafts)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Category Order") {
                    ForEach($groups) { $group in
                        visibilityRow(name: group.name, icon: group.icon, isVisible: $group.isVisible)
                    }
                    .onMove { source, destination in
                        groups.move(fromOffsets: source, toOffset: destination)
                        if orderID == nil {
                            groups = groups.filter { $0.categoryID != nil } + groups.filter { $0.categoryID == nil }
                        }
                    }
                }

                ForEach($groups) { $group in
                    Section("\(group.icon) \(group.name)") {
                        ForEach($group.items) { $item in
                            visibilityRow(name: item.name, icon: item.icon, isVisible: $item.isVisible)
                        }
                        .onMove { source, destination in
                            group.items.move(fromOffsets: source, toOffset: destination)
                        }
                    }
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle(draftName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if orderID != nil {
                        if isRenaming {
                            TextField("New Order", text: $draftName)
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .focused($nameFocused)
                                .submitLabel(.done)
                                .onSubmit { isRenaming = false }
                                .task { nameFocused = true }
                                .onChange(of: nameFocused) { _, focused in
                                    if !focused { isRenaming = false }
                                }
                                .accessibilityLabel("Order name")
                        } else {
                            Button {
                                isRenaming = true
                            } label: {
                                HStack(spacing: 6) {
                                    Text(draftName.isEmpty ? "New Order" : draftName)
                                        .lineLimit(1)
                                    Image(systemName: "pencil")
                                        .font(.caption)
                                }
                                .font(.headline)
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Rename \(draftName)")
                        }
                    } else {
                        Text("All Events").font(.headline)
                    }
                }
            }
            .onChange(of: groups) { _, _ in _ = save() }
            .onChange(of: draftName) { _, _ in _ = save() }
            .alert("Couldn't Save Home", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("Retry") { _ = save() }
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "Please try again.")
            }
        }
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(hasUnsavedChanges)
    }

    private func visibilityRow(name: String, icon: String, isVisible: Binding<Bool>) -> some View {
        HStack {
            Text(icon)
            Text(name)
                .foregroundStyle(isVisible.wrappedValue ? Color.primary : Color.secondary)
            Spacer()
            if orderID != nil {
                Button {
                    isVisible.wrappedValue.toggle()
                } label: {
                    Image(systemName: isVisible.wrappedValue ? "eye" : "eye.slash")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.color3)
                .font(.subheadline)
                .accessibilityLabel("\(isVisible.wrappedValue ? "Hide" : "Unhide") \(name)")
            }
        }
    }

    @discardableResult
    private func save() -> Bool {
        hasUnsavedChanges = true
        if let orderID {
            guard let index = viewModel.quickFinishOrders.orders.firstIndex(where: { $0.id == orderID }) else {
                saveError = "This order is no longer available. Close the editor and choose another order."
                return false
            }
            var order = viewModel.quickFinishOrders.orders[index]
            let trimmedName = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
            order.name = trimmedName.isEmpty ? "New Order" : trimmedName
            order.groupIDs = groups.map(\.id)
            order.eventIDs = Dictionary(uniqueKeysWithValues: groups.map {
                ($0.id, $0.items.map { $0.id.uriRepresentation().absoluteString })
            })
            order.hiddenGroupIDs = Set(groups.filter { !$0.isVisible }.map(\.id))
            order.hiddenEventIDs = Set(groups.flatMap(\.items).filter { !$0.isVisible }
                .map { $0.id.uriRepresentation().absoluteString })
            viewModel.quickFinishOrders.orders[index] = order
            saveError = nil
            hasUnsavedChanges = false
            return true
        }
        // Isolate each save so failures do not roll back unrelated edits.
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = viewContext.persistentStoreCoordinator
        do {
            for (groupIndex, group) in groups.enumerated() {
                let orderedEvents = try group.items.map { item -> Event in
                    let event = try context.existingObject(with: item.id) as! Event
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
            saveError = nil
            hasUnsavedChanges = false
            return true
        } catch {
            context.rollback()
            saveError = error.localizedDescription
            return false
        }
    }
}

/// Focus and select the initial name after the field is attached to its window.
private struct SelectedOrderNameField: UIViewRepresentable {
    @Binding var text: String
    let onFinish: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> OrderNameTextField {
        let field = OrderNameTextField()
        field.text = text
        field.placeholder = "New Order"
        field.textAlignment = .center
        let font = UIFont.preferredFont(forTextStyle: .title2)
        field.font = UIFont(descriptor: font.fontDescriptor.withSymbolicTraits(.traitBold) ?? font.fontDescriptor, size: 0)
        field.adjustsFontForContentSizeCategory = true
        field.returnKeyType = .done
        field.accessibilityLabel = "Order name"
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        field.delegate = context.coordinator
        field.addTarget(context.coordinator, action: #selector(Coordinator.textChanged(_:)), for: .editingChanged)
        field.onAttach = { [weak field] in
            DispatchQueue.main.async {
                guard let field, field.window != nil, !field.isFirstResponder else { return }
                field.becomeFirstResponder()
            }
        }
        return field
    }

    func updateUIView(_ field: OrderNameTextField, context: Context) {
        context.coordinator.parent = self
        if field.text != text { field.text = text }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: SelectedOrderNameField
        private var hasSelectedInitialName = false

        init(parent: SelectedOrderNameField) { self.parent = parent }

        @objc func textChanged(_ field: UITextField) {
            parent.text = field.text ?? ""
        }

        func textFieldDidBeginEditing(_ field: UITextField) {
            guard !hasSelectedInitialName else { return }
            hasSelectedInitialName = true
            DispatchQueue.main.async { [weak field] in
                guard let field, field.isFirstResponder else { return }
                field.selectedTextRange = field.textRange(from: field.beginningOfDocument, to: field.endOfDocument)
            }
        }

        func textFieldDidEndEditing(_ field: UITextField) {
            parent.text = field.text ?? ""
            parent.onFinish()
        }

        func textFieldShouldReturn(_ field: UITextField) -> Bool {
            field.resignFirstResponder()
            return true
        }
    }
}

private final class OrderNameTextField: UITextField {
    var onAttach: (() -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil { onAttach?() }
    }
}

/// Shared with the fixed header so selecting an order updates the grid immediately.
struct QuickFinishOrderTitle: View {
    @ObservedObject var viewModel: ContentViewModel
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: [SortDescriptor(\Category.order)],
                  predicate: NSPredicate(format: "isActive == true")) private var categories: FetchedResults<Category>
    @FetchRequest(sortDescriptors: [SortDescriptor(\Event.order)],
                  predicate: NSPredicate(format: "isActive == true")) private var events: FetchedResults<Event>
    @State private var isRenaming = false
    @State private var draftName = ""
    @State private var creationError: String?

    var body: some View {
        Group {
            if isRenaming {
                SelectedOrderNameField(text: $draftName, onFinish: finishRenaming)
                    .frame(height: 44)
            } else {
                Menu {
                    Button { select(nil) } label: {
                        if viewModel.quickFinishOrders.selected == nil {
                            Label("All Events", systemImage: "checkmark")
                        } else { Text("All Events") }
                    }
                    ForEach(viewModel.quickFinishOrders.orders) { order in
                        Button { select(order.id) } label: {
                            if order.id == viewModel.quickFinishOrders.selectedID {
                                Label(order.name, systemImage: "checkmark")
                            } else { Text(order.name) }
                        }
                    }
                    Divider()
                    Button("Edit Order", systemImage: "pencil") {
                        HapticFeedback.light()
                        viewModel.showQuickFinishEditor = true
                    }
                    Button("Add New Order", systemImage: "plus") { addOrder() }
                } label: {
                    HStack(spacing: 6) {
                        Text(viewModel.quickFinishOrders.selected?.name ?? "All Events")
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.caption.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .menuOrder(.fixed)
                .accessibilityHint("Choose, edit, or add a Home order")
            }
        }
        .font(.title2.bold())
        .onDisappear { finishRenaming() }
        .alert("Couldn't Create Order", isPresented: Binding(
            get: { creationError != nil }, set: { if !$0 { creationError = nil } }
        )) {
            Button("OK", role: .cancel) { creationError = nil }
        } message: { Text(creationError ?? "Please try again.") }
    }

    private func select(_ id: UUID?) {
        viewModel.quickFinishOrders.selectedID = id
        viewModel.quickFinishSearchText = ""
        HapticFeedback.light()
    }

    private func beginRenaming() {
        draftName = viewModel.quickFinishOrders.selected?.name ?? "New Order"
        isRenaming = true
    }

    private func finishRenaming() {
        guard isRenaming else { return }
        viewModel.quickFinishOrders.renameSelected(draftName)
        isRenaming = false
    }

    private func addOrder() {
        do {
            // Persist object IDs before using them as saved layout references.
            let objects: [NSManagedObject] = Array(categories) + Array(events)
            try context.obtainPermanentIDs(for: objects.filter { $0.objectID.isTemporaryID })
            var groupIDs = categories.map { $0.objectID.uriRepresentation().absoluteString }
            var eventIDs = Dictionary(uniqueKeysWithValues: categories.map { category in
                (category.objectID.uriRepresentation().absoluteString,
                 category.orderedActiveEvents.map { $0.objectID.uriRepresentation().absoluteString })
            })
            groupIDs.append("uncategorized")
            eventIDs["uncategorized"] = events.filter { $0.activeCategories.isEmpty }
                .map { $0.objectID.uriRepresentation().absoluteString }
            viewModel.quickFinishOrders.add(QuickFinishOrder(
                groupIDs: groupIDs, eventIDs: eventIDs,
                hiddenGroupIDs: [],
                hiddenEventIDs: []
            ))
            viewModel.quickFinishSearchText = ""
            HapticFeedback.light()
            beginRenaming()
        } catch { creationError = error.localizedDescription }
    }
}
