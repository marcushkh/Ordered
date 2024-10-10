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
        e1.startTime = "20:14"
        
        let e2 = Event(context: viewContext)
        e2.duration = 1000 //seconds
        e2.icon = "😎"
        e2.isActive = true
        e2.name = "Event 2"
        e2.order = 2
        
        let s1 = Section(context: viewContext)
        s1.color = "F5D657"
        s1.name = K.defaultSection[0]
        s1.events = NSOrderedSet(array: [e1])
        
        let s2 = Section(context: viewContext)
        s2.color = "57B2BF"
        s2.name = K.defaultSection[1]
        s2.events = NSOrderedSet(array: [e2])
        
        let s3 = Section(context: viewContext)
        s3.color = "F59057"
        s3.name = K.defaultSection[2]
        s3.events = NSOrderedSet(array: [e2])
        
        let s4 = Section(context: viewContext)
        s4.color = "8057F5"
        s4.name = K.defaultSection[3]
        s4.events = NSOrderedSet(array: [e1])

        let ec = Event_Cal(context: viewContext)
        ec.parent = e1
        ec.duration = e1.duration
        ec.icon = e1.icon
        ec.name = e1.name
        
        let ec2 = Event_Cal(context: viewContext)
        ec2.parent = e2
        ec2.duration = e2.duration
        ec2.icon = e2.icon
        ec2.name = e2.name
        
        let sc = Section_Cal(context: viewContext)
        sc.parent = s1
        sc.event_cals = NSOrderedSet(array: [ec])
        sc.color = s1.color
        sc.name = s1.name
        
        let sc2 = Section_Cal(context: viewContext)
        sc2.parent = s1
        sc2.event_cals = NSOrderedSet(array: [ec2])
        sc2.color = s1.color
        sc2.name = s1.name
        
        let cal = Cal(context: viewContext)
        cal.date = MyCalendar.getDate(from: "20240823")
        cal.section_cals = NSOrderedSet(array: [sc])
        cal.theme = "Theme"
        
        let cal2 = Cal(context: viewContext)
        cal2.date = MyCalendar.getDate(from: "20240824")
        cal2.section_cals = NSOrderedSet(array: [sc2])
        cal2.theme = "Theme"
        
        let cal3 = Cal(context: viewContext)
        cal3.date = MyCalendar.getDate(from: "20240825")
        cal3.section_cals = NSOrderedSet(array: [sc])
        cal3.theme = "Theme"
        
        let cal4 = Cal(context: viewContext)
        cal4.date = MyCalendar.getDate(from: "20240826")
        cal4.section_cals = NSOrderedSet(array: [sc2])
        cal4.theme = "Theme"
        
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
