import CoreData

@main
struct DailyEventVisibilityTests {
    static func main() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("test.sqlite")
        func open(_ path: String) throws -> NSManagedObjectContext {
            let model = NSManagedObjectModel(contentsOf: URL(fileURLWithPath: path))!
            model.entities.forEach { $0.managedObjectClassName = "NSManagedObject" }
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil,
                at: storeURL, options: [NSMigratePersistentStoresAutomaticallyOption: true,
                                       NSInferMappingModelAutomaticallyOption: true])
            let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            context.persistentStoreCoordinator = coordinator
            return context
        }
        func close(_ context: NSManagedObjectContext) throws {
            context.reset()
            let coordinator = context.persistentStoreCoordinator!
            for store in coordinator.persistentStores { try coordinator.remove(store) }
        }
        let old = try open(CommandLine.arguments[1])
        let event = NSEntityDescription.insertNewObject(forEntityName: "Event", into: old)
        event.setValue("Read", forKey: "name")
        event.setValue(true, forKey: "isActive")
        try old.save()
        let id = event.objectID.uriRepresentation()
        try close(old)

        let migrated = try open(CommandLine.arguments[2])
        let request = NSFetchRequest<NSManagedObject>(entityName: "Event")
        let events = try migrated.fetch(request)
        precondition(events.count == 1 && events[0].objectID.uriRepresentation() == id)
        precondition(events[0].value(forKey: "hiddenDay") == nil)
        events[0].setValue("261010", forKey: "hiddenDay")
        try migrated.save()
        try close(migrated)

        let reopened = try open(CommandLine.arguments[2])
        let restored = try reopened.fetch(NSFetchRequest<NSManagedObject>(entityName: "Event"))[0]
        precondition(restored.value(forKey: "name") as? String == "Read")
        precondition(restored.value(forKey: "isActive") as? Bool == true)
        precondition(restored.value(forKey: "hiddenDay") as? String == "261010")
        func visibleCount(on day: String) throws -> Int {
            let request = NSFetchRequest<NSManagedObject>(entityName: "Event")
            request.predicate = NSPredicate(format: "hiddenDay == nil OR hiddenDay != %@", day)
            return try reopened.count(for: request)
        }
        let sameDayCount = try visibleCount(on: "261010")
        let nextDayCount = try visibleCount(on: "261011")
        precondition(sameDayCount == 0)
        precondition(nextDayCount == 1)

        // Restore a hidden event for today without altering saved order preferences.
        restored.setValue(nil, forKey: "hiddenDay")
        restored.setValue("261010", forKey: "visibleDay")
        try reopened.save()
        try close(reopened)

        let overridden = try open(CommandLine.arguments[2])
        let visibleAgain = try overridden.fetch(NSFetchRequest<NSManagedObject>(entityName: "Event"))[0]
        precondition(visibleAgain.value(forKey: "hiddenDay") == nil)
        precondition(visibleAgain.value(forKey: "visibleDay") as? String == "261010")
        precondition(visibleAgain.value(forKey: "visibleDay") as? String != "261011")
        try close(overridden)
        print("PASS: migration, persisted daily hiding, next-day visibility, and persisted same-day restore override")
    }
}
