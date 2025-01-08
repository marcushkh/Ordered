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
}
