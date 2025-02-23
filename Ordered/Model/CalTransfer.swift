//
//  CalTransfer.swift
//  Ordered
//
//  Created by Kai Hin Hung on 5/8/2024.
//

import Foundation

struct CalTransfer{
    private static let viewContext = PersistenceController.shared.container.viewContext
    
    

    
    static func sectionToSC(_ section: Section) -> Section_Cal{
        var arr: [Event_Cal] = []
        
        for i in section.event_cals?.array ?? []{
            arr.append((i as! Event).getEC())
        }
        
        let sc = Section_Cal(context: viewContext)
        sc.color = section.color
        sc.name = section.name
        
        sc.parent = section
        sc.event_cals = NSOrderedSet(array: arr)
        return sc
    }
}
