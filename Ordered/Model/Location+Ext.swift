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
    
    // Available image names for locations
    static let availableImages = [
        "home", "school", "company", "cafe", "restaurant", "park", 
        "gym", "library", "store"
    ]
    
    // Define specific allowed placement positions (just 3 positions)
    static let allowedPositions: [CGPoint] = [
        CGPoint(x: 100, y: 100),  // Top-left position
        CGPoint(x: 300, y: 300),  // Middle position
        CGPoint(x: 500, y: 500)   // Bottom-right position
    ]
    
    // Check if a position is already occupied
    static func isPositionOccupied(at point: CGPoint, context: NSManagedObjectContext, excludingObjectID: NSManagedObjectID? = nil) -> Bool {
        let request: NSFetchRequest<Location> = Location.fetchRequest()
        
        do {
            let locations = try context.fetch(request)
            return locations.contains { location in
                // Skip if this is the location we're currently editing
                if let excludingID = excludingObjectID, location.objectID == excludingID {
                    return false
                }
                
                // Check if the position matches
                let locationPoint = CGPoint(x: CGFloat(location.positionX), y: CGFloat(location.positionY))
                return locationPoint == point
            }
        } catch {
            print("Error checking position occupation: \(error)")
            return false
        }
    }
    
    // Find nearest available allowed position
    static func nearestAvailableAllowedPosition(to point: CGPoint, context: NSManagedObjectContext, excludingObjectID: NSManagedObjectID? = nil) -> CGPoint? {
        // Sort positions by distance from the input point
        let sortedPositions = allowedPositions.sorted { posA, posB in
            distance(point, posA) < distance(point, posB)
        }
        
        // Return the first unoccupied position
        for position in sortedPositions {
            if !isPositionOccupied(at: position, context: context, excludingObjectID: excludingObjectID) {
                return position
            }
        }
        
        // If all positions are occupied, return nil
        return nil
    }
    
    // Find nearest allowed position
    static func nearestAllowedPosition(to point: CGPoint) -> CGPoint {
        guard !allowedPositions.isEmpty else { return point }
        
        // Find the closest allowed position
        var closestPoint = allowedPositions[0]
        var minDistance: CGFloat = distance(point, allowedPositions[0])
        
        for allowedPoint in allowedPositions {
            let currentDistance = distance(point, allowedPoint)
            if currentDistance < minDistance {
                minDistance = currentDistance
                closestPoint = allowedPoint
            }
        }
        
        return closestPoint
    }
    
    // Calculate distance between two points
    private static func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let xDist = a.x - b.x
        let yDist = a.y - b.y
        return sqrt(xDist * xDist + yDist * yDist)
    }
    
    // Create a new Location entity with default values
    static func createNew(in context: NSManagedObjectContext, 
                         imageName: String = "home",
                         posX: Int16 = 500,  // Default position in the center area
                         posY: Int16 = 500) -> Location? {
        
        // Try to find an available allowed position
        guard let availablePosition = nearestAvailableAllowedPosition(
            to: CGPoint(x: CGFloat(posX), y: CGFloat(posY)),
            context: context
        ) else {
            print("Cannot create location: all allowed positions are occupied")
            return nil
        }
        
        let newLocation = Location(context: context)
        newLocation.imageName = imageName
        newLocation.positionX = Int16(availablePosition.x)
        newLocation.positionY = Int16(availablePosition.y)
        
        // Save the context
        do {
            try context.save()
            print("New location created with image: \(imageName) at position (\(availablePosition.x), \(availablePosition.y))")
            return newLocation
        } catch {
            print("Error saving new location: \(error.localizedDescription)")
            // Handle the error appropriately
            return newLocation
        }
    }
    
    // Update the position of a location
    func updatePosition(posX: Int16, posY: Int16, context: NSManagedObjectContext) -> Bool {
        // Try to find an available allowed position
        guard let availablePosition = Location.nearestAvailableAllowedPosition(
            to: CGPoint(x: CGFloat(posX), y: CGFloat(posY)),
            context: context,
            excludingObjectID: self.objectID
        ) else {
            print("Cannot update location: all other allowed positions are occupied")
            return false
        }
        
        self.positionX = Int16(availablePosition.x)
        self.positionY = Int16(availablePosition.y)
        
        do {
            try context.save()
            print("Updated location position to allowed position (\(availablePosition.x), \(availablePosition.y))")
            return true
        } catch {
            print("Error updating location position: \(error.localizedDescription)")
            return false
        }
    }
    
    // Delete a location entity
    func delete(from context: NSManagedObjectContext) -> Bool {
        // Delete the entity
        context.delete(self)
        
        // Save the context
        do {
            try context.save()
            print("Successfully deleted location")
            return true
        } catch {
            print("Error deleting location: \(error.localizedDescription)")
            return false
        }
    }
} 
