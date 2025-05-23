//
//  Location+Ext.swift
//  Ordered
//
//  Created on current date
//

import Foundation
import CoreData
import SwiftUI

// Location type enum with associated default colors
enum LocationType: String, CaseIterable {
    case home = "Home"
    case school = "School"
    case company = "Company"
    case cafe = "Cafe"
    case restaurant = "Restaurant"
    case park = "Park"
    case gym = "Gym"
    case library = "Library"
    case store = "Store"
    
    // Get LocationType from image name
    static func from(_ imageName: String) -> LocationType? {
        return LocationType(rawValue: imageName)
    }
    
    var defaultColor: Int {
        switch self {
        case .home:
            return 2
        case .school:
            return 1
        case .company:
            return 0
        case .cafe:
            return 3
        case .restaurant:
            return 3
        case .park:
            return 5
        case .gym:
            return 1
        case .library:
            return 4
        case .store:
            return 5
        }
    }
    
    var defaultEvents: [TempEvent]{
        switch self {
        case .home:
            return [
                TempEvent(name: "Brush", icon: "🪥"),
                TempEvent(name: "Make Coffee", icon: "☕️", duration: 10),
                TempEvent(name: "Meditation", icon: "🧘‍♀️", duration: 5),
                TempEvent(name: "Exercise", icon: "🏃‍♂️", duration: 15),
                TempEvent(name: "Shower", icon: "🚿", duration: 15),
                TempEvent(name: "Skin Care", icon: "💆‍♀️", duration: 10),
                TempEvent(name: "Clean Room", icon: "🧹"),
                TempEvent(name: "Reading", icon: "📖", duration: 30)
            ]
        case .school:
            return [
                TempEvent(name: "School Work", icon: "👩‍🏫", duration: 30),
                TempEvent(name: "Assignments", icon: "📚", duration: 30)
            ]
        case .company:
            return [
                TempEvent(name: "Work Hours", icon: "💼", duration: 180),
                TempEvent(name: "Overtime", icon: "⏰", duration: 60)
            ]
        case .cafe:
            return [
                TempEvent(name: "Start-Up", icon: "🚀", duration: 45),
                TempEvent(name: "Freelance Work", icon: "💼", duration: 45),
                TempEvent(name: "Breakfast", icon: "🍽️", duration: 30),
                TempEvent(name: "Lunch", icon: "🍽️", duration: 30),
                TempEvent(name: "Tea", icon: "🍽️", duration: 30),
                TempEvent(name: "Dinner", icon: "🍽️", duration: 30)
            ]
        case .restaurant:
            return [
                TempEvent(name: "Breakfast", icon: "🍽️", duration: 30),
                TempEvent(name: "Lunch", icon: "🍽️", duration: 30),
                TempEvent(name: "Tea", icon: "🍽️", duration: 30),
                TempEvent(name: "Dinner", icon: "🍽️", duration: 30)
            ]
        case .park:
            return [
                TempEvent(name: "Have a walk", icon: "🚶‍♂️", duration: 30),
                TempEvent(name: "Walk the dog", icon: "🐕", duration: 30),
                TempEvent(name: "Jogging", icon: "🏃‍♂️", duration: 30),
                TempEvent(name: "Empty Your mind", icon: "😌", duration: 30)
            ]
        case .gym:
            return [
                TempEvent(name: "Gym", icon: "🏋", duration: 45)
            ]
        case .library:
            return [
                TempEvent(name: "Revision", icon: "📓", duration: 60),
                TempEvent(name: "Assignments", icon: "📚", duration: 30),
                TempEvent(name: "Start-Up", icon: "🚀", duration: 45),
                TempEvent(name: "Freelance Work", icon: "💼", duration: 45)
            ]
        case .store:
            return [
                TempEvent(name: "Window Shopping", icon: "👀", duration: 30),
                TempEvent(name: "Buying Grocery", icon: "🛒", duration: 30),
                TempEvent(name: "Buying Clothes", icon: "🧥", duration: 30)
            ]
        }
    }
    
    // Get the appropriate color based on the color scheme
    func colorFor(colorScheme: ColorScheme) -> String {
        return colorScheme == .dark ? K.defaultSectionColorDark[defaultColor] : K.defaultSectionColor[defaultColor]
    }
}

extension Location {
    
    // Available image names for locations
    static var availableImages: [String] {
        return LocationType.allCases.map { $0.rawValue }
    }
    
    // Get location type from image name
    static func locationType(from imageName: String) -> LocationType? {
        return LocationType(rawValue: imageName)
    }
    
    static let allowedPositions: [CGPoint] = [
        CGPoint(x: 100, y: 100),  // Top-left position (order 0)
        CGPoint(x: 300, y: 200),  // Middle position (order 1)
        CGPoint(x: 100, y: 300),   // Bottom-right position (order 2)
        CGPoint(x: 300, y: 400),   // Bottom-right position (order 2)
        CGPoint(x: 100, y: 500)   // Bottom-right position (order 2)
    ]
    
    static func save(name: String?, color: String?, location: Location?){
        if let l = location{
            if let n = name{
                l.name = n
            }
            if let c = color{
                l.color = c
            }
        }
        do {
            try Model.viewContext.save()
        } catch {
            print("Error removing event from location: \(error.localizedDescription)")
        }
    }
    
    // Get position coordinates from order
    static func positionFromOrder(_ order: Int16) -> CGPoint {
        let safeOrder = max(0, min(Int(order), allowedPositions.count - 1))
        return allowedPositions[safeOrder]
    }
    
    // Get order from position coordinates
    static func orderFromPosition(_ position: CGPoint) -> Int16 {
        for (index, allowedPosition) in allowedPositions.enumerated() {
            if position == allowedPosition {
                return Int16(index)
            }
        }
        
        // If not an exact match, find the closest position
        var closestIndex = 0
        var closestDistance = distance(position, allowedPositions[0])
        
        for i in 1..<allowedPositions.count {
            let currentDistance = distance(position, allowedPositions[i])
            if currentDistance < closestDistance {
                closestDistance = currentDistance
                closestIndex = i
            }
        }
        
        return Int16(closestIndex)
    }
    
    // Get the position for this location
    var position: CGPoint {
        // If reading position, convert from order to coordinates
        return Location.positionFromOrder(self.positionOrder)
    }
    
    // Set the position for this location
    func setPosition(_ newPosition: CGPoint) {
        // When setting position, convert to order
        self.positionOrder = Location.orderFromPosition(newPosition)
    }
    
    // Check if a position is already occupied
    static func isPositionOccupied(at point: CGPoint, context: NSManagedObjectContext, excludingObjectID: NSManagedObjectID? = nil) -> Bool {
        // Convert point to order
        let order = orderFromPosition(point)
        
        let request: NSFetchRequest<Location> = Location.fetchRequest()
        request.predicate = NSPredicate(format: "positionOrder == %d", order)
        
        do {
            let locations = try context.fetch(request)
            return locations.contains { location in
                // Skip if this is the location we're currently editing
                if let excludingID = excludingObjectID, location.objectID == excludingID {
                    return false
                }
                return true
            }
        } catch {
            print("Error checking position occupation: \(error)")
            return false
        }
    }
    
    // Find nearest available allowed position
    static func nearestAvailableAllowedPosition(to point: CGPoint, context: NSManagedObjectContext, excludingObjectID: NSManagedObjectID? = nil) -> CGPoint? {
        // Sort orders by distance from the input point
        let orderedPositions = allowedPositions.enumerated().sorted { 
            distance(point, $0.element) < distance(point, $1.element) 
        }
        
        // Return the first unoccupied position
        for (order, position) in orderedPositions {
            if !isPositionOrderOccupied(order: Int16(order), context: context, excludingObjectID: excludingObjectID) {
                return position
            }
        }
        
        // If all positions are occupied, return nil
        return nil
    }
    
    // Check if a position order is already occupied
    static func isPositionOrderOccupied(order: Int16, context: NSManagedObjectContext, excludingObjectID: NSManagedObjectID? = nil) -> Bool {
        let request: NSFetchRequest<Location> = Location.fetchRequest()
        request.predicate = NSPredicate(format: "positionOrder == %d", order)
        
        do {
            let locations = try context.fetch(request)
            return locations.contains { location in
                // Skip if this is the location we're currently editing
                if let excludingID = excludingObjectID, location.objectID == excludingID {
                    return false
                }
                return true
            }
        } catch {
            print("Error checking position order occupation: \(error)")
            return false
        }
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
    
    func toggleEvent(_ event: Event?) -> Bool {
        guard let event = event else { return false }
        
        let currentEvents = self.events ?? NSOrderedSet()
        
        if currentEvents.contains(event) {
            let mutableEvents = currentEvents.mutableCopy() as? NSMutableOrderedSet ?? NSMutableOrderedSet()
            let index = mutableEvents.index(of: event)
            if index != NSNotFound {
                mutableEvents.removeObject(at: index)
                self.events = mutableEvents
                
                if let locations = event.locations {
                    let mutableLocations = locations.mutableCopy() as? NSMutableSet ?? NSMutableSet()
                    mutableLocations.remove(self)
                    event.locations = mutableLocations
                }
                
                do {
                    try Model.viewContext.save()
                    print("Successfully removed event from location")
                } catch {
                    print("Error removing event from location: \(error.localizedDescription)")
                }
            }
            
            return false
        } else {
            let mutableEvents = currentEvents.mutableCopy() as? NSMutableOrderedSet ?? NSMutableOrderedSet()
            mutableEvents.add(event)
            self.events = mutableEvents
            
            let locations = event.locations ?? NSSet()
            let mutableLocations = locations.mutableCopy() as? NSMutableSet ?? NSMutableSet()
            mutableLocations.add(self)
            event.locations = mutableLocations
            
            do {
                try Model.viewContext.save()
                print("Successfully added event to location")
            } catch {
                print("Error adding event to location: \(error.localizedDescription)")
            }
            
            return true
        }
    }
    
    static func defaultColorFor(locationType: LocationType, in colorScheme: ColorScheme) -> String {
        return locationType.colorFor(colorScheme: colorScheme)
    }
    
    static func findByImageName(_ imageName: String, in context: NSManagedObjectContext) -> Location? {
        let fetchRequest: NSFetchRequest<Location> = Location.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "imageName == %@", imageName)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.first
        } catch {
            print("Error fetching location by image name: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Create a new Location entity with default values
    static func createNew(in context: NSManagedObjectContext, 
                         imageName: String = "home",
                         posOrder: Int16 = 0,
                         colorScheme: ColorScheme = .light) -> Location? {
        
        // Try to find an available position order
        var availableOrder: Int16 = 0
        
        for order in 0..<Int16(allowedPositions.count) {
            if !isPositionOrderOccupied(order: order, context: context) {
                availableOrder = order
                break
            }
        }
        
        // If we couldn't find an available order, all positions are occupied
        if availableOrder >= Int16(allowedPositions.count) {
            print("Cannot create location: all allowed positions are occupied")
            return nil
        }
        
        let newLocation = Location(context: context)
        newLocation.imageName = imageName
        newLocation.name = imageName
        newLocation.positionOrder = availableOrder
        
        // Set default color based on location type and color scheme
        if let locationType = LocationType(rawValue: imageName) {
            newLocation.color = locationType.colorFor(colorScheme: colorScheme)
        }
        
        // Save the context
        do {
            try context.save()
            let position = positionFromOrder(availableOrder)
            print("New location created with image: \(imageName) at position (\(position.x), \(position.y)) with order \(availableOrder)")
            return newLocation
        } catch {
            print("Error saving new location: \(error.localizedDescription)")
            // Handle the error appropriately
            return newLocation
        }
    }
    
    // Update the position of a location
    func updatePositionOrder(_ newOrder: Int16, context: NSManagedObjectContext) -> Bool {
        // Check if the order is valid
        if newOrder < 0 || newOrder >= Int16(Location.allowedPositions.count) {
            print("Invalid position order: \(newOrder)")
            return false
        }
        
        // Check if the position is already occupied
        if Location.isPositionOrderOccupied(order: newOrder, context: context, excludingObjectID: self.objectID) {
            print("Position order \(newOrder) is already occupied")
            return false
        }
        
        // Update the position order
        self.positionOrder = newOrder
        
        // Save changes
        do {
            try context.save()
            let position = Location.positionFromOrder(newOrder)
            print("Updated location position to order \(newOrder) at coordinates (\(position.x), \(position.y))")
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
