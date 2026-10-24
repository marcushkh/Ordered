import Foundation
import CoreData
import SwiftUI

// UI-only dependencies for the standalone macOS test executable.
enum K { static let categoryColors = ["000000"] }
extension Color {
    init(hex: String?) { self = .gray }
    static var color1: Color { .gray }
}
extension Event {
    var activeCategories: [Category] {
        if let category, category.isActive { return [category] }
        return []
    }
}

@main
struct TabPerformanceTests {
    static func flush(_ context: NSManagedObjectContext) {
        context.processPendingChanges()
        RunLoop.main.run(until: Date().addingTimeInterval(0.03))
    }

    static func main() throws {
        let model = NSManagedObjectModel(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))!
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try coordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil)
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        let today = MyCalendar.getToday()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let todayKey = today.getYYMMDD()
        let yesterdayKey = yesterday.getYYMMDD()
        let day = Cal(context: context); day.date = todayKey
        let oldDay = Cal(context: context); oldDay.date = yesterdayKey
        let a = Event(context: context); a.name = "A"; a.isActive = true; a.order = 0
        let b = Event(context: context); b.name = "B"; b.isActive = true; b.order = 1
        func add(_ event: Event?, _ cal: Cal, _ time: String? = "09:00:00") -> Event_Cal {
            let entry = Event_Cal(context: context)
            entry.parent = event; entry.cal = cal; entry.aEndTime = time
            entry.isOneTime = event == nil
            return entry
        }
        let first = add(a, day)
        _ = add(a, day, "11:00:00")
        let moved = add(b, day)
        _ = add(a, oldDay)
        _ = add(nil, day) // One-time completions count in the chart, not a reusable event.
        _ = add(a, day, nil) // An unfinished plan item must never count.
        try context.save()

        let home = CompletionSnapshotStore()
        home.activate(in: context, day: todayKey)
        precondition(home.snapshot.count(eventID: a.objectID, days: [todayKey]) == 2)
        precondition(home.snapshot.count(days: [todayKey, todayKey]) == 4)
        precondition(home.snapshot.averageTickMinutes(eventID: a.objectID, days: [todayKey]) == 600)
        for _ in 0..<20 { home.deactivate(); home.activate(in: context, day: todayKey) }
        precondition(home.fetchCount == 1, "Unchanged tab revisits must reuse the fetch")

        moved.parent = a
        try context.save(); flush(context)
        precondition(home.snapshot.count(eventID: a.objectID, days: [todayKey]) == 3,
                     "Reassigning a completion must refresh, even when the row count is unchanged")
        precondition(home.snapshot.count(eventID: b.objectID, days: [todayKey]) == 0)
        context.delete(first)
        try context.save(); flush(context)
        precondition(home.snapshot.count(eventID: a.objectID, days: [todayKey]) == 2)

        home.deactivate()
        let fetches = home.fetchCount
        moved.cal = oldDay
        _ = add(b, day)
        try context.save(); flush(context)
        precondition(home.fetchCount == fetches, "Hidden tabs must not rebuild snapshots")
        home.activate(in: context, day: todayKey)
        precondition(home.fetchCount == fetches + 1)
        precondition(home.snapshot.count(eventID: a.objectID, days: [todayKey]) == 1)
        home.activate(in: context, day: yesterdayKey)
        precondition(home.snapshot.count(eventID: a.objectID, days: [yesterdayKey]) == 2,
                     "Changing the day must change the fetch scope")

        let stats = CompletionSnapshotStore()
        stats.activate(in: context)
        let vm = StatViewModel()
        let planner = DayPlannerViewModel()
        let events = [a, b]
        let entries = try context.fetch(Event_Cal.fetchRequest()).filter { $0.aEndTime != nil }
        for range in StatisticRange.allCases {
            vm.range = range
            let rows = vm.rankedStatistics(allEvents: events, completions: stats.snapshot, dayPlannerVM: planner)
            let groups = vm.chartDateGroups(dayPlannerVM: planner)
            for row in rows {
                let expected = groups.map { dates in
                    let days = Set(dates.map { $0.getYYMMDD() })
                    return entries.filter { $0.parent == row.event && days.contains($0.cal?.date ?? "") }.count
                }
                precondition(row.columnCounts == expected)
                precondition(row.total == expected.reduce(0, +))
            }
            let builds = vm.rankingBuildCount
            for _ in 0..<100 {
                _ = vm.rankedStatistics(allEvents: events, completions: stats.snapshot, dayPlannerVM: planner)
            }
            precondition(vm.rankingBuildCount == builds, "Repeated renders must reuse the ranking")
        }
        let builds = vm.rankingBuildCount
        b.isFavourite = true
        let pinnedRows = vm.rankedStatistics(allEvents: events, completions: stats.snapshot, dayPlannerVM: planner)
        precondition(pinnedRows.first?.event == b && vm.rankingBuildCount == builds + 1)
        vm.currentDate = Calendar.current.date(byAdding: .month, value: -1, to: today)!
        precondition(vm.rankedStatistics(allEvents: events, completions: stats.snapshot, dayPlannerVM: planner).allSatisfy { $0.total == 0 })

        // A save from an editor's independent context must invalidate the UI cache.
        let other = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        other.persistentStoreCoordinator = coordinator
        let token = NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave, object: other, queue: nil) {
            context.mergeChanges(fromContextDidSave: $0)
        }
        let newEntry = Event_Cal(context: other)
        newEntry.parent = try other.existingObject(with: a.objectID) as? Event
        newEntry.cal = try other.existingObject(with: day.objectID) as? Cal
        newEntry.aEndTime = "14:00:00"
        let priorCount = stats.snapshot.count(eventID: a.objectID, days: [todayKey])
        try other.save(); flush(context)
        precondition(stats.snapshot.count(eventID: a.objectID, days: [todayKey]) == priorCount + 1)
        NotificationCenter.default.removeObserver(token)

        print("PASS: daily counts, one-time/pending events, edits/deletes, date changes, hidden-tab deferral, unchanged-tab reuse, statistics equivalence, ranking cache, pin/period invalidation, and cross-context merges")
        print("20 unchanged Home revisits: 1 fetch; 100 unchanged Statistics renders per range: 0 ranking rebuilds")
    }
}
