import CoreData

// Pass the compiled previous and current .mom paths. Uses a temporary SQLite store.
@main
struct CategoryDisplayPersistenceTests {
    static func main() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("test.sqlite")

        func open(_ modelPath: String) throws -> (NSPersistentStoreCoordinator, NSManagedObjectContext) {
            let model = NSManagedObjectModel(contentsOf: URL(fileURLWithPath: modelPath))!
            // Test the app's schema without requiring its generated iOS classes on macOS.
            model.entities.forEach { $0.managedObjectClassName = "NSManagedObject" }
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil,
                at: storeURL, options: [NSMigratePersistentStoresAutomaticallyOption: true,
                                       NSInferMappingModelAutomaticallyOption: true])
            let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            context.persistentStoreCoordinator = coordinator
            return (coordinator, context)
        }
        func close(_ coordinator: NSPersistentStoreCoordinator, _ context: NSManagedObjectContext) throws {
            context.reset()
            for store in coordinator.persistentStores { try coordinator.remove(store) }
        }

        let (oldCoordinator, oldContext) = try open(CommandLine.arguments[1])
        let category = NSEntityDescription.insertNewObject(forEntityName: "Category", into: oldContext)
        category.setValue("Work", forKey: "name")
        try oldContext.save()
        let categoryID = category.objectID.uriRepresentation().absoluteString
        try close(oldCoordinator, oldContext)

        let (coordinator, context) = try open(CommandLine.arguments[2])
        let categories = try context.fetch(NSFetchRequest<NSManagedObject>(entityName: "Category"))
        precondition(categories.count == 1 && categories[0].value(forKey: "name") as? String == "Work")
        precondition(categories[0].objectID.uriRepresentation().absoluteString == categoryID)
        let state = NSEntityDescription.insertNewObject(forEntityName: "CategoryDisplayState", into: context)
        precondition(state.value(forKey: "isMinimized") as? Bool == false)
        state.setValue(categoryID, forKey: "groupID")
        state.setValue(true, forKey: "isMinimized")
        if state.entity.attributesByName["hiddenDay"] != nil {
            state.setValue("261010", forKey: "hiddenDay")
        }
        let uncategorized = NSEntityDescription.insertNewObject(forEntityName: "CategoryDisplayState", into: context)
        uncategorized.setValue("uncategorized", forKey: "groupID")
        uncategorized.setValue("261007", forKey: "expandedFinishedDay")
        if uncategorized.entity.attributesByName["visibleDay"] != nil {
            uncategorized.setValue("261010", forKey: "visibleDay")
        }
        try context.save()
        try close(coordinator, context)

        let (reopenedCoordinator, reopenedContext) = try open(CommandLine.arguments[2])
        let states = try reopenedContext.fetch(NSFetchRequest<NSManagedObject>(entityName: "CategoryDisplayState"))
        precondition(states.count == 2)
        let restored = states.first { $0.value(forKey: "groupID") as? String == categoryID }!
        precondition(restored.value(forKey: "isMinimized") as? Bool == true)
        if restored.entity.attributesByName["hiddenDay"] != nil {
            precondition(restored.value(forKey: "hiddenDay") as? String == "261010")
            precondition(restored.value(forKey: "hiddenDay") as? String != "261011")
        }
        let restoredUncategorized = states.first { $0.value(forKey: "groupID") as? String == "uncategorized" }!
        precondition(restoredUncategorized.value(forKey: "expandedFinishedDay") as? String == "261007")
        if restoredUncategorized.entity.attributesByName["visibleDay"] != nil {
            precondition(restoredUncategorized.value(forKey: "visibleDay") as? String == "261010")
            precondition(restoredUncategorized.value(forKey: "visibleDay") as? String != "261011")
        }
        restored.setValue(false, forKey: "isMinimized")
        restored.setValue("261007", forKey: "expandedFinishedDay")
        try reopenedContext.save()
        try close(reopenedCoordinator, reopenedContext)

        let (finalCoordinator, finalContext) = try open(CommandLine.arguments[2])
        let finalStates = try finalContext.fetch(NSFetchRequest<NSManagedObject>(entityName: "CategoryDisplayState"))
        let expanded = finalStates.first { $0.value(forKey: "groupID") as? String == categoryID }!
        precondition(expanded.value(forKey: "isMinimized") as? Bool == false)
        precondition(expanded.value(forKey: "expandedFinishedDay") as? String == "261007")
        try close(finalCoordinator, finalContext)
        print("PASS: migration preserves categories and IDs; minimize and finished-expansion choices survive reopening, including Uncategorized")
    }
}
