//
//  Week.swift
//  Ordered
//
//  Created by Kai Hin Hung on 20/2/2025.
//
import CoreData
import SwiftUI

extension WeekDefault{
    static func get(_ weekAb: Int) -> WeekDefault?{
        let fetchRequest: NSFetchRequest<WeekDefault> = WeekDefault.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "weekAb == %d", weekAb)
        
        do {
            let weekDefault = try Model.viewContext.fetch(fetchRequest)
            return weekDefault.first
        } catch {
            print("Failed to fetch events: \(error)")
            return nil
        }
    }
    
    static func exist(date: Date) -> Bool{
        let fetchRequest: NSFetchRequest<WeekDefault> = WeekDefault.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "weekAb == %d", date.getWeekInt())
        print(date)
        
        do {
            let wd = try Model.viewContext.fetch(fetchRequest)
            let count = wd.first?.sections?.count ?? 0
            return count > 0
        } catch {
            print("Error checking existence: \(error)")
            return false
        }
    }
    
    static func new(_ weekInt: Int) -> WeekDefault {
        let wd = WeekDefault(context: Model.viewContext)
        wd.weekAb = Int16(weekInt % 7)
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
        
        return wd
    }
    
    func add(_ section: Section){
        if let sections = self.sections?.mutableCopy() as? NSMutableOrderedSet {
            sections.add(section)
            self.sections = sections
        }
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
    
    func sort(){ // The sorting algorithm we use is to put the incorrectly ordered items on top of the earliest start time which is sorted (insertion sort)
        let sections: [Section] = self.sections?.array as? [Section] ?? []
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
            while j >= 0 && Date.greaterHHMM(allEvents[j].aStartTime ?? allEvents[j].startTime!, temp.aStartTime ?? temp.startTime!){
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
        self.sections = NSOrderedSet(array: sections)
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
    
    func delete(){
        self.sections = nil
        
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
    
    func getLastFinishedEvent() -> Event_Cal? {
        let sections: [Section] = self.sections?.array as? [Section] ?? []
        return sections.last?.event_cals?.lastObject as? Event_Cal ?? nil
    }
}
