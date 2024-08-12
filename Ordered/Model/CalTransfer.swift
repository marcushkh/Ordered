//
//  CalTransfer.swift
//  Ordered
//
//  Created by Kai Hin Hung on 5/8/2024.
//

import Foundation

struct CalTransfer{
    private static let viewContext = PersistenceController.shared.container.viewContext
    
    static func eventToEC(_ event: Event) -> Event_Cal{
        let ec = Event_Cal(context: viewContext)
        ec.parent = event
        return ec
    }
    
    static func sectionToSC(_ section: Section) -> Section_Cal{
        var arr: [Event_Cal] = []
        
        for i in section.events?.array ?? []{
            arr.append(eventToEC(i as! Event))
        }
        
        let sc = Section_Cal(context: viewContext)
        sc.parent = section
        sc.events = NSOrderedSet(array: arr)
        
        return sc
    }
}
