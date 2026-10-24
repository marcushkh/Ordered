import SwiftUI
import CoreData
import UniformTypeIdentifiers
import UIKit

struct TopBar: View {
    @ObservedObject var viewModel: ContentViewModel
    @ObservedObject var dayPlannerVM: DayPlannerViewModel
    @ObservedObject var statViewModel: StatViewModel

    var body: some View {
        VStack{
            Group {
                switch viewModel.currentTab {
                case .quick:
                    QuickFinishTopBar(viewModel: viewModel, dayPlannerVM: dayPlannerVM)
                case .statistic:
                    StatTopBar(viewModel: statViewModel, dayPlannerVM: dayPlannerVM)
                case .setting:
                    SettingTopBar(viewModel: viewModel)
                case .library:
                    LibraryTopBar(viewModel: viewModel)

                case .view:
                    CompletedEventsTopBar(selectedDate: $viewModel.viewedDate, viewModel: viewModel)
                }
            }
        }
        .padding(.horizontal, K.horizontal_padding)
        .background {
            UnevenRoundedRectangle(bottomLeadingRadius: 30, bottomTrailingRadius: 30)
                .fill(.color1)
                .ignoresSafeArea(edges: .top)
        }
    }
}

struct QuickFinishTopBar: View {
    @ObservedObject private var celebrations = EventCompletionCelebrations.shared
    @State private var finishingPlanItems: [(item: PlanItem, index: Int)] = []
    @ObservedObject var viewModel: ContentViewModel
    @ObservedObject var dayPlannerVM: DayPlannerViewModel

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\Event.planOrder, order: .forward)],
        predicate: NSPredicate(format: "isActive == true AND planOrder >= 0"),
        animation: .spring(response: 0.4, dampingFraction: 0.8)
    ) private var libraryPlanEvents: FetchedResults<Event>

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\Event_Cal.planOrder, order: .forward)],
        predicate: NSPredicate(format: "isOneTime == true AND aEndTime == nil AND planOrder >= 0"),
        animation: .spring(response: 0.4, dampingFraction: 0.8)
    ) private var oneTimePlanEvents: FetchedResults<Event_Cal>
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showOneTimeEditor = false

    private var plannedEvents: [PlanItem] {
        var items = PlanStore.ordered(libraryPlanEvents.map(PlanItem.event) + oneTimePlanEvents.map(PlanItem.oneTime))
        for retained in finishingPlanItems.sorted(by: { $0.index < $1.index })
            where !items.contains(where: { $0.id == retained.item.id }) {
            items.insert(retained.item, at: min(retained.index, items.count))
        }
        return items
    }

    @State private var selectedDate = MyCalendar.getToday()
    @State private var finishError: String?
    @State private var draggedPlanID: NSManagedObjectID?
    @State private var previewPlanOrder: [NSManagedObjectID]?
    @State private var expansionScrollTarget: NSManagedObjectID?

    private var displayedPlan: [PlanItem] {
        guard let previewPlanOrder else { return plannedEvents }
        let items = Dictionary(uniqueKeysWithValues: plannedEvents.map { ($0.id, $0) })
        return previewPlanOrder.compactMap { items[$0] }
            + plannedEvents.filter { !previewPlanOrder.contains($0.id) }
    }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            titleRow
            planBar
        }
        .sheet(isPresented: $showOneTimeEditor) { OneTimeEventEditor() }
        .alert("Couldn't Save Changes", isPresented: Binding(
            get: { finishError != nil },
            set: { if !$0 { finishError = nil } }
        )) {
            Button("OK", role: .cancel) { finishError = nil }
        } message: {
            Text(finishError ?? "Please try again.")
        }
    }

    private var titleRow: some View {
        HStack(spacing: 0) {
            Menu {
                Button("Expand all", systemImage: "arrow.up.left.and.arrow.down.right") {
                    HapticFeedback.light()
                    viewModel.expandAllCategoriesRequest = UUID()
                }
                Button {
                    HapticFeedback.light()
                    viewModel.showEventHideControls.toggle()
                } label: {
                    Label(
                        viewModel.showEventHideControls ? "Done Hiding Events" : "Hide Events for Today",
                        systemImage: viewModel.showEventHideControls ? "eye" : "eye.slash"
                    )
                }
                Button(role: .destructive) {
                    HapticFeedback.light()
                    do {
                        try withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            try viewModel.clearPlan()
                            viewModel.planBarExpansion = 0
                        }
                    } catch {
                        finishError = error.localizedDescription
                    }
                } label: {
                    Label("Clear All Planned Events", systemImage: "trash")
                }
                .disabled(plannedEvents.isEmpty)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.color3)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .menuOrder(.fixed)
            .accessibilityLabel("Home actions")

            QuickFinishOrderTitle(viewModel: viewModel)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 6)

            Group {
                if viewModel.showEventHideControls {
                    Button("Cancel") {
                        HapticFeedback.light()
                        viewModel.showEventHideControls = false
                    }
                    .font(.subheadline)
                    .foregroundStyle(.color3)
                    .frame(minWidth: 44, minHeight: 44)
                    .buttonStyle(.plain)
                    .accessibilityHint("Exit hide mode. Events already hidden stay hidden for today.")
                } else {
                    Color.clear
                        .frame(width: 44, height: 44)
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(.vertical, 8)
        .transaction { transaction in
            // Keep changing names and database updates from moving the header controls.
            transaction.animation = nil
            transaction.disablesAnimations = true
        }
        .onAppear {
            selectedDate = dayPlannerVM.currentDate
        }
        .onChange(of: selectedDate) { _, newValue in
            HapticFeedback.light()
            dayPlannerVM.setCurrentDate(to: newValue)
        }
        .onChange(of: dayPlannerVM.currentDate) { _, newValue in
            selectedDate = newValue
        }
    }

    private var planBar: some View {
        let expansion = min(1, max(0, viewModel.planBarExpansion))
        return HStack(alignment: .center, spacing: 10) {
            Group {
                if plannedEvents.isEmpty {
                    Text("Hold an event to add it to your plan")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 6)
                        .padding(.bottom, 12)
                    Button {
                        HapticFeedback.light()
                        showOneTimeEditor = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.color3)
                            .frame(width: 44, height: 44)
                            .background(Color.color5, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add one-time event to plan")
                    .showCase(.planAdd)
                } else {
                    GeometryReader { geometry in
                        ScrollViewReader { proxy in
                            ScrollView(.horizontal) {
                                HStack(spacing: 10 + 4 * viewModel.planBarExpansion) {
                                    ForEach(displayedPlan) { event in
                                        PlanDragSource(
                                            id: event.id,
                                            onBegin: { beginPlanDrag(event.id) },
                                            onEnd: { cancelPlanDrag() },
                                            content: plannedCard(event) {
                                                expandPlan(to: event.id, using: proxy)
                                            }
                                        )
                                            .frame(width: 44 + (max(44, (geometry.size.width - 40) / 3) - 44) * viewModel.planBarExpansion)
                                            .opacity(draggedPlanID == event.id ? 0.35 : 1)
                                            .onDrop(of: [.orderedPlannedEvent], delegate: PlanReorderDropDelegate(
                                                isActive: { draggedPlanID != nil },
                                                onHover: { previewPlan(over: event.id) },
                                                onDrop: commitPlanDrag
                                            ))
                                            .id(event.id)
                                            .transition(.asymmetric(
                                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                                removal: .scale(scale: 0.8).combined(with: .opacity)
                                            ))
                                    }
                                    Button {
                                        HapticFeedback.light()
                                        showOneTimeEditor = true
                                    } label: {
                                        Image(systemName: "plus")
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundStyle(.color3)
                                            .frame(width: 44, height: 44)
                                            .background(Color.color5, in: Circle())
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Add one-time event to plan")
                                    .showCase(.planAdd)
                                    .id("plan-add")
                                    .onDrop(of: [.orderedPlannedEvent], delegate: PlanReorderDropDelegate(
                                        isActive: { draggedPlanID != nil },
                                        onHover: { previewPlan(over: nil) },
                                        onDrop: commitPlanDrag
                                    ))
                                }
                            }
                            .scrollIndicators(.hidden)
                            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
                            .onChange(of: viewModel.tutorial.step, initial: true) { _, step in
                                guard step == .planAdd else { return }
                                DispatchQueue.main.async {
                                    proxy.scrollTo("plan-add", anchor: .trailing)
                                }
                            }
                            .onChange(of: plannedEvents.map(\.id)) { oldIDs, newIDs in
                                guard let addedID = newIDs.last(where: { !oldIDs.contains($0) }) else { return }
                                // Let the inserted card and the scrollable width update first.
                                // An explicit command cannot be overwritten by scroll-position feedback.
                                DispatchQueue.main.async {
                                    guard plannedEvents.last?.id == addedID else { return }
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        proxy.scrollTo(addedID, anchor: .trailing)
                                    }
                                }
                            }
                        }
                    }
                    .frame(height: 40 + 94 * viewModel.planBarExpansion)
                }
            }

        }
        .onDrop(of: [.orderedPlannedEvent], delegate: PlanReorderDropDelegate(
            isActive: { draggedPlanID != nil },
            onHover: {},
            onDrop: commitPlanDrag
        ))
        .onDisappear {
            expansionScrollTarget = nil
            cancelPlanDrag()
        }
        .onChange(of: viewModel.planBarExpansion) { _, expansion in
            if expansion < 0.999 { expansionScrollTarget = nil }
        }
        .padding(.top, 6)
        .padding(.bottom, 12)
        .onChange(of: Set(celebrations.active.keys)) { _, activeIDs in
            // Fallback if playback was interrupted or its view went off screen.
            finishingPlanItems.removeAll { !activeIDs.contains($0.item.id) }
        }
    }

    private func beginPlanDrag(_ id: NSManagedObjectID) {
        expansionScrollTarget = nil
        draggedPlanID = id
        previewPlanOrder = plannedEvents.map(\.id)
        HapticFeedback.light()
    }

    private func previewPlan(over target: NSManagedObjectID?) {
        guard let draggedPlanID, let current = previewPlanOrder, target != draggedPlanID else { return }
        var updated = current.filter { $0 != draggedPlanID }
        if let target {
            // Keep the target's original index: moving right inserts after it,
            // while moving left inserts before it, including adjacent cards.
            guard let index = current.firstIndex(of: target) else { return }
            updated.insert(draggedPlanID, at: index)
        } else {
            updated.append(draggedPlanID)
        }
        guard updated != current else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
            previewPlanOrder = updated
        }
        HapticFeedback.light()
    }

    private func commitPlanDrag() -> Bool {
        guard let order = previewPlanOrder else { return false }
        do {
            try PlanStore.reorder(order, in: viewContext)
            cancelPlanDrag()
            return true
        } catch {
            cancelPlanDrag()
            finishError = error.localizedDescription
            return false
        }
    }

    private func cancelPlanDrag() {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
            draggedPlanID = nil
            previewPlanOrder = nil
        }
    }

    private func expandPlan(to id: NSManagedObjectID, using proxy: ScrollViewProxy) {
        HapticFeedback.soft()
        expansionScrollTarget = id
        withAnimation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(response: 0.35, dampingFraction: 0.85), completionCriteria: .removed) {
            viewModel.planBarExpansion = 1
        } completion: {
            // Wait for the wider cards to finish laying out before choosing the scroll position.
            guard expansionScrollTarget == id,
                  viewModel.planBarExpansion >= 0.999,
                  plannedEvents.contains(where: { $0.id == id }) else { return }
            expansionScrollTarget = nil
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                proxy.scrollTo(id, anchor: .center)
            }
        }
    }

    private func plannedCard(_ event: PlanItem, onExpand: @escaping () -> Void) -> some View {
        Button {
            guard draggedPlanID == nil, celebrations.active[event.id] == nil else { return }
            if viewModel.planBarExpansion < 0.999 {
                onExpand()
                return
            }
            let previousIndex = plannedEvents.firstIndex(where: { $0.id == event.id }) ?? 0
            // Retain before saving: fetch results remove the event immediately on save.
            // This prevents the plan briefly becoming empty and collapsing mid-burst.
            finishingPlanItems.append((event, previousIndex))
            do {
                let today = MyCalendar.getToday()
                dayPlannerVM.setCurrentDate(to: today)
                switch event {
                case .event(let libraryEvent):
                    try EventActionHandler.shared.quickFinish(libraryEvent, on: today)
                case .oneTime(let occurrence):
                    HapticFeedback.soft()
                    try PlanStore.finishOneTime(occurrence.objectID, in: viewContext)
                    EventCompletionCelebrations.shared.celebrate(eventID: occurrence.objectID, completionID: occurrence.objectID)
                }
                finishingPlanItems.removeAll { celebrations.active[$0.item.id] == nil }
                viewModel.refresh.toggle()
            } catch {
                finishingPlanItems.removeAll { $0.item.id == event.id }
                finishError = error.localizedDescription
            }
        } label: {
            QuickFinishCardContent(
                name: event.name,
                icon: event.icon,
                color: planColor(event),
                planExpansion: viewModel.planBarExpansion,
                celebrationID: event.id,
                isCompletingPlan: finishingPlanItems.contains { $0.item.id == event.id },
                onCelebrationFinished: {
                    finishingPlanItems.removeAll { $0.item.id == event.id }
                }
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(viewModel.planBarExpansion < 0.999
            ? "Expand plan, \(event.name)"
            : "Finish \(event.name)")
        .accessibilityAction(named: "Remove from plan") { removePlannedEvent(event) }
        .accessibilityHint("Hold and drag to reorder your plan.")
        .accessibilityAction(named: "Move earlier in plan") { movePlannedEvent(event, by: -1) }
        .accessibilityAction(named: "Move later in plan") { movePlannedEvent(event, by: 1) }
        .overlay(alignment: .topTrailing) {
            Button {
                removePlannedEvent(event)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .red)
                    .frame(width: 32, height: 32)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .offset(x: 6, y: -10)
            .accessibilityLabel("Remove \(event.name) from plan")
            .opacity(viewModel.planBarExpansion >= 1 ? 1 : 0)
            .animation(nil, value: viewModel.planBarExpansion >= 1)
            .allowsHitTesting(viewModel.planBarExpansion >= 1)
            .accessibilityHidden(viewModel.planBarExpansion < 1)
        }
        .padding(.top, 12 * viewModel.planBarExpansion)
    }

    private func movePlannedEvent(_ item: PlannedEventDrag, to target: PlanItem) -> Bool {
        guard let source = plannedEvents.first(where: { $0.id.uriRepresentation() == item.uri }),
              source.id != target.id else { return false }
        do {
            try withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.85)) {
                try PlanStore.move(source.id, to: target.id, in: viewContext)
            }
            HapticFeedback.light()
            return true
        } catch {
            finishError = error.localizedDescription
            return false
        }
    }

    private func movePlannedEvent(_ event: PlanItem, by offset: Int) {
        let events = Array(plannedEvents)
        guard let index = events.firstIndex(where: { $0.id == event.id }), events.indices.contains(index + offset) else { return }
        _ = movePlannedEvent(PlannedEventDrag(uri: event.id.uriRepresentation()), to: events[index + offset])
    }

    private func planColor(_ item: PlanItem) -> Color {
        if case .event(let event) = item { return Color(hex: event.activeCategories.first?.color) }
        return .color1
    }

    private func removePlannedEvent(_ event: PlanItem) {
        HapticFeedback.light()
        do {
            try withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                try PlanStore.remove(event.id, in: viewContext)
            }
        } catch {
            finishError = error.localizedDescription
        }
    }

}

/// Native drag lifecycle lets a cancelled or outside drop discard the temporary order.
private struct PlanDragSource<Content: View>: UIViewControllerRepresentable {
    let id: NSManagedObjectID
    let onBegin: () -> Void
    let onEnd: () -> Void
    let content: Content

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIViewController(context: Context) -> UIHostingController<Content> {
        let controller = UIHostingController(rootView: content)
        controller.view.backgroundColor = .clear
        controller.safeAreaRegions = []
        let interaction = UIDragInteraction(delegate: context.coordinator)
        interaction.isEnabled = true
        controller.view.addInteraction(interaction)
        return controller
    }

    func updateUIViewController(_ controller: UIHostingController<Content>, context: Context) {
        context.coordinator.parent = self
        controller.rootView = content
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiViewController: UIHostingController<Content>, context: Context) -> CGSize? {
        uiViewController.sizeThatFits(in: CGSize(width: proposal.width ?? 44, height: proposal.height ?? 132))
    }

    final class Coordinator: NSObject, UIDragInteractionDelegate {
        var parent: PlanDragSource
        init(parent: PlanDragSource) { self.parent = parent }

        func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
            let provider = NSItemProvider()
            let data = Data(parent.id.uriRepresentation().absoluteString.utf8)
            provider.registerDataRepresentation(forTypeIdentifier: UTType.orderedPlannedEvent.identifier, visibility: .ownProcess) { completion in
                completion(data, nil)
                return nil
            }
            parent.onBegin()
            return [UIDragItem(itemProvider: provider)]
        }

        func dragInteraction(_ interaction: UIDragInteraction, session: UIDragSession, didEndWith operation: UIDropOperation) {
            parent.onEnd()
        }

        func dragInteraction(_ interaction: UIDragInteraction, sessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool { true }
        func dragInteraction(_ interaction: UIDragInteraction, sessionAllowsMoveOperation session: UIDragSession) -> Bool { true }
    }
}

private struct PlanReorderDropDelegate: DropDelegate {
    let isActive: () -> Bool
    let onHover: () -> Void
    let onDrop: () -> Bool

    func validateDrop(info: DropInfo) -> Bool {
        isActive() && info.hasItemsConforming(to: [.orderedPlannedEvent])
    }
    func dropEntered(info: DropInfo) { if isActive() { onHover() } }
    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: isActive() ? .move : .cancel) }
    func performDrop(info: DropInfo) -> Bool { isActive() && onDrop() }
}

private struct PlannedEventDrag: Codable, Transferable {
    let uri: URL

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .orderedPlannedEvent)
    }
}

private extension UTType {
    static let orderedPlannedEvent = UTType(exportedAs: "com.ordered.planned-event")
}

struct LibraryTopBar: View {
    @ObservedObject var viewModel: ContentViewModel

    var body: some View {
        HStack {
            Color.clear
                .frame(width: 44, height: 44)
            Spacer()
            Text("Library")
                .font(.title2.bold())
            Spacer()
            Button {
                HapticFeedback.light()
                viewModel.libraryEditorRoute = .category(nil)
            } label: {
                Image(systemName: "plus")
                    .font(.title3)
                    .foregroundStyle(.color3)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .showCase(.categoryPlus)
            .showCase(.openCategory, enabled: Category.count() == 0)
            .accessibilityLabel("Create Category")
        }
        .padding(.vertical, 8)
    }
}

/// Restores Home's month popover and week selector for browsing completions.
private struct CompletedEventsTopBar: View {
    @Binding var selectedDate: Date
    @ObservedObject var viewModel: ContentViewModel
    @State private var calendarDate = MyCalendar.getToday()
    @State private var showCalendar = false
    @State private var weekPages: [Date] = []

    private var calendar: Calendar {
        MyCalendar.weekCalendar
    }

    private var selectedWeek: Date {
        calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? calendar.startOfDay(for: selectedDate)
    }

    private func weekDates(startingAt start: Date) -> [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { select(MyCalendar.getToday()) } label: {
                    Image(systemName: "calendar.badge.clock")
                        .font(.title3)
                        .frame(width: 60, height: 44)
                }
                .foregroundStyle(.color3)
                .buttonStyle(.plain)
                .accessibilityLabel("Today")
                .accessibilityHint("Show today's completed events")
                Spacer(minLength: 0)
                Button {
                    HapticFeedback.light()
                    calendarDate = selectedDate
                    showCalendar = true
                } label: {
                    Text(selectedDate.monthYYYY())
                        .font(.title2.bold())
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Choose a date")
                .popover(isPresented: $showCalendar) {
                    DatePicker("Choose a date", selection: $calendarDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(.color4)
                        .frame(width: 320)
                        .padding()
                        .presentationCompactAdaptation(.popover)
                        .onChange(of: calendarDate) { _, newValue in
                            select(newValue)
                            showCalendar = false
                        }
                }
                Spacer(minLength: 0)
                Button {
                    viewModel.completedEventsShareRequest = UUID()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .frame(width: 60, height: 44)
                }
                .foregroundStyle(.color3)
                .buttonStyle(.plain)
                .accessibilityLabel("Share completed events for this day")
                .disabled(!viewModel.canShareCompletedEvents)
                .showCase(.shareDay)
            }
            .padding(.vertical, 8)

            SwipeableStack(weekPages, jumpTo: selectedWeek, onPageChanged: selectWeek) { start, _ in
                weekRow(startingAt: start)
            }
            .frame(height: 52)
            .padding(.vertical, K.xxxsmall_size)
            .accessibilityAction(named: "Previous week") { stepWeek(-1) }
            .accessibilityAction(named: "Next week") { stepWeek(1) }
        }
        .onChange(of: selectedWeek, initial: true) { _, week in
            if !weekPages.contains(week) { rebuildWeekPages() }
        }
        .onChange(of: calendar.firstWeekday) { _, _ in rebuildWeekPages() }
    }

    private func rebuildWeekPages() {
        var model = MyCalendar()
        model.startDate = min(model.startDate, calendar.date(byAdding: .year, value: -1, to: selectedDate) ?? selectedDate)
        model.endDate = max(model.endDate, calendar.date(byAdding: .year, value: 1, to: selectedDate) ?? selectedDate)
        weekPages = model.startDateOfWeeksInRange()
    }

    private func weekRow(startingAt start: Date) -> some View {
        HStack(spacing: 0) {
            ForEach(weekDates(startingAt: start), id: \.self) { date in
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                let isToday = calendar.isDate(date, inSameDayAs: MyCalendar.getToday())
                Button { select(date) } label: {
                    VStack(spacing: 3) {
                        Text(date.weekDayAbbrev())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(date.dayNum())
                            .bold(isToday)
                            .foregroundStyle(isToday ? (isSelected ? Color.white : .color4) : (isSelected ? .cBackground : .cPrimary))
                            .frame(width: K.large_size, height: K.large_size)
                            .background(
                                isSelected ? (isToday ? Color.color3 : .color4) : .cBackground,
                                in: Circle()
                            )
                    }
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(date.formatted(date: .complete, time: .omitted))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
    }
    }

    private func selectWeek(_ start: Date) {
        guard !calendar.isDate(start, equalTo: selectedDate, toGranularity: .weekOfYear) else { return }
        select(MyCalendar.selection(inWeekContaining: start, preserving: selectedDate,
                                    today: MyCalendar.getToday(), calendar: calendar))
    }

    private func select(_ date: Date) {
        HapticFeedback.light()
        selectedDate = calendar.startOfDay(for: date)
    }

    private func stepWeek(_ offset: Int) {
        if let start = calendar.date(byAdding: .weekOfYear, value: offset, to: selectedWeek) {
            selectWeek(start)
        }
    }
}
