import CoreData
import SwiftUI

// Standalone test support; the app's K also depends on UIKit.
enum K {
    static let categoryColors = ["DCEDFA", "E3BCB5", "F0DCB8", "D2CAF3", "FDFBCC", "E6EEDA"]
    static let categoryColorsDark = ["88C0ED", "C4819B", "D69569", "7854EC", "C1BC63", "819A59"]
}

@main
struct OnboardingCategoryTests {
    static func main() throws {
        let model = NSManagedObjectModel(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))!
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try coordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil)
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        let vm = WelcomeVM()
        precondition(vm.categoryDrafts.map(\.name) == ["Morning", "Work", "Daily Events", "Exercise", "Food"])
        precondition(vm.categoryDrafts.flatMap(\.events).allSatisfy { !$0.isSelected })

        vm.previousCategory()
        precondition(vm.categoryIndex == 0, "Back must stop at the first page")
        vm.categoryDrafts[0].events[0].isSelected = true
        vm.categoryDrafts[0].events[2].isSelected = true
        vm.categoryDrafts[0].events.append(OnboardingEvent(name: "My Morning", icon: "✨", isSelected: true))
        vm.advanceCategory()
        vm.previousCategory()
        precondition(vm.categoryIndex == 0)
        precondition(vm.categoryDrafts[0].events[0].isSelected)
        precondition(vm.categoryDrafts[0].events.last?.name == "My Morning", "Back must retain custom drafts")
        vm.advanceCategory()
        precondition(tryCount("Category", in: context) == 0, "Next must not save categories")
        precondition(tryCount("Event", in: context) == 0, "Next must not save events")
        try vm.saveCategories(in: context, colorScheme: .light)
        precondition(tryCount("Category", in: context) == 0, "Incomplete onboarding must not save")

        vm.categoryDrafts[1].events[0].isSelected = true
        vm.categoryDrafts[1].events[0].isSelected = false
        vm.categoryDrafts[1].events[1].isSelected = true
        while !vm.categoriesComplete { vm.advanceCategory() }
        precondition(tryCount("Category", in: context) == 0, "Even the final category Next must remain a draft")
        vm.previousCategory()
        precondition(vm.categoryIndex == 4 && !vm.categoriesComplete, "Back from privacy returns to Food")
        vm.categoryDrafts[4].events[0].isSelected = true
        vm.categoryDrafts[4].events[0].isSelected = false
        vm.advanceCategory()
        try vm.saveCategories(in: context, colorScheme: .dark)
        let all = try context.fetch(Category.fetchRequest())
        precondition(all.count == 2, "Only categories with selected events should be created")
        let category = all.first { $0.name == "Morning" }!
        precondition(category.icon == "☀️" && category.isActive)
        let events = category.events!.array as! [Event]
        precondition(events.map(\.name) == ["Brush Teeth", "Make the Bed", "My Morning"])
        precondition(events.allSatisfy { $0.category == category && $0.isActive && !$0.isFavourite && $0.duration == -1 })
        let work = all.first { $0.name == "Work" }!
        precondition(work.order > category.order && work.color == K.categoryColorsDark[1])
        precondition((work.events!.array as! [Event]).map(\.name) == ["Focus Time"])
        precondition(tryCount("Event", in: context) == 4)
        precondition(tryCount("Event_Cal", in: context) == 0, "Adding must not record a completion")

        try vm.saveCategories(in: context, colorScheme: .light)
        precondition(tryCount("Category", in: context) == 2, "Repeated finish must not duplicate categories")
        let skipped = WelcomeVM()
        for _ in skipped.categoryDrafts.indices { skipped.advanceCategory() }
        precondition(!skipped.categoriesComplete && skipped.categoryIndex == 4)
        precondition(skipped.showAlert, "An empty setup must explain the minimum requirement")
        do {
            try skipped.saveCategories(in: context, colorScheme: .light)
            preconditionFailure("Empty setup must not save")
        } catch WelcomeVM.SetupError.selectionRequired { }
        precondition(tryCount("Category", in: context) == 2)
        skipped.previousCategory()
        skipped.categoryDrafts[4].events.append(OnboardingEvent(name: "Custom Meal", icon: "🍽️", isSelected: true))
        skipped.advanceCategory()
        skipped.advanceCategory()
        precondition(skipped.categoriesComplete, "One custom event in one category is sufficient")
        skipped.previousCategory()
        skipped.previousCategory()
        skipped.categoryDrafts[4].events.removeLast()
        skipped.advanceCategory()
        skipped.advanceCategory()
        precondition(!skipped.categoriesComplete, "Removing the last selection must block continuation again")
        print("Onboarding category checks passed")
    }

    static func tryCount(_ entity: String, in context: NSManagedObjectContext) -> Int {
        try! context.count(for: NSFetchRequest<NSFetchRequestResult>(entityName: entity))
    }
}
