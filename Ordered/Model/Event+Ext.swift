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
    //Create and get the EC from a Event
    static func getEC(URL: URL) -> Event_Cal?{
        let persistentStoreCoordinator = Model.viewContext.persistentStoreCoordinator
        
        if let objectID = persistentStoreCoordinator?.managedObjectID(forURIRepresentation: URL) {
            do {
                let managedObject = try Model.viewContext.existingObject(with: objectID)
                print("Fetched object: \(managedObject)")
                return managedObject as? Event_Cal
            } catch {
                print("Error fetching object: \(error)")
            }
        } else {
            print("Invalid objectID")
        }
        return nil
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
    
    func delete(){
        Model.viewContext.delete(self)
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
    
}
