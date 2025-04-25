//
//  Location+Ext.swift
//  Ordered
//
//  Created on current date
//

import Foundation
import CoreData
import SwiftUI

extension Location {
    
    // Create a new Location entity with default values
    static func createNew(in context: NSManagedObjectContext, 
                         name: String = "New Location",
                         posX: Int16 = 500,  // Default position in the center area
                         posY: Int16 = 500) -> Location {
        
        let newLocation = Location(context: context)
        newLocation.name = name
        newLocation.positionX = posX
        newLocation.positionY = posY
        
        // Save the context
        do {
            try context.save()
            print("New location created: \(name)")
            return newLocation
        } catch {
            print("Error saving new location: \(error.localizedDescription)")
            // Handle the error appropriately
            return newLocation
        }
    }
    
    // Update the position of a location
    func updatePosition(posX: Int16, posY: Int16, context: NSManagedObjectContext) {
        self.positionX = posX
        self.positionY = posY
        
        do {
            try context.save()
            print("Updated position for: \(self.name ?? "Unnamed location") to (\(posX), \(posY))")
        } catch {
            print("Error updating location position: \(error.localizedDescription)")
            // Position is updated in memory but not saved to database
        }
    }
    
    // Delete a location entity
    func delete(from context: NSManagedObjectContext) -> Bool {
        let name = self.name ?? "Unnamed location"
        
        // Delete the entity
        context.delete(self)
        
        // Save the context
        do {
            try context.save()
            print("Successfully deleted location: \(name)")
            return true
        } catch {
            print("Error deleting location: \(error.localizedDescription)")
            return false
        }
    }
} 
