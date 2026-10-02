import SwiftUI
import CoreData
import Combine

struct CompletedEventsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var viewModel: ContentViewModel
    @AppStorage("DayStartTime") private var dayStartTime = 0
    @State private var today = MyCalendar.getToday()
    @State private var deleteError: String?

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Event_Cal.aEndTime, ascending: false)],
        predicate: CompletedEventsView.predicate(for: MyCalendar.getToday()),
        animation: .default
    ) private var completions: FetchedResults<Event_Cal>

    // Also update while the app stays open across the configured day boundary.
    private let clock = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(today, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                Spacer()
                Text("\(completions.count) completed")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.horizontal, K.horizontal_padding)
            .padding(.vertical, 16)

            if completions.isEmpty {
                ContentUnavailableView(
                    "No Completed Events Today",
                    systemImage: "checkmark.circle",
                    description: Text("Finish an event in Quick Finish to see it here.")
                )
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(orderedCompletions) { completion in
                        CompletedEventRow(completion: completion) {
                            delete(completion)
                        }
                        .listRowBackground(Color.color5)
                        .swipeActions(edge: .trailing) {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                delete(completion)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .contentMargins(.top, 0)
            }
        }
        .padding(.bottom, 80)
        .onAppear(perform: refreshToday)
        .onReceive(clock) { _ in refreshToday() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refreshToday() }
        }
        .onChange(of: dayStartTime) { _, _ in refreshToday() }
        .alert("Couldn't Delete Completion", isPresented: Binding(
            get: { deleteError != nil },
            set: { if !$0 { deleteError = nil } }
        )) {
            Button("OK", role: .cancel) { deleteError = nil }
        } message: {
            Text(deleteError ?? "Please try again.")
        }
    }

    private static func predicate(for date: Date) -> NSPredicate {
        NSPredicate(format: "cal.date == %@ AND aEndTime != nil AND parent != nil", date.getYYMMDD())
    }

    private var orderedCompletions: [Event_Cal] {
        // Clock times after midnight belong after evening times when the day starts later.
        completions.sorted { lhs, rhs in
            let left = lhs.aEndTime ?? ""
            let right = rhs.aEndTime ?? ""
            if left == right {
                return lhs.objectID.uriRepresentation().absoluteString < rhs.objectID.uriRepresentation().absoluteString
            }
            return Date.greaterHHMM(left, right)
        }
    }

    private func refreshToday() {
        let current = MyCalendar.getToday()
        if today != current { today = current }
        let predicate = Self.predicate(for: current)
        if completions.nsPredicate != predicate { completions.nsPredicate = predicate }
    }

    private func delete(_ completion: Event_Cal) {
        // Isolate the save so a failure cannot delete a row or roll back unrelated edits.
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = viewContext.persistentStoreCoordinator
        do {
            let occurrence = try context.existingObject(with: completion.objectID)
            context.delete(occurrence)
            try context.save()
            viewModel.refresh.toggle()
            HapticFeedback.light()
        } catch {
            context.rollback()
            deleteError = error.localizedDescription
        }
    }
}

private struct CompletedEventRow: View {
    @ObservedObject var completion: Event_Cal
    let delete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(completion.parent?.icon ?? "✓")
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(Color.success, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(completion.parent?.name ?? "Event")
                    .font(.headline)
                if let time = completion.aEndTime {
                    Text(Date.getDateFromHHMM(time), format: .dateTime.hour().minute())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let detail = completion.detail, !detail.isEmpty {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            Button(role: .destructive, action: delete) {
                Image(systemName: "trash")
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Delete completion of \(completion.parent?.name ?? "event")")
        }
        .padding(.vertical, 4)
    }
}
