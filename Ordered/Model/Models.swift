//
//  Models.swift
//  Ordered
//
//  Created by Kai Hin Hung on 21/8/2024.
//

import Foundation

struct Models{
    static private var viewContext = PersistenceController.shared.container.viewContext
    
    static func swapOrder<T: OrderedItem>(item1: inout T, item2: inout T){
        var tmp: Int16 = item1.order
        item1.order = item2.order
        item2.order = tmp
        
        do{
            try viewContext.save()
        }catch{
            print("Error")
        }
    }
    
    static func createEvent(icon: String, name: String, duration: Int){ //duration is counted as seconds
        let newEvent = Event(context: viewContext)
        newEvent.icon = icon
        newEvent.name = name
        newEvent.duration = Int32(duration)
        newEvent.isActive = true
        newEvent.order = getHighestOrder(c: ModelName.Event) + 1
        
        do{
            try viewContext.save()
        }catch{
            print("Error")
        }
    }
    
    static func createSection(name: String, color: String){
        let newSection = Section(context: viewContext)
        newSection.name = name
        newSection.color = color
        newSection.order = getHighestOrder(c: ModelName.Section) + 1
        
        do{
            try viewContext.save()
        }catch{
            print("Error")
        }
    }
    
    static func add(event: Event, to section: Section){
        //        section.events.insert(event
    }
    
    static func remove(event: Event, from section: Section){
        //        section.events.re
    }
    
    static func createDay(name: String){
        let newDay = Day(context: viewContext)
        newDay.name = name
        newDay.order =  getHighestOrder(c: ModelName.Day) + 1
        
        do{
            try viewContext.save()
        }catch{
            print("Error")
        }
    }
    
    static func getHighestOrder(c: ModelName) -> Int16 {
        switch(c){
        case .Event:
            do{
                let allItems = try viewContext.fetch(Event.fetchRequest()) as? [Event]
                return allItems?.max { $0.order < $1.order }?.order ?? 1
            }catch{
                fatalError("Unresolved error \(error)")
            }
        case .Section:
            do{
                let allItems = try viewContext.fetch(Section.fetchRequest()) as? [Section]
                return allItems?.max { $0.order < $1.order }?.order ?? 1
            }catch{
                fatalError("Unresolved error \(error)")
            }
        case .Day:
            do{
                let allItems = try viewContext.fetch(Day.fetchRequest()) as? [Day]
                return allItems?.max { $0.order < $1.order }?.order ?? 1
            }catch{
                fatalError("Unresolved error \(error)")
            }
        }
    }
}

enum ModelName{
    case Event, Section, Day
}

protocol OrderedItem {
    var order: Int16 { get set } // You can choose the type (Int, Float, etc.)
}
