//
//  Section+Ext.swift
//  Ordered
//
//  Created by Kai Hin Hung on 4/1/2025.
//

import Foundation

extension Section {
    
    static func save(name: String?, color: String?, section: Section? = nil) -> Section {
        let sectionToSave = section ?? Section(context: Model.viewContext)
        
        if let n = name{
            sectionToSave.name = n
        }
        if let c = color{
            sectionToSave.color = c
        }
        
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
        section.color = K.defaultSectionColor[0]
        section.name = "New Section"
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
        return section
    }
    
    static func save(name: String? = nil, color: String? = nil, sc: Section_Cal? = nil, cal: Cal? = nil) -> Section_Cal{ //not yet support create
        let scToSave = sc ?? Section_Cal(context: Model.viewContext)
        
        if let n = name{
            scToSave.name = n
        }
        if let c = color{
            scToSave.color = c
        }
        
        if let c = cal{
            let sectionCals = c.section_cals?.mutableCopy() as? NSMutableOrderedSet
            sectionCals?.add(scToSave)
            cal?.section_cals = sectionCals
        }
        
        
        do{
            try Model.viewContext.save()
        }catch{
            print("Error")
        }
        return scToSave
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
