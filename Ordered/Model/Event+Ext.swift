//
//  Event+Ext.swift
//  Ordered
//
//  Created by Kai Hin Hung on 4/1/2025.
//

extension Event {
    
    static func save(icon: String, name: String, duration: Int, event: Event? = nil) -> Event {
        let eventToSave = event ?? Event(context: Model.viewContext)
        
        eventToSave.icon = icon
        eventToSave.name = name
        eventToSave.duration = Int32(duration)
        
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
        //        ec.startTime = event.startTime
        //        ec.endTime = event.endTime
        
        ec.parent = self
        return ec
    }

}
