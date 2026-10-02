import SwiftUI
import CoreData

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
                    Text("Today")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .padding(.vertical, 8)
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
    @ObservedObject var viewModel: ContentViewModel
    @ObservedObject var dayPlannerVM: DayPlannerViewModel

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\Event.planOrder, order: .forward)],
        predicate: NSPredicate(format: "isActive == true AND planOrder >= 0"),
        animation: .spring(response: 0.4, dampingFraction: 0.8)
    ) private var plannedEvents: FetchedResults<Event>

    @State private var selectedDate = MyCalendar.getToday()
    @State private var finishError: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            titleRow
            planBar
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

    private var titleRow: some View {
        HStack {
            Button {
                HapticFeedback.light()
                do {
                    try withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        try viewModel.clearPlan()
                        viewModel.planBarExpansion = 1
                    }
                } catch {
                    finishError = error.localizedDescription
                }
            } label: {
                Text("Clear")
                    .font(.subheadline)
                    .foregroundStyle(plannedEvents.isEmpty ? Color.secondary : Color.color3)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(plannedEvents.isEmpty)
            .accessibilityLabel("Clear all planned events")
            Spacer()
            Text("All Events")
                .font(.title2)
                .bold()

            Spacer()

            Button {
                HapticFeedback.light()
                viewModel.showQuickFinishEditor = true
            } label: {
                Image(systemName: "pencil")
                    .font(.title3)
                    .foregroundStyle(.color3)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit Quick Finish")
        }
        .padding(.vertical, 8)
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
        Group {
            if plannedEvents.isEmpty {
                Text("Hold an event to add it to your plan")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)
                    .padding(.bottom, 12)
            } else {
                GeometryReader { geometry in
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal) {
                            HStack(spacing: 10 + 4 * viewModel.planBarExpansion) {
                                ForEach(plannedEvents) { event in
                                    plannedCard(event)
                                        .frame(width: 44 + (max(44, (geometry.size.width - 40) / 3) - 44) * viewModel.planBarExpansion)
                                        .id(event.objectID)
                                        .transition(.asymmetric(
                                            insertion: .move(edge: .bottom).combined(with: .opacity),
                                            removal: .scale(scale: 0.8).combined(with: .opacity)
                                        ))
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
                        .onChange(of: plannedEvents.map(\.objectID)) { oldIDs, newIDs in
                            guard let addedID = newIDs.last(where: { !oldIDs.contains($0) }) else { return }
                            // Let the inserted card and the scrollable width update first.
                            // An explicit command cannot be overwritten by scroll-position feedback.
                            DispatchQueue.main.async {
                                guard plannedEvents.last?.objectID == addedID else { return }
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    proxy.scrollTo(addedID, anchor: .trailing)
                                }
                            }
                        }
                    }
                }
                .frame(height: 52 + 78 * viewModel.planBarExpansion)
            }
        }
        .padding(.bottom, 8)
    }

    private func plannedCard(_ event: Event) -> some View {
        Button {
            if viewModel.planBarExpansion < 0.999 {
                HapticFeedback.light()
                withAnimation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(response: 0.35, dampingFraction: 0.85)) {
                    viewModel.planBarExpansion = 1
                }
                return
            }
            do {
                try EventActionHandler.shared.quickFinish(event, on: dayPlannerVM.currentDate, removingFromPlan: true)
                viewModel.refresh.toggle()
            } catch {
                finishError = error.localizedDescription
            }
        } label: {
            QuickFinishCard(
                event: event,
                color: Color(hex: event.activeCategories.first?.color),
                planExpansion: viewModel.planBarExpansion
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(viewModel.planBarExpansion < 0.999
            ? "Expand plan, \(event.name ?? "event")"
            : "Finish \(event.name ?? "event")")
        .accessibilityAction(named: "Remove from plan") { removePlannedEvent(event) }
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
            .accessibilityLabel("Remove \(event.name ?? "event") from plan")
            .opacity(viewModel.planBarExpansion)
            .allowsHitTesting(viewModel.planBarExpansion >= 0.999)
            .accessibilityHidden(viewModel.planBarExpansion < 0.999)
        }
    }

    private func removePlannedEvent(_ event: Event) {
        HapticFeedback.light()
        do {
            try withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                try viewModel.removeFromPlan(event)
            }
        } catch {
            finishError = error.localizedDescription
        }
    }

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
            .accessibilityLabel("Create Category")
        }
        .padding(.vertical, 8)
    }
}
