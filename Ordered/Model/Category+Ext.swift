import SwiftUI
import CoreData

extension Category {
    /// Library and Finish Now use the category's ordered relationship as their shared event order.
    var orderedActiveEvents: [Event] {
        (events?.array as? [Event] ?? []).filter(\.isActive)
    }

    static func new(colorScheme: ColorScheme, name: String? = nil, icon: String = "🏷️", count: Int = 0) -> Category {
        let category = Category(context: Model.viewContext)
        category.name = name ?? "New Category"
        category.icon = icon
        category.color = colorScheme == .dark
            ? K.categoryColorsDark[count % K.categoryColorsDark.count]
            : K.categoryColors[count % K.categoryColors.count]
        category.order = Int16(count)
        category.isActive = true
        category.events = NSMutableOrderedSet()

        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save category: \(error.localizedDescription)")
        }
        return category
    }

    static func count() -> Int {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == true")
        return (try? Model.viewContext.count(for: request)) ?? 0
    }

    func delete() {
        for event in events?.array as? [Event] ?? [] where event.category == self {
            event.category = nil
        }
        events = NSOrderedSet()
        isActive = false
        try? Model.viewContext.save()
    }
}

