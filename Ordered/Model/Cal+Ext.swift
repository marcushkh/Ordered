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
        cal.section_cals = NSOrderedSet()
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
        cal.section_cals = NSOrderedSet()
        var d = date.getYYMMDD()
        cal.date = d
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }

        return cal
    }

    /// New days begin empty; events are added by the user or Quick Finish.
    static func getOrCreate(date: Date) -> Cal {
        get(date: date) ?? new(date: date)
    }

    static func clear(date: Date) {
        let cal = get(date: date)

        print(type(of: cal?.section_cals))

        for i in cal?.section_cals ?? []{
            let i = i as? Section_Cal

            for j in i?.event_cals ?? []{
                let j = j as? Event_Cal
                // Preserve completed events when clearing the plan.
                if j?.aStartTime == nil && j?.aEndTime == nil{
                    Model.viewContext.delete(j!)
                    do {
                        try Model.viewContext.save()
                    } catch {
                        print("Failed to save event: \(error.localizedDescription)")
                    }
                }
            }
            // Preserve sections that still contain completed events.
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

    func addSection(_ section: Section_Cal? = nil, above: Section_Cal? = nil, below: Section_Cal? = nil) -> Section_Cal{
        // Create empty section immediately
        HapticFeedback.light()
        let currentCal = self

        // Calculate insertion index BEFORE removing empty events
        var insertIndex: Int? = nil
        if let sc = above {
            insertIndex = currentCal.section_cals?.index(of: sc)
        } else if let sc = below {
            if let index = currentCal.section_cals?.index(of: sc) {
                insertIndex = index + 1
            }
        }
        let newSection = section ?? Section_Cal.new()

        // Handle insertion position using the pre-calculated index
        if let index = insertIndex {
            if let sections = currentCal.section_cals?.mutableCopy() as? NSMutableOrderedSet {
                if index <= sections.count {
                    sections.insert(newSection, at: index)
                } else {
                    // If index is out of bounds, just append
                    if let section_cals = self.section_cals?.mutableCopy() as? NSMutableOrderedSet {
                        section_cals.add(newSection)
                        self.section_cals = section_cals
                    }
                }
                currentCal.section_cals = sections
            }
        } else {
            if let section_cals = self.section_cals?.mutableCopy() as? NSMutableOrderedSet {
                section_cals.add(newSection)
                self.section_cals = section_cals
            }
        }

        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save empty section: \(error)")
        }

        return newSection
    }

    func addSection(_ section: [Section_Cal]){
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
                guard j.parent != nil else { continue }
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

    func sort(){ // Sort events within each section individually
        print("SORT")
        let sections: [Section_Cal] = self.section_cals?.array as? [Section_Cal] ?? []

        // Sort events within each section separately
        for section in sections {
            var sectionEvents: [Event_Cal] = []

            // Extract events from this section only
            for event in section.event_cals?.array as? [Event_Cal] ?? [] {
                if event.startTime != nil || event.aStartTime != nil {
                    sectionEvents.append(event)
                }
            }

            if sectionEvents.count < 2 { continue }

            var swapList: [[Event_Cal]] = []
            for i in 1..<sectionEvents.count {
                let temp = sectionEvents[i]
                var j = i-1

                while j >= 0 && Date.greaterHHMM(sectionEvents[j].aStartTime ?? sectionEvents[j].startTime!, temp.aStartTime ?? temp.startTime!) {
                    sectionEvents[j+1] = sectionEvents[j]
                    j -= 1
                }
                if j != i-1 {
                    swapList.append([temp, sectionEvents[j+1]])
                }
                sectionEvents[j+1] = temp
            }

            for swapPair in swapList {
                let event1 = swapPair[0]
                let event2 = swapPair[1]

                if let events = section.event_cals?.mutableCopy() as? NSMutableOrderedSet,
                   events.contains(event1) && events.contains(event2) {
                    events.remove(event1)
                    events.insert(event1, at: events.index(of: event2))
                    section.event_cals = events.copy() as? NSOrderedSet
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

                guard ec.parent != nil else { continue }

                let customEvent = CustomEvent(color: sc.parent?.color ?? "", name: ec.parent?.name ?? "", icon: (ec.parent?.icon ?? ""), objectId: ec.objectID.uriRepresentation().absoluteString, duration: Int(ec.duration), startTime: ec.startTime, endTime: ec.endTime, aStartTime: ec.aStartTime, durationFinished: Int(ec.durationFinished))
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
                guard ec.parent != nil else { continue }

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

    func getNextSectionCal(after sectionCal: Section_Cal) -> Section_Cal? {
        let sections = self.section_cals?.array as? [Section_Cal] ?? []
        guard let currentIndex = sections.firstIndex(of: sectionCal) else { return nil }
        let nextIndex = currentIndex + 1
        return nextIndex < sections.count ? sections[nextIndex] : nil
    }

    func removeAllEmptyEvent() {
        let sections = self.section_cals?.array as? [Section_Cal] ?? []

        // Iterate through sections in reverse order to find the last empty event
        for section in sections {
            let events = section.event_cals?.array as? [Event_Cal] ?? []

            for event in events {
                if event.parent == nil && event.startTime == nil {
                    // Remove the movement-detection empty event
                    if let eventCals = section.event_cals?.mutableCopy() as? NSMutableOrderedSet {
                        eventCals.remove(event)
                        section.event_cals = eventCals.copy() as? NSOrderedSet
                    }

                    // Delete the event from Core Data
                    Model.viewContext.delete(event)

                    // If section becomes empty after removing the event, remove the section too
                    if section.event_cals?.count == 0 {
                        if let sectionCals = self.section_cals?.mutableCopy() as? NSMutableOrderedSet {
                            sectionCals.remove(section)
                            self.section_cals = sectionCals.copy() as? NSOrderedSet
                        }
                        Model.viewContext.delete(section)
                    }
                }
            }
        }

        // Save changes
        do {
            try Model.viewContext.save()
            print("Removed last movement-detection empty event")
        } catch {
            print("Failed to save after removing empty event: \(error.localizedDescription)")
        }
    }

    func removeAllEmptyEvents() {
        let sections = self.section_cals?.array as? [Section_Cal] ?? []
        var sectionsToDelete: [Section_Cal] = []

        // Iterate through all sections
        for section in sections {
            let events = section.event_cals?.array as? [Event_Cal] ?? []
            var eventsToDelete: [Event_Cal] = []

            // Find all empty events (both user-created and movement-detection)
            for event in events {
                if event.parent == nil {
                    eventsToDelete.append(event)
                }
            }

            // Remove empty events from the section
            if !eventsToDelete.isEmpty {
                if let eventCals = section.event_cals?.mutableCopy() as? NSMutableOrderedSet {
                    for event in eventsToDelete {
                        eventCals.remove(event)
                        Model.viewContext.delete(event)
                    }
                    section.event_cals = eventCals.copy() as? NSOrderedSet
                }

                // If section becomes empty after removing events, mark it for deletion
                if section.event_cals?.count == 0 {
                    sectionsToDelete.append(section)
                }
            }
        }

        // Remove empty sections
        if !sectionsToDelete.isEmpty {
            if let sectionCals = self.section_cals?.mutableCopy() as? NSMutableOrderedSet {
                for section in sectionsToDelete {
                    sectionCals.remove(section)
                    Model.viewContext.delete(section)
                }
                self.section_cals = sectionCals.copy() as? NSOrderedSet
            }
        }

        // Save changes
        do {
            try Model.viewContext.save()
            print("Removed all empty events (\(sections.flatMap { ($0.event_cals?.array as? [Event_Cal] ?? []).filter { $0.parent == nil } }.count) events)")
        } catch {
                         print("Failed to save after removing all empty events: \(error.localizedDescription)")
         }
     }

    func hasUserCreatedEmptyEventAtBottom() -> Bool {
        let sections = self.section_cals?.array as? [Section_Cal] ?? []

        // Check if there are any sections
        guard !sections.isEmpty else { return false }

        // Get the last section
        let lastSection = sections.last!
        let events = lastSection.event_cals?.array as? [Event_Cal] ?? []

        // Check if there are any events in the last section
        guard !events.isEmpty else { return false }

        // Get the last event in the last section
        let lastEvent = events.last!

        // Check if it's a user-created empty event (no parent AND has startTime)
        return lastEvent.parent == nil && lastEvent.startTime != nil
    }

    func isLastEventOfDay(_ event: Event_Cal) -> Bool {
        // First check if the event has been started (has aStartTime)
        guard event.aStartTime != nil else { return false }

        let sections = self.section_cals?.array as? [Section_Cal] ?? []
        guard !sections.isEmpty else { return false }

        // Find the section containing this event
        guard let eventSection = event.section_cal,
              let sectionIndex = sections.firstIndex(of: eventSection) else { return false }

        let eventsInSection = eventSection.event_cals?.array as? [Event_Cal] ?? []
        guard let eventIndex = eventsInSection.firstIndex(of: event) else { return false }

        // Check all events after this one in the same section
        for i in (eventIndex + 1)..<eventsInSection.count {
            let laterEvent = eventsInSection[i]
            // Skip empty events (events with no parent)
            if laterEvent.parent == nil { continue }
            if laterEvent.aStartTime != nil {
                return false // Found a started event after this one
            }
        }

        // Check all events in all sections after this section
        for i in (sectionIndex + 1)..<sections.count {
            let laterSection = sections[i]
            let laterEvents = laterSection.event_cals?.array as? [Event_Cal] ?? []

            for laterEvent in laterEvents {
                // Skip empty events (events with no parent)
                if laterEvent.parent == nil { continue }
                if laterEvent.aStartTime != nil {
                    return false // Found a started event in a later section
                }
            }
        }

        // No started events found after this one, so this is the last started event
        return true
    }
}
