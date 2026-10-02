import AppIntents
import CoreData

struct OrderedEventEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Event"
    static var defaultQuery = OrderedEventQuery()

    let id: String
    let name: String
    let icon: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(icon) \(name)")
    }

    init(event: Event) {
        id = event.objectID.uriRepresentation().absoluteString
        name = event.name ?? "Event"
        icon = event.icon ?? "✓"
    }
}

struct OrderedEventQuery: EntityStringQuery {
    @MainActor
    func entities(for identifiers: [String]) async throws -> [OrderedEventEntity] {
        try await PersistenceController.shared.waitUntilReady()
        let context = Model.viewContext
        return try identifiers.compactMap { identifier in
            guard let url = URL(string: identifier),
                  let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url),
                  let event = try context.existingObject(with: objectID) as? Event,
                  event.isActive, !event.isDeleted else { return nil }
            return OrderedEventEntity(event: event)
        }
    }

    @MainActor
    func suggestedEntities() async throws -> [OrderedEventEntity] {
        try await PersistenceController.shared.waitUntilReady()
        return try events(matching: nil)
    }

    @MainActor
    func entities(matching string: String) async throws -> [OrderedEventEntity] {
        try await PersistenceController.shared.waitUntilReady()
        return try events(matching: string)
    }

    @MainActor
    private func events(matching search: String?) throws -> [OrderedEventEntity] {
        let request: NSFetchRequest<Event> = Event.fetchRequest()
        if let search, !search.isEmpty {
            request.predicate = NSPredicate(format: "isActive == YES AND name CONTAINS[cd] %@", search)
        } else {
            request.predicate = NSPredicate(format: "isActive == YES")
        }
        request.sortDescriptors = [
            NSSortDescriptor(key: "isFavourite", ascending: false),
            NSSortDescriptor(key: "order", ascending: true),
            NSSortDescriptor(key: "name", ascending: true)
        ]
        let events = try Model.viewContext.fetch(request)
        try Model.viewContext.obtainPermanentIDs(for: events.filter { $0.objectID.isTemporaryID })
        return events.map { OrderedEventEntity(event: $0) }
    }
}

struct QuickFinishEventIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Finish Event"
    static var description = IntentDescription("Record one completion of the selected event for today, just like Quick Finish. Each run records a new completion.")
    static var openAppWhenRun = false

    @Parameter(title: "Event")
    var event: OrderedEventEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Quick finish \(\.$event)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        try await PersistenceController.shared.waitUntilReady()
        let context = Model.viewContext
        guard let url = URL(string: event.id),
              let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url),
              let selectedEvent = try context.existingObject(with: objectID) as? Event,
              selectedEvent.isActive, !selectedEvent.isDeleted else {
            throw QuickFinishIntentError.eventUnavailable
        }
        try EventActionHandler.shared.quickFinish(selectedEvent, on: MyCalendar.getToday())
        return .result()
    }
}

private enum QuickFinishIntentError: LocalizedError {
    case eventUnavailable

    var errorDescription: String? {
        "This event is no longer available. Choose another event in the shortcut."
    }
}

struct OrderedShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: QuickFinishEventIntent(),
            phrases: ["Quick finish an event in \(.applicationName)"],
            shortTitle: "Quick Finish Event",
            systemImageName: "checkmark.circle"
        )
    }
}
