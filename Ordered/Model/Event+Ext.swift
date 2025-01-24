//
//  Event+Ext.swift
//  Ordered
//
//  Created by Kai Hin Hung on 4/1/2025.
//
import SwiftUI
import CoreData

extension Event {
    
    static func save(icon: String, name: String, startTime: String? = nil, endTime: String? = nil, duration: Int = -1, event: Event? = nil) -> Event {
        let eventToSave = event ?? Event(context: Model.viewContext)
        
        eventToSave.icon = icon
        eventToSave.name = name
        eventToSave.duration = Int32(duration)
        eventToSave.startTime = startTime
        eventToSave.endTime = endTime
        
        if event == nil {
            eventToSave.isActive = true
            eventToSave.order = Model.getHighestOrder(c: Model.Event) + 1
        }
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
        
        return eventToSave
    }
    
    func getEC() -> Event_Cal{
        let ec = Event_Cal(context: Model.viewContext)
        ec.duration = self.duration
        ec.icon = self.icon
        ec.name = self.name
        ec.startTime = self.startTime
        ec.endTime = self.endTime
        
        ec.parent = self
        return ec
    }

}

extension Event_Cal{
    func delete(){
        print("Deleted")
        if let ecs = self.section_cal?.event_cals?.mutableCopy() as? NSMutableOrderedSet {
            ecs.remove(self)
            
            self.section_cal?.event_cals = ecs.copy() as? NSOrderedSet
            
            do {
                try Model.viewContext.save()
            } catch {
                print("Failed to save event: \(error.localizedDescription)")
            }
        }
    }
    
    func edit(name: String, icon: String, startTime: String?, endTime: String?, duration: Int?){
        self.name = name
        self.icon = icon
        self.startTime = startTime
        self.endTime = endTime
        self.duration = Int32(duration ?? -1)
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
}
