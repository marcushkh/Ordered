import CoreData

/// A plan can mix reusable Library events and independent one-time occurrences.
enum PlanItem: Identifiable {
    case event(Event)
    case oneTime(Event_Cal)

    var object: NSManagedObject {
        switch self {
        case .event(let event): return event
        case .oneTime(let occurrence): return occurrence
        }
    }
    var id: NSManagedObjectID { object.objectID }
    var name: String { object.value(forKey: "name") as? String ?? "Event" }
    var icon: String { object.value(forKey: "icon") as? String ?? "💡" }
    var order: Int64 {
        get { (object.value(forKey: "planOrder") as? NSNumber)?.int64Value ?? -1 }
        nonmutating set { object.setValue(newValue, forKey: "planOrder") }
    }
}

extension Event_Cal {
    // Completion has always been persisted through aEndTime. Keep a single source of truth.
    var is_finish: Bool { aEndTime != nil }
    var displayName: String { isOneTime ? (name ?? "Event") : (parent?.name ?? "Event") }
    var displayIcon: String { isOneTime ? (icon ?? "💡") : (parent?.icon ?? "✓") }
}

enum PlanStore {
    static func items(in context: NSManagedObjectContext) throws -> [PlanItem] {
        let events: NSFetchRequest<Event> = Event.fetchRequest()
        events.predicate = NSPredicate(format: "isActive == true AND planOrder >= 0")
        let occurrences: NSFetchRequest<Event_Cal> = Event_Cal.fetchRequest()
        occurrences.predicate = NSPredicate(format: "isOneTime == true AND aEndTime == nil AND planOrder >= 0")
        return ordered(try context.fetch(events).map(PlanItem.event)
            + context.fetch(occurrences).map(PlanItem.oneTime))
    }

    static func ordered(_ items: [PlanItem]) -> [PlanItem] {
        items.sorted {
            if $0.order == $1.order { return $0.id.uriRepresentation().absoluteString < $1.id.uriRepresentation().absoluteString }
            return $0.order < $1.order
        }
    }

    static func nextOrder(in context: NSManagedObjectContext) throws -> Int64 {
        (try items(in: context).last?.order ?? -1) + 1
    }

    static func createOneTime(name: String, icon: String, in source: NSManagedObjectContext) throws {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            throw NSError(domain: "Ordered.Plan", code: 1, userInfo: [NSLocalizedDescriptionKey: "Enter an event name."])
        }
        try save(in: source) { context in
            let order = try nextOrder(in: context)
            let occurrence = Event_Cal(context: context)
            occurrence.name = name
            occurrence.icon = icon.isEmpty ? "💡" : icon
            occurrence.isOneTime = true
            occurrence.parent = nil
            occurrence.planOrder = order
            occurrence.duration = -1
            occurrence.aStartTime = nil
            occurrence.aEndTime = nil // is_finish == false
            // No date until completed: unfinished plans survive the day boundary.
        }
    }

    static func move(_ sourceID: NSManagedObjectID, to targetID: NSManagedObjectID, in source: NSManagedObjectContext) throws {
        guard sourceID != targetID else { return }
        try save(in: source) { context in
            var items = try items(in: context)
            guard let from = items.firstIndex(where: { $0.id == sourceID }),
                  let to = items.firstIndex(where: { $0.id == targetID }) else { return }
            let item = items.remove(at: from)
            items.insert(item, at: to)
            for (index, item) in items.enumerated() { item.order = Int64(index) }
        }
    }

    /// Commit the exact order previewed during a drag in a single save.
    static func reorder(_ ids: [NSManagedObjectID], in source: NSManagedObjectContext) throws {
        try save(in: source) { context in
            let items = try items(in: context)
            guard ids.count == items.count, Set(ids) == Set(items.map(\.id)) else {
                throw NSError(domain: "Ordered.Plan", code: 2, userInfo: [
                    NSLocalizedDescriptionKey: "Your plan changed while dragging. Please try again."
                ])
            }
            let positions = Dictionary(uniqueKeysWithValues: ids.enumerated().map { ($0.element, Int64($0.offset)) })
            for item in items { item.order = positions[item.id]! }
        }
    }

    static func clear(in source: NSManagedObjectContext) throws {
        try save(in: source) { context in
            for item in try items(in: context) { remove(item, in: context) }
        }
    }

    static func remove(_ id: NSManagedObjectID, in source: NSManagedObjectContext) throws {
        try save(in: source) { context in
            if let item = try items(in: context).first(where: { $0.id == id }) {
                remove(item, in: context)
            }
        }
    }

    private static func remove(_ item: PlanItem, in context: NSManagedObjectContext) {
        switch item {
        case .event: item.order = -1
        case .oneTime: context.delete(item.object)
        }
    }

    static func finishOneTime(_ id: NSManagedObjectID, in source: NSManagedObjectContext) throws {
        try save(in: source) { context in
            guard let occurrence = try context.existingObject(with: id) as? Event_Cal,
                  occurrence.isOneTime, !occurrence.is_finish, occurrence.planOrder >= 0 else { return }
            let date = MyCalendar.getToday().getYYMMDD()
            let request: NSFetchRequest<Cal> = Cal.fetchRequest()
            request.predicate = NSPredicate(format: "date == %@", date)
            request.fetchLimit = 1
            let cal = try context.fetch(request).first ?? Cal(context: context)
            cal.date = date
            occurrence.cal = cal
            let time = Date.now.getHHMM()
            occurrence.aStartTime = time
            occurrence.aEndTime = time
            occurrence.durationFinished = 0
            occurrence.planOrder = -1
        }
    }

    /// A failed operation must not alter the visible plan or unrelated unsaved changes.
    private static func save(in source: NSManagedObjectContext, changes: (NSManagedObjectContext) throws -> Void) throws {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = source.persistentStoreCoordinator
        do {
            try changes(context)
            guard context.hasChanges else { return }
            try context.obtainPermanentIDs(for: Array(context.insertedObjects))
            let changedIDs: [AnyHashable: Any] = [
                NSInsertedObjectsKey: context.insertedObjects.map(\.objectID),
                NSUpdatedObjectsKey: context.updatedObjects.map(\.objectID),
                NSDeletedObjectsKey: context.deletedObjects.map(\.objectID)
            ]
            try context.save()
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changedIDs, into: [source])
        } catch {
            context.rollback()
            throw error
        }
    }
}
