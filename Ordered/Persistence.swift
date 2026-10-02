import CoreData
import Combine

final class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    static let preview = PersistenceController(inMemory: true)

    let container: NSPersistentContainer
    @Published private(set) var isReady = false
    @Published private(set) var loadingError: String?
    private var isLoading = false
    private var loadingWaiters: [CheckedContinuation<Void, Error>] = []

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Ordered")
        if inMemory {
            container.persistentStoreDescriptions.first?.type = NSInMemoryStoreType
        }
        for description in container.persistentStoreDescriptions {
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
            description.shouldAddStoreAsynchronously = true
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        load()
    }

    /// Load the store before presenting views that use its managed objects.
    func load() {
        guard !isLoading else { return }
        isLoading = true
        loadingError = nil
        isReady = false

        if !container.persistentStoreCoordinator.persistentStores.isEmpty {
            finish(error: nil)
            return
        }
        container.loadPersistentStores { [self] _, error in
            finish(error: error)
        }
    }

    /// Shortcuts may run before the app's database has finished opening.
    @MainActor
    func waitUntilReady() async throws {
        if isReady { return }
        if let loadingError {
            throw NSError(domain: "Ordered.Persistence", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: loadingError])
        }
        try await withCheckedThrowingContinuation { continuation in
            loadingWaiters.append(continuation)
        }
    }

    private func finish(error: Error?) {
        DispatchQueue.main.async { [self] in
            isLoading = false
            var error = error
            if error == nil {
                do {
                    try adoptQuickFinishOrder()
                } catch let migrationError {
                    error = migrationError
                }
            }
            loadingError = error?.localizedDescription
            isReady = error == nil
            let waiters = loadingWaiters
            loadingWaiters.removeAll()
            for waiter in waiters {
                if let error { waiter.resume(throwing: error) }
                else { waiter.resume() }
            }
        }
    }
}

extension PersistenceController {
    /// Import Finish Now's previous ordering once, before either page reads the store.
    /// Subsequent edits use only the shared Library order.
    private func adoptQuickFinishOrder() throws {
        let coordinator = container.persistentStoreCoordinator
        let migrationKey = "Ordered.SharedOrderFromQuickFinish.v1"
        for store in coordinator.persistentStores {
            var metadata = coordinator.metadata(for: store)
            guard metadata[migrationKey] as? Bool != true else { continue }

            let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            context.persistentStoreCoordinator = coordinator
            do {
                let categoryRequest: NSFetchRequest<Category> = Category.fetchRequest()
                categoryRequest.affectedStores = [store]
                categoryRequest.predicate = NSPredicate(format: "isActive == true")
                categoryRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Category.order, ascending: true)]
                let categories = legacyQuickFinishSorted(try context.fetch(categoryRequest)) { $0.quickFinishOrder }
                for (index, category) in categories.enumerated() {
                    category.order = Int16(clamping: index)
                    let members = category.events?.array as? [Event] ?? []
                    let active = legacyQuickFinishSorted(members.filter(\.isActive)) { $0.quickFinishOrder }
                    category.events = NSOrderedSet(array: active + members.filter { !$0.isActive })
                }

                // Match the previous fallback order, including favourites and hidden events.
                let eventRequest: NSFetchRequest<Event> = Event.fetchRequest()
                eventRequest.affectedStores = [store]
                eventRequest.predicate = NSPredicate(format: "isActive == true")
                eventRequest.sortDescriptors = [
                    NSSortDescriptor(keyPath: \Event.isFavourite, ascending: false),
                    NSSortDescriptor(keyPath: \Event.order, ascending: true)
                ]
                let uncategorized = try context.fetch(eventRequest).filter { $0.activeCategories.isEmpty }
                let orderedEvents = legacyQuickFinishSorted(uncategorized) { $0.quickFinishOrder }
                for (index, event) in orderedEvents.enumerated() {
                    event.order = Int16(clamping: index)
                }
                try context.save()
                metadata[migrationKey] = true
                coordinator.setMetadata(metadata, for: store)
            } catch {
                context.rollback()
                throw error
            }
        }
    }
}

private func legacyQuickFinishSorted<T>(_ items: [T], order: (T) -> Int64) -> [T] {
    items.enumerated().sorted { lhs, rhs in
        let left = order(lhs.element) < 0 ? Int64.max : order(lhs.element)
        let right = order(rhs.element) < 0 ? Int64.max : order(rhs.element)
        return left == right ? lhs.offset < rhs.offset : left < right
    }.map(\.element)
}
