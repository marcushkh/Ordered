//
//  Persistence.swift
//  Ordered
//
//  Created by Kai Hin Hung on 9/7/2024.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Ordered")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        let description = container.persistentStoreDescriptions.first
        description?.shouldMigrateStoreAutomatically = true
        description?.shouldInferMappingModelAutomatically = true
        let migrationContext = container.viewContext

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }

            // Event used to support schedules and running timers. Normalize every
            // legacy row before the UI can use it so the app now has one event
            // invariant: an event is either unticked or ticked at one instant.
            Self.convertLegacyEventsToTickEvents(in: migrationContext)
            Self.convertLegacyLocationsToSections(in: migrationContext)
            Self.convertLegacyCategoriesToSingleCategory(in: migrationContext)
            Self.convertLegacySectionEventsToOrderedEntries(in: migrationContext)
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    static func convertLegacyEventsToTickEvents(in context: NSManagedObjectContext) {
        context.performAndWait {
            do {
                let events = try context.fetch(Event.fetchRequest()) as? [Event] ?? []
                let calendarEvents = try context.fetch(Event_Cal.fetchRequest()) as? [Event_Cal] ?? []

                for event in events {
                    event.startTime = nil
                    event.endTime = nil
                    event.duration = -1
                }

                for event in calendarEvents {
                    event.startTime = nil
                    event.endTime = nil
                    event.duration = -1
                    event.durationFinished = 0

                    // Preserve whether a historical event was completed, but
                    // collapse its time range to the single tick timestamp.
                    if event.aEndTime != nil {
                        let tickTime = event.aStartTime ?? event.aEndTime
                        event.aStartTime = tickTime
                        event.aEndTime = tickTime
                    } else if event.aStartTime != nil {
                        event.aEndTime = event.aStartTime
                    }
                }

                if context.hasChanges {
                    try context.save()
                }

                // Discard any timer session left by an older app version.
                let defaults = UserDefaults.standard
                defaults.removeObject(forKey: "timePassed")
                defaults.removeObject(forKey: "startTime")
                defaults.removeObject(forKey: "currentECID")
            } catch {
                // Loading old data should never make the app crash. A later save
                // path also enforces tick-only values for newly touched records.
                print("Failed to convert legacy events to tick events: \(error.localizedDescription)")
            }
        }
    }

    /// Converts the former place-based grouping into reusable sections. The old
    /// entities remain in this model version only so an installed app can open
    /// its existing store, copy the data, and remove every legacy row safely.
    static func convertLegacyLocationsToSections(in context: NSManagedObjectContext) {
        context.performAndWait {
            do {
                let locations = try context.fetch(Location.fetchRequest()) as? [Location] ?? []
                let allSectionCals = try context.fetch(Section_Cal.fetchRequest()) as? [Section_Cal] ?? []
                let existingSections = try context.fetch(Section.fetchRequest()) as? [Section] ?? []

                for section in existingSections {
                    section.isActive = true
                    section.name = section.name ?? section.location?.name ?? "Section"
                    section.icon = section.icon ?? Self.sectionIcon(for: section.location?.imageName)
                    section.color = section.color ?? section.location?.color ?? K.defaultSectionColor[0]

                    if section.events == nil || section.events?.count == 0,
                       let oldEvents = section.location?.events {
                        section.events = oldEvents.mutableCopy() as? NSOrderedSet
                    }
                }

                for (index, location) in locations.sorted(by: { $0.positionOrder < $1.positionOrder }).enumerated() {
                    let linkedSections = location.sections?.allObjects as? [Section] ?? []
                    let target = linkedSections.first ?? Section(context: context)
                    target.name = location.name ?? location.imageName ?? "Section"
                    target.icon = Self.sectionIcon(for: location.imageName)
                    target.color = location.color ?? K.defaultSectionColor[index % K.defaultSectionColor.count]
                    target.order = location.positionOrder
                    target.isActive = true
                    target.events = location.events?.mutableCopy() as? NSOrderedSet ?? NSOrderedSet()

                    for oldSection in linkedSections {
                        oldSection.name = oldSection.name ?? target.name
                        oldSection.icon = oldSection.icon ?? target.icon
                        oldSection.color = oldSection.color ?? target.color
                        oldSection.isActive = true
                        if oldSection.events == nil || oldSection.events?.count == 0 {
                            oldSection.events = target.events
                        }
                    }

                    for sectionCal in allSectionCals where sectionCal.location == location {
                        sectionCal.parent = sectionCal.parent ?? target
                    }
                }

                var activeSections = try context.fetch(Section.fetchRequest()) as? [Section] ?? []
                var fallback = activeSections.first(where: { $0.name == "General" })
                if allSectionCals.contains(where: { $0.parent == nil }) {
                    if fallback == nil {
                        let section = Section(context: context)
                        section.name = "General"
                        section.icon = "📋"
                        section.color = K.defaultSectionColor[0]
                        section.order = Int16(activeSections.count)
                        section.isActive = true
                        section.events = NSOrderedSet()
                        fallback = section
                        activeSections.append(section)
                    }
                    for sectionCal in allSectionCals where sectionCal.parent == nil {
                        sectionCal.parent = fallback
                    }
                }

                for location in locations {
                    if let coordinates = location.coordinates?.allObjects as? [Coordinate] {
                        coordinates.forEach(context.delete)
                    }
                    context.delete(location)
                }

                if context.hasChanges { try context.save() }
            } catch {
                print("Failed to convert legacy locations to sections: \(error.localizedDescription)")
            }
        }
    }

    /// Older builds allowed an event to be connected to several categories.
    /// Keep the first category in the user's visible order and remove the old
    /// multi-category links so the new to-one invariant is always true.
    static func convertLegacyCategoriesToSingleCategory(in context: NSManagedObjectContext) {
        context.performAndWait {
            do {
                let events = try context.fetch(Event.fetchRequest()) as? [Event] ?? []
                for event in events {
                    let legacyCategories = (event.categories?.allObjects as? [Category] ?? [])
                        .filter(\.isActive)
                        .sorted { $0.order < $1.order }
                    event.category = legacyCategories.first ?? event.category
                    event.categories = NSSet()
                }
                if context.hasChanges { try context.save() }
            } catch {
                print("Failed to convert categories to a single selection: \(error.localizedDescription)")
            }
        }
    }

    /// Sections now use ordered Event_Cal template entries. Each entry points
    /// to an Event, which preserves sequences such as Work, Read, Work while
    /// keeping both Work entries tied to the same reusable Event.
    static func convertLegacySectionEventsToOrderedEntries(in context: NSManagedObjectContext) {
        context.performAndWait {
            do {
                let sections = try context.fetch(Section.fetchRequest()) as? [Section] ?? []
                for section in sections where section.event_cals?.count == 0 {
                    let events = section.events?.array as? [Event] ?? []
                    let templates = events.map { event in
                        let template = Event_Cal(context: context)
                        template.parent = event
                        template.section = section
                        template.duration = -1
                        template.startTime = nil
                        template.endTime = nil
                        return template
                    }
                    section.event_cals = NSOrderedSet(array: templates)
                }
                if context.hasChanges { try context.save() }
            } catch {
                print("Failed to convert Section events to ordered entries: \(error.localizedDescription)")
            }
        }
    }

    private static func sectionIcon(for legacyImageName: String?) -> String {
        switch legacyImageName?.lowercased() {
        case "home": return "🏠"
        case "school": return "🎓"
        case "company": return "💼"
        case "cafe": return "☕️"
        case "restaurant": return "🍽️"
        case "park": return "🌳"
        case "gym": return "🏋️"
        case "library": return "📚"
        case "store": return "🛍️"
        default: return "📁"
        }
    }
}
