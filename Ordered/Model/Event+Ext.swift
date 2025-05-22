//
//  Event+Ext.swift
//  Ordered
//
//  Created by Kai Hin Hung on 4/1/2025.
//
import SwiftUI
import CoreData

extension Event {
        
    static func save(icon: String? = nil, name: String? = nil, startTime: String? = nil, endTime: String? = nil, duration: Int = -1, order_insert_first: Bool = true, event: Event? = nil) -> Event {
        let eventToSave = event ?? Event(context: Model.viewContext)
        
        if let icon = icon{
            eventToSave.icon = icon
        }
        if let name = name{
            eventToSave.name = name
        }
        eventToSave.duration = Int32(duration)
        eventToSave.startTime = startTime
        eventToSave.endTime = endTime
        
        if event == nil {
            eventToSave.isActive = true
            
            let allEvent = fetchEvents(isFavourite: false)
            print(allEvent)
            
            var order: Int16 = 0
            
            if order_insert_first{
                if allEvent.count != 0{
                    order = allEvent[0].order
                }
                for i in allEvent{
                    i.order = i.order + 1
                }
                
            }
            else{
                if allEvent.count != 0{
                    order = allEvent.last?.order ?? 0
                }
            }
            eventToSave.order = order
        }
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
        
        return eventToSave
    }
    
    static func fetchEvents(isFavourite: Bool? = nil) -> [Event] {
        let request: NSFetchRequest<Event> = Event.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Event.isFavourite, ascending: false),
            NSSortDescriptor(keyPath: \Event.order, ascending: true)
        ]
        request.predicate = NSPredicate(format: "isActive == true")
        if let isFavourite = isFavourite {
            request.predicate = NSPredicate(format: "isActive == true AND isFavourite == %@", NSNumber(value: isFavourite))
        }

        do {
            return try Model.viewContext.fetch(request)
        } catch {
            print("Fetch failed: \(error)")
            return []
        }
    }
    
    func toggleIsFavorite() {
        self.isFavourite.toggle()
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
    
    func delete(){
        self.isActive = false
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
    
    func getEC() -> Event_Cal{
        let ec = Event_Cal(context: Model.viewContext)
        ec.duration = self.duration
        ec.startTime = self.startTime
        ec.endTime = self.endTime
        
        ec.parent = self
        return ec
    }
    
    func finished(on date: Date) -> Int{
        let fetchRequest: NSFetchRequest<Event_Cal> = Event_Cal.fetchRequest()
        let datePredicate = NSPredicate(format: "section_cal.cal.date == %@", date.getYYMMDD())
        let parentPredicate = NSPredicate(format: "parent == %@", self)
        let endTimePredicate = NSPredicate(format: "aEndTime != nil")
        
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, parentPredicate, endTimePredicate])
        
        do {
            let events = try Model.viewContext.fetch(fetchRequest)
            return events.count
        } catch {
            print("Failed to fetch events: \(error)")
            return 0
        }
        
    }
    
    func totalTime(on date: Date) -> Int{
        let fetchRequest: NSFetchRequest<Event_Cal> = Event_Cal.fetchRequest()
        let datePredicate = NSPredicate(format: "section_cal.cal.date == %@", date.getYYMMDD())
        let parentPredicate = NSPredicate(format: "parent == %@", self)
        let endTimePredicate = NSPredicate(format: "aEndTime != nil")
        
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, parentPredicate, endTimePredicate])
        
        do {
            let events = try Model.viewContext.fetch(fetchRequest)
            var total = 0
            for event in events{
                total += Int(event.durationFinished)
            }
            return total
        } catch {
            print("Failed to fetch events: \(error)")
            return 0
        }
    }
}

extension Event_Cal{
    //Create and get the EC from a Event
    static func getEC(_ URL: URL) -> Event_Cal?{
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
    
    static func getEC(_ string: String) -> Event_Cal?{
        let persistentStoreCoordinator = Model.viewContext.persistentStoreCoordinator
        
        if let objectID = persistentStoreCoordinator?.managedObjectID(forURIRepresentation: URL(string: string)!) {
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
    
    func edit(detail: String?, startTime: String?, endTime: String?, duration: Int, aStartTime: String? = nil, aEndTime: String? = nil, durationFinished: Int = 0, parent: Event? = nil){
        
        self.detail = detail
        self.startTime = startTime
        self.endTime = endTime
        self.duration = Int32(duration)
        self.aStartTime = aStartTime
        self.aEndTime = aEndTime
        self.durationFinished = Int32(durationFinished)
        if let p = parent{
            self.parent = p
        }
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
    
    func copyFunction() -> Event_Cal?{
        var newEC = self.parent?.getEC()
        newEC?.detail = self.detail
        
        return newEC
    }
    
    func delete(){
        Model.viewContext.delete(self)
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
    
    func createNew() -> Event_Cal{
        let ec = Event_Cal(context: Model.viewContext)
        ec.parent = self.parent
        ec.detail = self.detail
        ec.startTime = self.startTime
        ec.endTime = self.endTime
        ec.duration = self.duration
        ec.durationFinished = self.durationFinished
        ec.aStartTime = self.aStartTime
        ec.aEndTime = self.aEndTime
        
        return ec
    }
}

enum EventStatus: String{
    case TickEvent
    case NotStarted
    case InProgress
    case Paused
    case Completed
    
    static func get(from ec: Event_Cal) -> EventStatus{
        let actionHandler = EventActionHandler.shared
        if ec.aEndTime != nil{
            return .Completed
        }
        if ec.duration == -1 && ec.startTime == nil {
            return .TickEvent
        }
        if actionHandler.isCurrentEC(ec: ec) {
            if actionHandler.startTime != nil{
                return .InProgress
            }
            else{
                return .Paused
            }
        }
        return .NotStarted
    }
}
