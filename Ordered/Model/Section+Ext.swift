//
//  Section+Ext.swift
//  Ordered
//
//  Created by Kai Hin Hung on 4/1/2025.
//

import SwiftUI
import CoreData

extension Section {
    func getSC() -> Section_Cal{
        let sc = Section_Cal(context: Model.viewContext)
        let templates = event_cals?.array as? [Event_Cal] ?? []
        let ecs: [Event_Cal]
        if templates.isEmpty {
            // Compatibility for Sections saved before ordered duplicate entries.
            ecs = (events?.array as? [Event] ?? []).map { $0.getEC() }
        } else {
            ecs = templates.compactMap { template in
                guard let event = template.parent else { return nil }
                let copy = event.getEC()
                copy.detail = template.detail
                return copy
            }
        }
        sc.event_cals = NSOrderedSet(array: ecs)
        sc.parent = self
        return sc
    }
    
    static func save(section: Section? = nil, insertIndex: Int? = nil) -> Section{
        // If have sc -> change the sc name and color
        var sectionToSave: Section
        if section != nil {
            sectionToSave = section!
        }
        // If dont have sc -> create a sc and put it at the end of cal
        else{
            sectionToSave = Section(context: Model.viewContext)
        }
        
        do{
            try Model.viewContext.save()
        }catch{
            print("Error")
        }
        return sectionToSave
    }
    
    static func new(colorScheme: ColorScheme, name: String? = nil, icon: String = "📁", count: Int = 0) -> Section{
        let section = Section(context: Model.viewContext)
        section.name = name ?? "New Section"
        section.icon = icon
        section.color = colorScheme == .dark ? K.defaultSectionColorDark[count % K.defaultSectionColorDark.count] : K.defaultSectionColor[count % K.defaultSectionColor.count]
        section.order = Int16(count)
        section.isActive = true
        section.events = NSMutableOrderedSet()
        section.event_cals = NSMutableOrderedSet()
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
        return section
    }

    static func count() -> Int {
        let request: NSFetchRequest<Section> = Section.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == true")
        return (try? Model.viewContext.count(for: request)) ?? 0
    }

    func add(event: Event) {
        let items = events?.mutableCopy() as? NSMutableOrderedSet ?? NSMutableOrderedSet()
        if !items.contains(event) { items.add(event) }
        events = items
        try? Model.viewContext.save()
    }

    func remove(event: Event) {
        let items = events?.mutableCopy() as? NSMutableOrderedSet ?? NSMutableOrderedSet()
        items.remove(event)
        events = items
        try? Model.viewContext.save()
    }
    
    func add(event: Event_Cal){
        if let events = self.event_cals?.mutableCopy() as? NSMutableOrderedSet {
            events.add(event)
            self.event_cals = events
        }
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
    
    func insert(_ event1: Event_Cal, after event2: Event_Cal){
        if let events = self.event_cals?.mutableCopy() as? NSMutableOrderedSet{
            events.insert(event1, at: events.index(of: event2) + 1)
            self.event_cals = events.copy() as? NSOrderedSet
        }
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
    
    func delete(){
        isActive = false
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
}

// Categories are reusable event collections. They intentionally have no
// relationship to Section or Section_Cal, so categorizing an event cannot
// change where that event appears in the planner.
extension Category {
    static func new(colorScheme: ColorScheme, name: String? = nil, icon: String = "🏷️", count: Int = 0) -> Category {
        let category = Category(context: Model.viewContext)
        category.name = name ?? "New Category"
        category.icon = icon
        category.color = colorScheme == .dark
            ? K.defaultSectionColorDark[count % K.defaultSectionColorDark.count]
            : K.defaultSectionColor[count % K.defaultSectionColor.count]
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

extension Section_Cal {
    func get_event_cals_without_started_events() -> [Event_Cal]{
        var ecs = self.event_cals?.array as! [Event_Cal]
        ecs = ecs.filter { $0.aStartTime == nil } //with aStartTime == nil, it is removed
        return ecs
    }
    
    func get_started_event_cals() -> [Event_Cal]{
        var ecs = self.event_cals?.array as! [Event_Cal]
        ecs = ecs.filter { $0.aStartTime != nil } //with aStartTime != nil, it is removed
        return ecs
    }
    
    static func new() -> Section_Cal{
        let section = Section_Cal(context: Model.viewContext)
        section.event_cals = NSMutableOrderedSet()
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
        return section
    }
    
    static func new(section: Section? = nil) -> Section_Cal{
        let sectionCal = Section_Cal(context: Model.viewContext)
        sectionCal.event_cals = NSMutableOrderedSet()
        sectionCal.parent = section
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
        return sectionCal
    }
    
    static func save(section: Section?, sc: Section_Cal? = nil, cal: Cal? = nil, insertIndex: Int? = nil){
        if let scToSave = sc {
            scToSave.parent = section
        }
        else{
            let scToSave = section?.getSC() ?? Section_Cal.new()
            
            if let c = cal{
                let sectionCals = c.section_cals?.mutableCopy() as? NSMutableOrderedSet
                if let i = insertIndex{
                    sectionCals?.insert(scToSave, at: i)
                }
                else{
                    sectionCals?.add(scToSave)
                }
                cal?.section_cals = sectionCals
            }
        }
        
        do{
            try Model.viewContext.save()
        }catch{
            print("Error")
        }
    }
    
    func delete(){
        for i in self.event_cals ?? []{
            Model.viewContext.delete(i as! NSManagedObject)
        }
        Model.viewContext.delete(self)
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
    
    func add(event: Event_Cal){
        if let events = self.event_cals?.mutableCopy() as? NSMutableOrderedSet {
            events.add(event)
            self.event_cals = events
        }
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
    
    func add(event: [Event_Cal]){
        if let events = self.event_cals?.mutableCopy() as? NSMutableOrderedSet {
            for i in event{
                events.add(i)
            }
            self.event_cals = events
        }
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
    
    func insert(_ event1: Event_Cal, after event2: Event_Cal){
        if let events = self.event_cals?.mutableCopy() as? NSMutableOrderedSet{
            events.insert(event1, at: events.index(of: event2) + 1)
            self.event_cals = events.copy() as? NSOrderedSet
        }
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
    
    func insertAtTop(_ event: Event_Cal){
        if let events = self.event_cals?.mutableCopy() as? NSMutableOrderedSet{
            events.insert(event, at: 0)
            self.event_cals = events.copy() as? NSOrderedSet
        }
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
}
