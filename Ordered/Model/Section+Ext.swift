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
        sc.color = self.color
        sc.name = self.name
        sc.event_cals = self.event_cals
        sc.parent = self
        return sc
    }
    
    static func save(name: String? = nil, color: String? = nil, section: Section? = nil, wd: WeekDefault? = nil, insertIndex: Int? = nil){
        // If have sc -> change the sc name and color
        if let sectionToSave = section {
            if let n = name{
                sectionToSave.name = n
            }
            if let c = color{
                sectionToSave.color = c
            }
        }
        // If dont have sc -> create a sc and put it at the end of cal
        else{
            let sectionToSave = Section(context: Model.viewContext)
            if let n = name{
                sectionToSave.name = n
            }
            if let c = color{
                sectionToSave.color = c
            }
            if let w = wd{
                let sections = w.sections?.mutableCopy() as? NSMutableOrderedSet
                if let i = insertIndex{
                    sections?.insert(sectionToSave, at: i)
                }
                else{
                    sections?.add(sectionToSave)
                }
                wd?.sections = sections
            }
        }
        
        do{
            try Model.viewContext.save()
        }catch{
            print("Error")
        }
    }
    
    static func new(colorScheme: ColorScheme, name: String? = nil, count: Int = 0) -> Section{
        let section = Section(context: Model.viewContext)
        section.event_cals = NSMutableOrderedSet()
        section.color = colorScheme == .light ? K.defaultSectionColor[count % K.defaultSectionColor.count] : K.defaultSectionColorDark[count % K.defaultSectionColorDark.count]
        section.name = name ?? "New Section"
        
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
        Model.viewContext.delete(self)
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
}

extension Section_Cal {
    
    static func new(colorScheme: ColorScheme, name: String? = nil, count: Int = 0) -> Section_Cal{
        let section = Section_Cal(context: Model.viewContext)
        section.event_cals = NSMutableOrderedSet()
        section.color = colorScheme == .light ? K.defaultSectionColor[count % K.defaultSectionColor.count] : K.defaultSectionColorDark[count % K.defaultSectionColorDark.count]
        section.name = name ?? "New Section"
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
        return section
    }
    
    static func save(name: String? = nil, color: String? = nil, sc: Section_Cal? = nil, cal: Cal? = nil, insertIndex: Int? = nil){
        // If have sc -> change the sc name and color
        if let scToSave = sc {
            if let n = name{
                scToSave.name = n
            }
            if let c = color{
                scToSave.color = c
            }
        }
        // If dont have sc -> create a sc and put it at the end of cal
        else{
            let scToSave = Section_Cal(context: Model.viewContext)
            if let n = name{
                scToSave.name = n
            }
            if let c = color{
                scToSave.color = c
            }
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
    
    static func save(name: String? = nil, color: String? = nil, sc: Section_Cal? = nil, wd: WeekDefault? = nil, insertIndex: Int? = nil){
        // If have sc -> change the sc name and color
        if let scToSave = sc {
            if let n = name{
                scToSave.name = n
            }
            if let c = color{
                scToSave.color = c
            }
        }
        // If dont have sc -> create a sc and put it at the end of cal
        else{
            let scToSave = Section_Cal(context: Model.viewContext)
            if let n = name{
                scToSave.name = n
            }
            if let c = color{
                scToSave.color = c
            }
            if let w = wd{
                let sections = w.sections?.mutableCopy() as? NSMutableOrderedSet
                if let i = insertIndex{
                    sections?.insert(scToSave, at: i)
                }
                else{
                    sections?.add(scToSave)
                }
                wd?.sections = sections
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
    
    func setColor(_ color: String){
        self.color = color
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
}
