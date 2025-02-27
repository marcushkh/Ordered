//
//  Models.swift
//  Ordered
//
//  Created by Kai Hin Hung on 21/8/2024.
//

import Foundation
import CoreData

enum Model{
    static var viewContext = PersistenceController.shared.container.viewContext
    
    case Event_, Section_
    
    static func getHighestOrder(c: Model) -> Int16 {
        switch(c){
        case .Event_:
            do{
                let allItems = try viewContext.fetch(Event.fetchRequest()) as? [Event]
                return allItems?.max { $0.order < $1.order }?.order ?? 1
            }catch{
                fatalError("Unresolved error \(error)")
            }
        case .Section_:
            do{
                let allItems = try viewContext.fetch(Section.fetchRequest()) as? [Section]
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
    
    static func duration_to_string(min duration: Int32) -> String{
        var ans = ""
        if duration/60 == 1{
            ans += String(format: "1 hr ")
        }
        else if duration/60 >= 2{
            ans += String(format: "%d hrs ", duration / 60)
        }
        
        if duration%60 == 1{
            ans += String(format: "1 min")
        }
        else if duration % 60 >= 2 {
            ans += String(format: "%d mins", duration%60)
        }
        else{
            if ans.isEmpty {
                ans = "0 mins"
            }
        }
        
        return ans
    }
    
    static func duration_to_HHmmss(sec duration: Int32) -> String{
        var ans = ""
        var d = duration
        if d/3600 >= 1{
            //Have hour
            ans = String(format: "%2d:", duration/3600)
            d = d%3600
        }
        ans = ans + String(format: "%02d:%02d", d/60, d%60)
        return ans
    }
}

protocol OrderedItem {
    var order: Int16 { get set }
}
