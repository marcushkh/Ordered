//
//  Event+Ext.swift
//  Ordered
//
//  Created by Kai Hin Hung on 4/1/2025.
//
import SwiftUI
import CoreData

extension Event {
    var activeCategories: [Category] {
        if let category, category.isActive { return [category] }
        return []
    }

    func setCategory(_ selectedCategory: Category?) {
        category = selectedCategory
        // Clear the migration-only relationship after the single selection is
        // established so one event can never retain multiple categories.
        categories = NSSet()
        try? Model.viewContext.save()
    }
        
    static func save(icon: String? = nil, name: String? = nil, startTime: String? = nil, endTime: String? = nil, duration: Int = -1, isFavourite: Bool = false, isActive: Bool = true, order_insert_first: Bool = false, event: Event? = nil) -> Event {
        
        let eventToSave = event ?? Event(context: Model.viewContext)
        
        if let icon{
            eventToSave.icon = icon
        }
        if let name{
            eventToSave.name = name
        }
        // Tick-only invariant. Keep the legacy Core Data fields so old stores can
        // migrate safely, but never write schedule or duration values again.
        eventToSave.duration = -1
        eventToSave.startTime = nil
        eventToSave.endTime = nil
        eventToSave.isFavourite = isFavourite
        eventToSave.isActive = isActive
        
        if event == nil {
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
    
    static func findByName(_ name: String) -> Event? {
        let request: NSFetchRequest<Event> = Event.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@ AND isActive == true", name)
        request.fetchLimit = 1
        
        do {
            let results = try Model.viewContext.fetch(request)
            return results.first
        } catch {
            print("Fetch failed: \(error)")
            return nil
        }
    }
    
    static func findByNameInactive(_ name: String) -> Event? {
        let request: NSFetchRequest<Event> = Event.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@ AND isActive == false", name)
        request.fetchLimit = 1
        
        do {
            let results = try Model.viewContext.fetch(request)
            return results.first
        } catch {
            print("Fetch failed: \(error)")
            return nil
        }
    }
    
    static func findOrCreate(icon: String, name: String, duration: Int = -1, isActive: Bool = true, order_insert_first: Bool = false) -> Event {
        // First, try to find an existing event with the same name
        if let existingEvent = findByName(name) {
            print("Found existing event with name: \(name)")
            return existingEvent
        }
        
        // If no existing event is found, create a new one
        return save(icon: icon, name: name, duration: duration, isActive: isActive, order_insert_first: order_insert_first)
    }
    
    static func findOrCreateInactive(icon: String, name: String, duration: Int = -1, order_insert_first: Bool = false) -> Event{
        // First, try to find an existing event with the same name
        if let existingEvent = findByNameInactive(name) {
            print("Found existing event with name: \(name)")
            return existingEvent
        }
        
        // If no existing event is found, create a new one
        return save(icon: icon, name: name, duration: duration, isActive: false, order_insert_first: order_insert_first)
    }
    
    func toggleIsFavorite() {
        self.isFavourite.toggle()
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
    
    static func getAllFavorite() -> [Event] {
        let request: NSFetchRequest<Event> = Event.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == true AND isFavourite == true")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Event.order, ascending: true)]
        
        do {
            return try Model.viewContext.fetch(request)
        } catch {
            print("Failed to fetch favorite events: \(error)")
            return []
        }
    }
    
    static func count() -> Int {
        let request: NSFetchRequest<Event> = Event.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == true")
        request.sortDescriptors = []
        
        do {
            return try Model.viewContext.fetch(request).count
        } catch {
            print("Failed to fetch favorite events: \(error)")
            return 0
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
        ec.duration = -1
        ec.startTime = nil
        ec.endTime = nil
        
        ec.parent = self
        return ec
    }
    
    func finished(on date: Date) -> Int{
        let fetchRequest: NSFetchRequest<Event_Cal> = Event_Cal.fetchRequest()
        let datePredicate = NSPredicate(format: "cal.date == %@", date.getYYMMDD())
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
        let datePredicate = NSPredicate(format: "cal.date == %@", date.getYYMMDD())
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
    
    static func getEmpty(aStartTime: String? = nil, aEndTime: String? = nil) -> Event_Cal{
        let ec = Event_Cal(context: Model.viewContext)
        ec.duration = -1
        ec.startTime = nil
        ec.endTime = nil
        ec.aStartTime = nil
        ec.aEndTime = nil
        
        return ec
    }
    
    func edit(detail: String?, startTime: String?, endTime: String?, duration: Int, aStartTime: String? = nil, aEndTime: String? = nil, durationFinished: Int = 0, parent: Event? = nil){
        
        self.detail = detail
        self.startTime = nil
        self.endTime = nil
        self.duration = -1
        let tickTime = aStartTime ?? aEndTime
        self.aStartTime = tickTime
        self.aEndTime = tickTime
        self.durationFinished = 0
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
        let newEC = self.parent?.getEC()
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
        ec.startTime = nil
        ec.endTime = nil
        ec.duration = -1
        ec.durationFinished = 0
        if self.aEndTime != nil {
            let tickTime = self.aStartTime ?? self.aEndTime
            ec.aStartTime = tickTime
            ec.aEndTime = tickTime
        }
        
        return ec
    }
}

enum EventStatus: String{
    case TickEvent
    case Completed
    
    static func get(from ec: Event_Cal) -> EventStatus{
        if ec.aEndTime != nil{
            return .Completed
        }
        return .TickEvent
    }
}

extension Event {
    /// Move only the plan occurrence; Library ordering and completion history stay intact.
    func moveInPlan(to target: Event) throws {
        guard let context = managedObjectContext, target.managedObjectContext === context else { return }
        try PlanStore.move(objectID, to: target.objectID, in: context)
    }

    static func clearPlan(in context: NSManagedObjectContext) throws {
        let request: NSFetchRequest<Event> = Event.fetchRequest()
        request.predicate = NSPredicate(format: "planOrder >= 0")
        let events = try context.fetch(request)
        guard !events.isEmpty else { return }
        let previousOrders = events.map { ($0, $0.planOrder) }
        for event in events { event.planOrder = -1 }
        do {
            try context.save()
        } catch {
            for (event, order) in previousOrders { event.planOrder = order }
            throw error
        }
    }

    /// Negative order means the event is not planned. Nonnegative values preserve insertion order.
    func addToPlan() throws {
        guard isActive, planOrder < 0, let context = managedObjectContext else { return }
        let nextOrder = try PlanStore.nextOrder(in: context)
        let previousOrder = planOrder
        planOrder = nextOrder
        do {
            try context.save()
        } catch {
            planOrder = previousOrder
            throw error
        }
    }

    func removeFromPlan() throws {
        guard let context = managedObjectContext else { return }
        let previousOrder = planOrder
        planOrder = -1
        do {
            try context.save()
        } catch {
            planOrder = previousOrder
            throw error
        }
    }
}
