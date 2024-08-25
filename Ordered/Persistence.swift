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
        
        //Init for preview
        let e1 = Event(context: viewContext)
        e1.duration = -1 //seconds
        e1.icon = "🛏️"
        e1.isActive = true
        e1.name = "Event 1"
        e1.order = 1
        
        let e2 = Event(context: viewContext)
        e2.duration = 1000 //seconds
        e2.icon = "🛏️"
        e2.isActive = true
        e2.name = "Event 2"
        e2.order = 2
        
        let s1 = Section(context: viewContext)
        s1.color = "F5D657"
        s1.name = "Morning Routine"
        s1.events = NSOrderedSet(array: [e1])

        let ec = Event_Cal(context: viewContext)
        ec.parent = e1
        ec.duration = e1.duration
        ec.icon = e1.icon
        ec.name = e1.name
        
        let sc = Section_Cal(context: viewContext)
        sc.parent = s1
        sc.event_cals = NSOrderedSet(array: [ec])
        sc.color = s1.color
        sc.name = s1.name
        
        let cal = Cal(context: viewContext)
        cal.date = MyCalendar.getDate(from: "20240825")
        cal.section_cals = NSOrderedSet(array: [sc])
        cal.theme = "Theme"
        
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
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
