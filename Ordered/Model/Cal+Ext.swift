//
//  Cal+Ext.swift
//  Ordered
//
//  Created by Kai Hin Hung on 4/1/2025.
//

import CoreData

extension Cal {
    
    static func exist(date: String) -> Bool{
        let fetchRequest: NSFetchRequest<Cal> = Cal.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@", date)
        
        do {
            let count = try Model.viewContext.count(for: fetchRequest)
            return count > 0
        } catch {
            print("Error checking existence: \(error)")
            return false
        }
    }
    
    static func get(date: String) -> Cal? {
        let fetchRequest: NSFetchRequest<Cal> = Cal.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@", date)
        fetchRequest.fetchLimit = 1
        
        do {
            let result = try Model.viewContext.fetch(fetchRequest)
            return result.first
        } catch {
            print("Error fetching Cal object: \(error)")
            return nil
        }
    }
    
    static func get(date: Date) -> Cal? {
        let fetchRequest: NSFetchRequest<Cal> = Cal.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@", date.getYYMMDD())
        fetchRequest.fetchLimit = 1
        
        do {
            let result = try Model.viewContext.fetch(fetchRequest)
            return result.first
        } catch {
            print("Error fetching Cal object: \(error)")
            return nil
        }
    }
    
    static func new(date: String) -> Cal {
        let cal = Cal(context: Model.viewContext)
        cal.date = date
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
        
        return cal
    }
    
    static func new(date: Date) -> Cal {
        let cal = Cal(context: Model.viewContext)
        var d = date.getYYMMDD()
        cal.date = d
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
        
        return cal
    }
    
    static func clear(date: Date) {
        let cal = get(date: date)
        
        print(type(of: cal?.section_cals))
        
        for i in cal?.section_cals ?? []{
            let i = i as? Section_Cal
            
            for j in i?.event_cals ?? []{
                let j = j as? Event_Cal
                if j?.aStartTime == nil{
                    Model.viewContext.delete(j!)
                    do {
                        try Model.viewContext.save()
                    } catch {
                        print("Failed to save event: \(error.localizedDescription)")
                    }
                }
            }
            if i?.event_cals?.count == 0 {
                Model.viewContext.delete(i!)
            }
        }
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
        
    }
    
    func add(_ section: Section_Cal){
        if let section_cals = self.section_cals?.mutableCopy() as? NSMutableOrderedSet {
            section_cals.add(section)
            self.section_cals = section_cals
        }
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
    
    func add(_ section: [Section_Cal]){
        if let section_cals = self.section_cals?.mutableCopy() as? NSMutableOrderedSet {
            section_cals.add(section)
            self.section_cals = section_cals
        }
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
    
    func getLastFinishedEvent() -> Event_Cal? {
        let sections: [Section_Cal] = self.section_cals?.array as? [Section_Cal] ?? []
        var allEvents: [Event_Cal] = []
        
        //Extract all events from cal
        for i in sections{
            for j in i.event_cals?.array as? [Event_Cal] ?? [] {
                allEvents.append(j)
            }
        }
        
        if allEvents.isEmpty {
            return nil
        }
        
        var e = allEvents.first
        for i in allEvents{
            if i.aStartTime != nil {
                e = i
            }
        }
        return e
    }
    
    func sort(){ // The sorting algorithm we use is to put the incorrectly ordered items on top of the earliest start time which is sorted (insertion sort)
        let sections: [Section_Cal] = self.section_cals?.array as? [Section_Cal] ?? []
        var allEvents: [Event_Cal] = []
        
        //Extract all events from cal
        for i in sections{
            for j in i.event_cals?.array as? [Event_Cal] ?? [] {
                if j.startTime != nil || j.aStartTime != nil{ //Remove all events without startTime
                    allEvents.append(j)
                }
            }
        }
        
        var swapList: [[Event_Cal]] = [] //[[Event 1, Event 2]] => Event 1 to put in front of Event 2
        //Insertion Sort (get all insertion pairs)
        if allEvents.count < 2 {return}
        for i in 1..<allEvents.count{
            let temp = allEvents[i]
            var j = i-1
            
            // allEvents must have startTime or aStartTime
            while j >= 0 && Date.greaterHHMM(allEvents[j].aStartTime ?? allEvents[j].startTime!, temp.aStartTime ?? temp.startTime!) {
                //If in here => need to swap
                allEvents[j+1] = allEvents[j]
                j -= 1
            }
            if j != i-1{
                swapList.append([temp,allEvents[j+1]])
            }
            allEvents[j+1] = temp
        }
        
        // Do the insertion
        for i in swapList{
            let event1 = i[0]
            let event2 = i[1]
            //remove event1 from cal
            for j in sections{
                if let events = j.event_cals?.mutableCopy() as? NSMutableOrderedSet, events.contains(event1) {
                    events.remove(event1)
                    j.event_cals = events.copy() as? NSOrderedSet
                }
            }
            for j in sections{
                if let events = j.event_cals?.mutableCopy() as? NSMutableOrderedSet, events.contains(event2) {
                    events.insert(event1, at: events.index(of: event2))
                    j.event_cals = events.copy() as? NSOrderedSet
                }
            }
        }
        self.section_cals = NSOrderedSet(array: sections)
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
    
    func getCustomEventList() -> [CustomEvent] {
        var customEventList: [CustomEvent] = []
        for sc in self.section_cals?.array as? [Section_Cal] ?? [] {
            for ec in sc.event_cals?.array as? [Event_Cal] ?? [] {
                let customEvent = CustomEvent(color: sc.location?.color ?? "", name: sc.location?.imageName?.capitalizedFirst ?? "", icon: (ec.parent?.icon ?? ""), objectId: ec.objectID.uriRepresentation().absoluteString, duration: Int(ec.duration), startTime: ec.startTime, endTime: ec.endTime, aStartTime: ec.aStartTime, durationFinished: Int(ec.durationFinished))
                customEventList.append(customEvent)
            }
        }
        return customEventList
    }
    
    func getCurrentLocation() -> Int{
        var currentLocation: Int = 0
        var count : Int = 0
        for sc in self.section_cals?.array as? [Section_Cal] ?? [] {
            for ec in sc.event_cals?.array as? [Event_Cal] ?? [] {
                count += 1
                if ec.aStartTime != nil{
                    currentLocation = count
                }
                if ec.aEndTime != nil{
                    currentLocation = count + 1
                }
            }
        }
        
        if currentLocation >= 1{
            return currentLocation - 1
        }
        else{
            return 0
        }
    }
}
