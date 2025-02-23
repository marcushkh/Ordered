//
//  Event+Ext.swift
//  Ordered
//
//  Created by Kai Hin Hung on 4/1/2025.
//
import SwiftUI
import CoreData

extension Event {
        
    static func save(icon: String? = nil, name: String? = nil, startTime: String? = nil, endTime: String? = nil, duration: Int = -1, event: Event? = nil) -> Event {
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
            eventToSave.order = Model.getHighestOrder(c: Model.Event) + 1
        }
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
        
        return eventToSave
    }
    
    func toggleIsFavorite() {
        self.isFavourite.toggle()
        
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
    
    func delete(){
        Model.viewContext.delete(self)
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
    
    func toNewSection(colorScheme: ColorScheme) {
        if let s = self.section, let ECindex = s.event_cals?.index(of: self){
            if let weekDefault = s.week_default{
                if var all_s = weekDefault.sections?.array as? [Section], let Sindex = all_s.firstIndex(of: s){
                    
                    if let ecArray = s.event_cals?.array as? [Event_Cal]{
                        let firstHalf = Array(ecArray[..<ECindex])
                        let secondHalf = Array(ecArray[ECindex...])
                        
                        s.event_cals = NSOrderedSet(array: firstHalf)
                        let newS = Section.new(colorScheme: colorScheme, count: all_s.count)
                        newS.event_cals = NSOrderedSet(array: secondHalf)
                        
                        
                        all_s.insert(newS, at: Sindex + 1)
                        
                        weekDefault.sections = NSOrderedSet(array: all_s)
                    }
                }
            }
            
            do {
                try Model.viewContext.save()
            } catch {
                print("Failed to save event: \(error.localizedDescription)")
            }
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
