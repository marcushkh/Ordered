import SwiftUI
import CoreData
import Combine
import UIKit
import LinkPresentation

struct CompletedEventsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var viewModel: ContentViewModel
    @AppStorage("DayStartTime") private var dayStartTime = MyCalendar.defaultDayStartHour
    @State private var today = MyCalendar.getToday()
    @State private var deleteError: String?
    @State private var shareImage: CompletedEventsShareImage?
    @State private var shareError: String?

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Event_Cal.aEndTime, ascending: true)],
        animation: .default
    ) private var completions: FetchedResults<Event_Cal>

    // Also update while the app stays open across the configured day boundary.
    private let clock = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    init(viewModel: ContentViewModel) {
        self.viewModel = viewModel
        _completions = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Event_Cal.aEndTime, ascending: true)],
            predicate: Self.predicate(for: viewModel.viewedDate),
            animation: .default
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(viewModel.viewedDate, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                Spacer()
                Text("\(completions.count) completed")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.horizontal, K.horizontal_padding)
            .padding(.top, 8)
            .padding(.bottom, 8)

            if completions.isEmpty {
                ContentUnavailableView(
                    isViewingToday ? "No Completed Events Today" : "No Completed Events",
                    systemImage: "checkmark.circle",
                    description: Text(isViewingToday
                        ? "Finish an event in Home to see it here."
                        : "No events were completed on this date.")
                )
                .frame(maxHeight: .infinity)
                .padding(.bottom, 80)
            } else {
                ScrollViewReader { proxy in
                List {
                    ForEach(orderedCompletions) { completion in
                        CompletedEventRow(completion: completion, isTutorialTarget: completion.objectID.uriRepresentation().absoluteString == viewModel.tutorial.completionID) {
                            delete(completion)
                        }
                        .id(completion.objectID.uriRepresentation().absoluteString)
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
                .contentMargins(.top, 4, for: .scrollContent)
                .contentMargins(.bottom, 120, for: .scrollContent)
                .ignoresSafeArea(.container, edges: .bottom)
                .onChange(of: viewModel.tutorial.step, initial: true) { _, step in
                    if step == .deleteCompletion, let id = viewModel.tutorial.completionID {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
                }
            }
        }
        .onAppear {
            refreshToday()
            refreshSelection()
        }
        .onChange(of: viewModel.viewedDate) { _, _ in refreshSelection() }
        .onChange(of: completions.count, initial: true) { _, count in
            viewModel.canShareCompletedEvents = count > 0
        }
        .onChange(of: viewModel.completedEventsShareRequest) { _, _ in shareDay() }
        .onReceive(clock) { _ in refreshToday() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refreshToday() }
        }
        .onChange(of: dayStartTime) { _, _ in refreshToday() }
        .sheet(item: $shareImage) { item in
            CompletedEventsShareSheet(image: item.image)
        }
        .alert("Couldn't Create Image", isPresented: Binding(
            get: { shareError != nil },
            set: { if !$0 { shareError = nil } }
        )) {
            Button("OK", role: .cancel) { shareError = nil }
        } message: {
            Text(shareError ?? "Please try again.")
        }
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
        NSPredicate(format: "cal.date == %@ AND aEndTime != nil AND (parent != nil OR isOneTime == true)", date.getYYMMDD())
    }

    private var orderedCompletions: [Event_Cal] {
        // Clock times after midnight belong after evening times when the day starts later.
        completions.sorted { lhs, rhs in
            let left = lhs.aEndTime ?? ""
            let right = rhs.aEndTime ?? ""
            if left == right {
                return lhs.objectID.uriRepresentation().absoluteString < rhs.objectID.uriRepresentation().absoluteString
            }
            return Date.greaterHHMM(right, left)
        }
    }

    private var isViewingToday: Bool {
        Calendar.current.isDate(viewModel.viewedDate, inSameDayAs: today)
    }

    @MainActor
    private func shareDay() {
        let entries = orderedCompletions.map { completion in
            CompletedEventsShareEntry(
                name: completion.displayName,
                icon: completion.displayIcon,
                color: completion.categoryCircleColor,
                time: completion.aEndTime.map { Date.getDateFromHHMM($0).formatted(.dateTime.hour().minute()) },
                detail: completion.detail
            )
        }
        guard !entries.isEmpty else { return }
        // Render every row in a non-scrolling layout, including those off screen.
        let renderer = ImageRenderer(content: CompletedEventsShareCard(date: viewModel.viewedDate, entries: entries)
            .environment(\.colorScheme, .light)
            .environment(\.dynamicTypeSize, .medium))
        renderer.scale = 3
        renderer.isOpaque = true
        guard let image = renderer.uiImage else {
            shareError = "Unable to create the day's image. Please try again."
            return
        }
        shareImage = CompletedEventsShareImage(image: image)
    }

    private func refreshToday() {
        let current = MyCalendar.getToday()
        if today != current {
            if isViewingToday { viewModel.viewedDate = current }
            today = current
        }
    }

    private func refreshSelection() {
        let predicate = Self.predicate(for: viewModel.viewedDate)
        if completions.nsPredicate != predicate { completions.nsPredicate = predicate }
    }

    private func delete(_ completion: Event_Cal) {
        // Isolate the save so a failure cannot delete a row or roll back unrelated edits.
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = viewContext.persistentStoreCoordinator
        do {
            let completionID = completion.objectID.uriRepresentation().absoluteString
            let occurrence = try context.existingObject(with: completion.objectID)
            context.delete(occurrence)
            try context.save()
            viewModel.tutorial.deletedCompletion(id: completionID)
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
    var isTutorialTarget = false
    let delete: () -> Void
    @State private var retainedIcon: String

    init(completion: Event_Cal, isTutorialTarget: Bool = false, delete: @escaping () -> Void) {
        self.completion = completion
        self.isTutorialTarget = isTutorialTarget
        self.delete = delete
        _retainedIcon = State(initialValue: completion.displayIcon)
    }

    var body: some View {
        HStack(spacing: 12) {
            EventCompletionIcon(icon: retainedIcon, eventID: completion.objectID, fontSize: 22)
                .frame(width: 44, height: 44)
                .background(completion.categoryCircleColor, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(completion.displayName)
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
            .showCase(.deleteCompletion, enabled: isTutorialTarget)
            .buttonStyle(.borderless)
            .accessibilityLabel("Delete completion of \(completion.displayName)")
        }
        .padding(.vertical, 4)
        .onChange(of: completion.displayIcon) { _, icon in
            // Deletion clears relationships before the row's removal animation ends.
            // Keep its last real emoji instead of displaying the missing-parent fallback.
            guard !completion.isDeleted, completion.managedObjectContext != nil,
                  completion.isOneTime || completion.parent != nil else { return }
            retainedIcon = icon
        }
    }
}

private struct CompletedEventsShareEntry {
    let name: String
    let icon: String
    let color: Color
    let time: String?
    let detail: String?
}

private extension Event_Cal {
    var categoryCircleColor: Color {
        let categoryColor = isOneTime ? nil : parent?.activeCategories.first?.color
        return Color(hex: categoryColor)
    }
}

private struct CompletedEventsShareImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

private struct CompletedEventsShareSheet: UIViewControllerRepresentable {
    let image: UIImage

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [CompletedEventsShareItem(image: image)], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

private final class CompletedEventsShareItem: NSObject, UIActivityItemSource {
    let image: UIImage

    init(image: UIImage) {
        self.image = image
        super.init()
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        image
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        image
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = "Share Your Day To Others"
        if let appIcon = UIImage(named: "ShareAppIcon") {
            let provider = NSItemProvider(object: appIcon)
            metadata.iconProvider = provider
            metadata.imageProvider = provider
        }
        return metadata
    }
}

private struct CompletedEventsShareCard: View {
    let date: Date
    let entries: [CompletedEventsShareEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Ordered")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.color3)
                Text("My day, completed")
                    .font(.system(size: 28, weight: .bold))
                Text(date, format: .dateTime.weekday(.wide).month(.wide).day().year())
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                Text(entries.count == 1 ? "1 completed event" : "\(entries.count) completed events")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.color3)
            }

            VStack(spacing: 0) {
                ForEach(entries.indices, id: \.self) { index in
                    entryRow(entries[index])
                    if index < entries.count - 1 {
                        Divider().padding(.leading, 58)
                    }
                }
            }
            .padding(.horizontal, 16)
            .background(.white, in: RoundedRectangle(cornerRadius: 20))
        }
        .padding(24)
        .frame(width: 390, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(Color.black)
        .background(Color(red: 0.95, green: 0.96, blue: 0.98))
    }

    private func entryRow(_ entry: CompletedEventsShareEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(entry.icon)
                .font(.system(size: 24))
                .frame(width: 42, height: 42)
                .background(entry.color, in: Circle())
            VStack(alignment: .leading, spacing: 5) {
                Text(entry.name)
                    .font(.system(size: 17, weight: .semibold))
                if let time = entry.time {
                    Text(time)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                if let detail = entry.detail, !detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(detail)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 14)
    }
}
