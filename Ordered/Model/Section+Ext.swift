//
//  Section+Ext.swift
//  Ordered
//
//  Created by Kai Hin Hung on 4/1/2025.
//

import Foundation

extension Section {
    
    static func save(name: String, color: String, section: Section? = nil) -> Section {
        let sectionToSave = section ?? Section(context: Model.viewContext)
        
        sectionToSave.name = name
        sectionToSave.color = color
        
        if section == nil{
            sectionToSave.order = Model.getHighestOrder(c: Model.Section) + 1
        }
        
        do{
            try Model.viewContext.save()
        }catch{
            print("Error")
        }
        return sectionToSave
    }
    
    func add(event: Event){
        if let events = self.events?.mutableCopy() as? NSMutableOrderedSet {
            events.add(event)
            self.events = events
        }
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
    
    func add(event: [Event]){
        if let events = self.events?.mutableCopy() as? NSMutableOrderedSet {
            for i in event{
                events.add(i)
            }
            self.events = events
        }
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
    
    func remove(event: Event){
        //        section.events.re
    }
}

extension Section_Cal {
    
    static func new() -> Section_Cal{
        let section = Section_Cal(context: Model.viewContext)
        section.event_cals = NSMutableOrderedSet()
        section.color = "f0411c"
        section.name = "new calendar"
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
        return section
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
    
    func remove(event: Event_Cal){
        //        section.events.re
    }
   
    func setColor(_ color: String){
        self.color = color
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
}
