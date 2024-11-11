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
        let tmp: Int16 = item1.order
        item1.order = item2.order
        item2.order = tmp
        
        do{
            try viewContext.save()
        }catch{
            print("Error")
        }
    }
    
    static func saveEvent(icon: String, name: String, duration: Int, event: Event? = nil) -> Event {
        let eventToSave = event ?? Event(context: viewContext)
        
        eventToSave.icon = icon
        eventToSave.name = name
        eventToSave.duration = Int32(duration)
        
        if event == nil {
            eventToSave.isActive = true
            eventToSave.order = getHighestOrder(c: ModelName.Event) + 1
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
        
        return eventToSave
    }
    
    static func saveSection(name: String, color: String, section: Section? = nil) -> Section{
        let sectionToSave = section ?? Section(context: viewContext)
        
        sectionToSave.name = name
        sectionToSave.color = color
        
        if section == nil{
            sectionToSave.order = getHighestOrder(c: ModelName.Section) + 1
        }
        
        do{
            try viewContext.save()
        }catch{
            print("Error")
        }
        return sectionToSave
    }
    
    static func add(event: Event, to section: Section){
        if let events = section.events?.mutableCopy() as? NSMutableOrderedSet {
            events.add(event)
            section.events = events
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
    
    static func add(event: [Event], to section: Section){
        if let events = section.events?.mutableCopy() as? NSMutableOrderedSet {
            for i in event{
                events.add(i)
            }
            section.events = events
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
    
    static func remove(event: Event, from section: Section){
        //        section.events.re
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
        }
    }
}

enum ModelName{
    case Event, Section
}

protocol OrderedItem {
    var order: Int16 { get set } // You can choose the type (Int, Float, etc.)
}
