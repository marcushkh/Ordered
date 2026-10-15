//
//  WelcomeVM.swift
//  Ordered
//
//  Created by Kai Hin Hung on 31/8/2024.
//

import CoreData
import Foundation
import SwiftUI

class WelcomeVM: ObservableObject{
    @Published var categoryIndex = 0
    @Published var categoryDrafts = OnboardingCategory.suggestions

    var categoriesComplete: Bool { categoryIndex >= categoryDrafts.count }

    var hasSelectedCategory: Bool {
        categoryDrafts.contains { $0.events.contains(where: \.isSelected) }
    }

    enum SetupError: LocalizedError {
        case selectionRequired
        var errorDescription: String? {
            "Select at least one event in any category to continue."
        }
    }

    private var hasSavedCategories = false

    func advanceCategory() {
        guard !categoriesComplete else { return }
        if categoryIndex == categoryDrafts.count - 1 && !hasSelectedCategory {
            alertMessage = SetupError.selectionRequired.localizedDescription
            showAlert = true
            return
        }
        categoryIndex += 1
    }

    func previousCategory() {
        guard categoryIndex > 0 else { return }
        categoryIndex -= 1
    }

    /// Persist the entire setup in one transaction only when onboarding finishes.
    /// Failed saves leave all drafts intact and can be retried without partial categories.
    func saveCategories(in viewContext: NSManagedObjectContext, colorScheme: ColorScheme) throws {
        guard !hasSavedCategories else { return }
        guard hasSelectedCategory else { throw SetupError.selectionRequired }
        guard categoriesComplete else { return }
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = viewContext.persistentStoreCoordinator
        do {
            let request: NSFetchRequest<Category> = Category.fetchRequest()
            let categories = try context.fetch(request)
            var nextOrder = (categories.map { Int($0.order) }.max() ?? -1) + 1
            let palette = colorScheme == .dark ? K.categoryColorsDark : K.categoryColors
            for (draftIndex, draft) in categoryDrafts.enumerated() {
                let selected = draft.events.filter(\.isSelected)
                guard !selected.isEmpty else { continue }
                let category = Category(context: context)
                category.name = draft.name
                category.icon = draft.icon
                category.color = palette[draftIndex % palette.count]
                category.order = Int16(clamping: nextOrder)
                nextOrder += 1
                category.isActive = true
                let events = selected.enumerated().map { index, item in
                    let event = Event(context: context)
                    event.name = item.name
                    event.icon = item.icon
                    event.duration = -1
                    event.isActive = true
                    event.isFavourite = false
                    event.order = Int16(clamping: index)
                    event.category = category
                    return event
                }
                category.events = NSOrderedSet(array: events)
            }
            if context.hasChanges { try context.save() }
            hasSavedCategories = true
        } catch {
            context.rollback()
            throw error
        }
    }

    @Published var showAlert = false
    @Published var alertMessage = ""
}

struct OnboardingEvent: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    var isSelected = false
}

struct OnboardingCategory {
    let name: String
    let icon: String
    let question: String
    var events: [OnboardingEvent]

    private static func category(_ name: String, _ icon: String, _ question: String,
                                 _ events: [(String, String)]) -> Self {
        Self(name: name, icon: icon, question: question,
             events: events.map { OnboardingEvent(name: $0.0, icon: $0.1) })
    }

    static let suggestions: [Self] = [
        category("Morning", "☀️", "What do you do in the morning?", [
            ("Brush", "🪥"), ("Water", "💧"), ("Make Bed", "🛏️"),
            ("Shower", "🚿"), ("Meditate", "🧘"), ("Skincare", "🧴"),
            ("Plan the Day", "📝"), ("Target Setting", "🎯")
        ]),
        category("Work", "🧳", "What do you do at work?", [
            ("Check Email", "📧"), ("Plan Tasks", "📋"), ("Focus Time", "🧑🏻‍💻"),
            ("Take a Break", "☕️"), ("Nap", "🥱"),("Review the Day", "✅"),
            ("Study", "📚"),("Assignments", "✍️")
        ]),
        category("Daily Events", "🔥", "What is part of your everyday life?", [
            ("Read", "📖"), ("Journal", "📓"), ("Laundry", "🧺"),
            ("Cleaning", "🧹"), ("Grocery Shop", "🛒"), ("Walk the Dog", "🐕"),
            ("Water Plants", "🪴"), ("Call Family", "📞")
        ]),
        category("Exercise", "🦾", "How do you like to move?", [
            ("Walk", "🚶"), ("Run", "🏃"), ("Stretch", "🙆"),
            ("Gym", "🏋️"), ("Yoga", "🧘"), ("Cycle", "🚴"),
            ("Swim", "🏊"), ("Sports", "🏀")
        ]),
        category("Food", "🍽️", "What are your food routines?", [
            ("Breakfast", "🍳"), ("Lunch", "🥗"), ("Dinner", "🍲"),
            ("Cook", "👨‍🍳"), ("Meal Prep", "🍱"), ("Fruit", "🍎"),
            ("Snack", "🥜"), ("Wash Dishes", "🧽")
        ])
    ]
}
