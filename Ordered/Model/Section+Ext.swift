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
        
        var ecs: [Event_Cal] = []
        for ec in self.event_cals?.array as? [Event_Cal] ?? [] {
            ecs.append(ec.createNew())
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
    
    static func new(colorScheme: ColorScheme, name: String? = nil, count: Int = 0) -> Section{
        let section = Section(context: Model.viewContext)
        section.event_cals = NSMutableOrderedSet()
        
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
        for i in self.event_cals ?? []{
            Model.viewContext.delete(i as! NSManagedObject)
        }
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
}

extension Section_Cal {
    
    static func new(count: Int = 0) -> Section_Cal{
        let section = Section_Cal(context: Model.viewContext)
        section.event_cals = NSMutableOrderedSet()
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
        return section
    }
    
    static func save(location: Location?, sc: Section_Cal? = nil, cal: Cal? = nil, insertIndex: Int? = nil){
        // If have sc -> change the sc name and color
        if let scToSave = sc {
            scToSave.location = location
        }
        // If dont have sc -> create a sc and put it at the end of cal
        else{
            let scToSave = Section_Cal(context: Model.viewContext)
            scToSave.location = location
            
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
    
    static func save(location: Location?, sc: Section_Cal? = nil, insertIndex: Int? = nil){
        // If have sc -> change the sc name and color
        if let scToSave = sc {
            scToSave.location = location
        }
        // If dont have sc -> create a sc and put it at the end of cal
        else{
            let scToSave = Section_Cal(context: Model.viewContext)
            scToSave.location = location
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
}
