//
//  Models.swift
//  Ordered
//
//  Created by Kai Hin Hung on 21/8/2024.
//

import Foundation
import CoreData

enum Model{
    case Event, Section
    
    static var viewContext = PersistenceController.shared.container.viewContext
    
    static func getHighestOrder(c: Model) -> Int16 {
        switch(c){
        case .Event:
            do{
                let allItems = try viewContext.fetch(Ordered.Event.fetchRequest()) as? [Event]
                return allItems?.max { $0.order < $1.order }?.order ?? 1
            }catch{
                fatalError("Unresolved error \(error)")
            }
        case .Section:
            do{
                let allItems = try viewContext.fetch(Ordered.Section.fetchRequest()) as? [Section]
                return allItems?.max { $0.order < $1.order }?.order ?? 1
            }catch{
                fatalError("Unresolved error \(error)")
            }
        }
    }
    
    
    static func swapOrder<T: OrderedItem>(item1: inout T, item2: inout T){
        let tmp: Int16 = item1.order
        item1.order = item2.order
        item2.order = tmp
        
        do{
            try viewContext.save()
        }catch{
            print("Error")
        }
    }
}

protocol OrderedItem {
    var order: Int16 { get set }
}
