import Foundation
import CoreData
import Combine

/// Counts are grouped once when completion data changes, never fetched per tile.
struct CompletionSnapshot {
    struct TickTimes {
        var minutes = 0
        var count = 0
    }

    let identity = UUID()
    var revision = 0
    private(set) var totalsByDay: [String: Int] = [:]
    private(set) var countsByEvent: [NSManagedObjectID: [String: Int]] = [:]
    private(set) var timesByEvent: [NSManagedObjectID: [String: TickTimes]] = [:]

    init(revision: Int = 0, completions: [Event_Cal] = []) {
        self.revision = revision
        for completion in completions {
            guard completion.aEndTime != nil, let day = completion.cal?.date else { continue }
            totalsByDay[day, default: 0] += 1
            guard let eventID = completion.parent?.objectID else { continue }
            countsByEvent[eventID, default: [:]][day, default: 0] += 1
            if let time = completion.aEndTime {
                let parts = time.split(separator: ":").compactMap { Int($0) }
                if parts.count >= 2 {
                    timesByEvent[eventID, default: [:]][day, default: TickTimes()].minutes += parts[0] * 60 + parts[1]
                    timesByEvent[eventID, default: [:]][day, default: TickTimes()].count += 1
                }
            }
        }
    }

    func count(eventID: NSManagedObjectID? = nil, days: [String]) -> Int {
        let counts = eventID.map { countsByEvent[$0] ?? [:] } ?? totalsByDay
        return Set(days).reduce(0) { $0 + (counts[$1] ?? 0) }
    }

    func averageTickMinutes(eventID: NSManagedObjectID, days: [String]) -> Int? {
        let times = timesByEvent[eventID] ?? [:]
        let total = Set(days).reduce(into: TickTimes()) { total, day in
            guard let time = times[day] else { return }
            total.minutes += time.minutes
            total.count += time.count
        }
        return total.count == 0 ? nil : total.minutes / total.count
    }
}

/// Observes the UI context (including merges from other contexts). Hidden tabs
/// only mark their data dirty; they reload once on their next appearance.
final class CompletionSnapshotStore: ObservableObject {
    @Published private(set) var snapshot = CompletionSnapshot()
    @Published private(set) var isLoaded = false
    @Published private(set) var errorMessage: String?
    private var context: NSManagedObjectContext?
    private var observer: AnyCancellable?
    private var day: String?
    private var isActive = false
    private var isDirty = true
    private(set) var fetchCount = 0

    func activate(in context: NSManagedObjectContext, day: String? = nil) {
        precondition(context.concurrencyType == .mainQueueConcurrencyType)
        if self.context !== context {
            self.context = context
            isDirty = true
            observer = NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: context)
                .sink { [weak self] notification in
                    guard Self.affectsCompletions(notification) else { return }
                    self?.isDirty = true
                    // Coalesce related insert/update/merge notifications.
                    DispatchQueue.main.async { [weak self] in self?.reloadIfNeeded() }
                }
        }
        if self.day != day {
            self.day = day
            isDirty = true
        }
        isActive = true
        reloadIfNeeded()
    }

    func deactivate() { isActive = false }
    func clearError() { errorMessage = nil }

    private func reloadIfNeeded() {
        guard isActive, isDirty, let context else { return }
        let request: NSFetchRequest<Event_Cal> = Event_Cal.fetchRequest()
        var predicates = [NSPredicate(format: "aEndTime != nil")]
        if let day { predicates.append(NSPredicate(format: "cal.date == %@", day)) }
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.relationshipKeyPathsForPrefetching = ["cal", "parent"]
        request.returnsObjectsAsFaults = false
        do {
            let completions = try context.fetch(request)
            fetchCount += 1
            snapshot = CompletionSnapshot(revision: snapshot.revision + 1, completions: completions)
            isDirty = false
            isLoaded = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private static func affectsCompletions(_ notification: Notification) -> Bool {
        if notification.userInfo?[NSInvalidatedAllObjectsKey] != nil { return true }
        return [NSInsertedObjectsKey, NSUpdatedObjectsKey, NSDeletedObjectsKey,
                NSRefreshedObjectsKey, NSInvalidatedObjectsKey].contains { key in
            let objects = notification.userInfo?[key] as? Set<NSManagedObject> ?? []
            return objects.contains { $0 is Event_Cal || $0 is Cal }
        }
    }
}
