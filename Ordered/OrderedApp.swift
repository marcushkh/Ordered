//
//  OrderedApp.swift
//  Ordered
//
//  Created by Kai Hin Hung on 9/7/2024.
//

import SwiftUI

@main
struct OrderedApp: App {
    let persistenceController = PersistenceController.shared
    
    //To be deleted:
    private var viewContext = PersistenceController.shared.container.viewContext
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .task{
                    //Init for preview
                    let e1 = Event(context: viewContext)
                    e1.duration = -1 //seconds
                    e1.icon = "🛏️"
                    e1.isActive = true
                    e1.name = "Event 1"
                    
                    let s1 = Section(context: viewContext)
                    s1.color = "F5D657"
                    s1.name = "Morning Routine"
                    s1.events = NSOrderedSet(array: [e1])
                    
                    let ec = Event_Cal(context: viewContext)
                    ec.parent = e1
                    
                    let sc = Section_Cal(context: viewContext)
                    sc.parent = s1
                    sc.events = NSOrderedSet(array: [ec])
                    
                    let cal = Cal(context: viewContext)
                    cal.date = Date()
                    cal.sections = NSOrderedSet(array: [sc])
                    cal.theme = "Theme"
                    
                    do{
                        try viewContext.save()
                    }catch{
                        print("Error")
                    }
                }
        }
    }
    
}
