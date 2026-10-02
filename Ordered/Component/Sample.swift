//
//  Sample.swift
//  Ordered
//
//  Created by Kai Hin Hung on 31/7/2024.
//

import Foundation
import CoreData

struct Sample{
    static let sampleEC = {
        let context = PersistenceController.preview.container.viewContext
        let fetchRequest: NSFetchRequest<Event_Cal> = Event_Cal.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        let results = try! context.fetch(fetchRequest)
        return results.first!
    }()
    
    
    static let sampleEvent = {
        let context = PersistenceController.preview.container.viewContext
        let fetchRequest: NSFetchRequest<Event> = Event.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        let results = try! context.fetch(fetchRequest)
        return results.first!
    }()
    
}
