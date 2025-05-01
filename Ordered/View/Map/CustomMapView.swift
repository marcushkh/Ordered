//
//  SwiftUIView.swift
//  Ordered
//
//  Created by Kai Hin Hung on 24/4/2025.
//

import SwiftUI
import MapKit
import CoreData

// Add the MapStyle enum
enum MapStyle: String, CaseIterable {
    case grid = "grid"
    case dots = "dots"
}

// Add these preference key structures for size reporting
struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct ContentSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct CustomMapView: View {
    @ObservedObject var viewModel: ContentViewModel
    @AppStorage("mapStyle") private var mapStyle: String = MapStyle.grid.rawValue
    @State private var scale: CGFloat = 1.0
    @State private var isScrolling = false
    @State private var isDragging = false
    @State private var selectedLocationObjectID: NSManagedObjectID? = nil
    @State private var scrollViewID = UUID() // ID for ScrollViewReader
    
    // Add states to track and limit scroll position
    @State private var contentOffset: CGPoint = .zero
    @State private var scrollViewSize: CGSize = .zero
    @State private var contentSize: CGSize = .zero
    
    // Add Environment for CoreData context
    @Environment(\.managedObjectContext) private var viewContext
    
    // FetchRequest for Location entities
    @FetchRequest(
        sortDescriptors: []
    )
    private var locations: FetchedResults<Location>
    
    // Computed property to determine current map style
    private var currentMapStyle: MapStyle {
        MapStyle(rawValue: mapStyle) ?? .grid
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height * 2
            
            // Native ScrollView with ScrollViewReader for programmatic scrolling
            ScrollViewReader { scrollProxy in
                ScrollView([.vertical], showsIndicators: false) {
                    ZStack {
                        // First layer: background style
                        BackgroundView(style: currentMapStyle)
                            .frame(width: width, height: height)
                            .background(Color.white) // Ensure background has color
                            .zIndex(0)
                        
                        // Visual indicators for allowed position squares
                        ForEach(0..<Location.allowedPositions.count, id: \.self) { index in
                            let position = Location.allowedPositions[index]
                            
                            // Only show the rectangle if the position is not occupied
                            if !Location.isPositionOccupied(at: position, context: viewContext) {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue, lineWidth: 2)
                                    .frame(width: 120, height: 120)
                                    .position(position)
                                    .zIndex(1)
                            }
                        }
                        
                        // Second layer: transparent tap detector and drop receiver
                        Color.clear
                            .frame(width: width, height: height)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if !isScrolling {
                                    if isDragging {
                                        withAnimation(.spring()) {
                                            isDragging = false
                                            selectedLocationObjectID = nil
                                        }
                                    }
                                }
                            }
                            .dropDestination(for: String.self) { items, location in
                                // Only proceed if we have an item and it's one of our location images
                                guard let imageName = items.first, 
                                      Location.availableImages.contains(imageName) else {
                                    return false
                                }
                                
                                // Get the drop point
                                let dropPoint = CGPoint(x: location.x, y: location.y)
                                
                                // Check if the drop point is inside any of our allowed position squares
                                var isInsideAllowedSquare = false
                                var targetPosition: CGPoint? = nil
                                
                                for position in Location.allowedPositions {
                                    // Calculate the square boundaries
                                    let squareSize: CGFloat = 120 // Match the size of our visual rectangles
                                    let halfSize = squareSize / 2
                                    let minX = position.x - halfSize
                                    let maxX = position.x + halfSize
                                    let minY = position.y - halfSize
                                    let maxY = position.y + halfSize
                                    
                                    // Check if the drop point is inside this square
                                    if dropPoint.x >= minX && dropPoint.x <= maxX && 
                                       dropPoint.y >= minY && dropPoint.y <= maxY {
                                        isInsideAllowedSquare = true
                                        targetPosition = position
                                        break
                                    }
                                }
                                
                                // Only proceed if the drop was inside an allowed square
                                if isInsideAllowedSquare, let position = targetPosition {
                                    // Check if this position is already occupied
                                    let isOccupied = Location.isPositionOccupied(at: position, context: viewContext)
                                    
                                    if isOccupied {
                                        // Find and remove the existing location at this position
                                        if let existingLocation = findLocationAt(position: position) {
                                            // Delete the existing location
                                            existingLocation.delete(from: viewContext)
                                        }
                                    }
                                    
                                    // Create new location at the exact position
                                    let newLocation = Location(context: viewContext)
                                    newLocation.imageName = imageName
                                    newLocation.positionX = Int16(position.x)
                                    newLocation.positionY = Int16(position.y)
                                    
                                    // Save to database
                                    do {
                                        try viewContext.save()
                                        print("New location created with image: \(imageName) at position (\(position.x), \(position.y))")
                                        viewModel.refresh.toggle()
                                        return true
                                    } catch {
                                        print("Error saving new location: \(error.localizedDescription)")
                                        return false
                                    }
                                } else {
                                    // Drop was not in a valid position
                                    print("Cannot place location: drop point not in an allowed square")
                                    return false
                                }
                            }
                            .zIndex(2)
                        
                        // Third layer: draggable rectangles from Location entities
                        ForEach(locations) { location in
                            LocationRectangleView(
                                location: location,
                                isDragging: $isDragging,
                                selectedLocationObjectID: $selectedLocationObjectID,
                                viewModel: viewModel
                            )
                            .zIndex(3)
                        }
                        .onChange(of: viewModel.refresh) { oldValue, newValue in
                            // Refresh handling
                        }
                    }
                    .frame(width: width, height: height)
                    // Use preference key to report content size
                    .background(
                        GeometryReader { contentGeo in
                            Color.clear
                                .preference(key: ContentSizePreferenceKey.self, value: CGSize(width: width, height: height))
                        }
                    )
                }
                // Track scrolling state using a gesture
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            isScrolling = true
                            
                            // Calculate new proposed offset
                            let newOffset = CGPoint(
                                x: contentOffset.x - value.translation.width,
                                y: contentOffset.y - value.translation.height
                            )
                            
                            // Apply bounds to ensure we can't scroll past content edges
                            let maxOffsetX = max(0, contentSize.width - scrollViewSize.width)
                            let maxOffsetY = max(0, contentSize.height - scrollViewSize.height)
                            
                            // Update offset with constraints
                            contentOffset = CGPoint(
                                x: max(0, min(newOffset.x, maxOffsetX)),
                                y: max(0, min(newOffset.y, maxOffsetY))
                            )
                        }
                        .onEnded { _ in
                            // Small delay to prevent tap detection immediately after scrolling
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isScrolling = false
                            }
                        }
                )
                // Use preference key to report scroll view size
                .background(
                    GeometryReader { scrollGeo in
                        Color.white
                            .preference(key: SizePreferenceKey.self, value: scrollGeo.size)
                    }
                )
                .clipped() // Clip content to bounds
                .onPreferenceChange(SizePreferenceKey.self) { newSize in
                    // Update scroll view size when the preference value changes
                    scrollViewSize = newSize
                }
                .onPreferenceChange(ContentSizePreferenceKey.self) { newSize in
                    // Update content size when the preference value changes
                    contentSize = newSize
                }
                .onChange(of: viewModel.refresh) {
                }
                .id(scrollViewID)
            }
        }
        .ignoresSafeArea()
    }

    // Helper method to find a location at a specific position
    private func findLocationAt(position: CGPoint) -> Location? {
        let request: NSFetchRequest<Location> = Location.fetchRequest()
        
        do {
            let allLocations = try viewContext.fetch(request)
            for location in allLocations {
                let locationPoint = CGPoint(x: CGFloat(location.positionX), y: CGFloat(location.positionY))
                if locationPoint == position {
                    return location
                }
            }
        } catch {
            print("Error fetching locations: \(error)")
        }
        
        return nil
    }
}

struct LocationRectangleView: View {
    let location: Location
    @Binding var isDragging: Bool
    @Binding var selectedLocationObjectID: NSManagedObjectID?
    @GestureState private var dragOffset: CGSize = .zero
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isContextMenuPresented = false
    // Timer to distinguish between taps and scrolls
    @State private var tapTimer: Timer?
    @State private var potentialTap = false
    // State for delete confirmation
    @State private var showDeleteAlert = false
    @ObservedObject var viewModel: ContentViewModel
    
    private var isPositioning: Bool {
        isDragging && selectedLocationObjectID == location.objectID
    }
    
    private var position: CGPoint {
        CGPoint(
            x: CGFloat(location.positionX),
            y: CGFloat(location.positionY)
        )
    }
    
    // Get the image name from location, with fallback to "home"
    private var imageName: String {
        location.imageName ?? "home"
    }
    
    private let size = CGSize(width: 100, height: 100)
    
    var body: some View {
        ZStack {
            if isPositioning {
                // The location image when in positioning mode
                Image(imageName)
                    .resizable()
                    .frame(width: size.width, height: size.height)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .global)
                            .updating($dragOffset) { value, state, _ in
                                state = CGSize(
                                    width: value.translation.width,
                                    height: value.translation.height
                                )
                            }
                            .onEnded { value in
                                let newPosition = CGPoint(
                                    x: position.x + value.translation.width,
                                    y: position.y + value.translation.height
                                )
                                
                                // Check if the new position is inside any of our allowed position squares
                                var isInsideAllowedSquare = false
                                var targetPosition: CGPoint? = nil
                                
                                for position in Location.allowedPositions {
                                    // Calculate the square boundaries
                                    let squareSize: CGFloat = 120 // Match the size of our visual rectangles
                                    let halfSize = squareSize / 2
                                    let minX = position.x - halfSize
                                    let maxX = position.x + halfSize
                                    let minY = position.y - halfSize
                                    let maxY = position.y + halfSize
                                    
                                    // Check if the new position is inside this square
                                    if newPosition.x >= minX && newPosition.x <= maxX && 
                                       newPosition.y >= minY && newPosition.y <= maxY {
                                        isInsideAllowedSquare = true
                                        targetPosition = position
                                        break
                                    }
                                }
                                
                                // Only proceed if the drop was inside an allowed square
                                if isInsideAllowedSquare, let targetPos = targetPosition {
                                    // Check if this position is already occupied by another location
                                    let isOccupied = Location.isPositionOccupied(at: targetPos, context: viewContext, excludingObjectID: location.objectID)
                                    
                                    if isOccupied {
                                        // Find the location at the target position for swapping
                                        if let otherLocation = findLocationAt(position: targetPos, in: viewContext) {
                                            print("Swapping positions with another location")
                                            
                                            // Save original positions
                                            let originalPos = CGPoint(x: CGFloat(location.positionX), y: CGFloat(location.positionY))
                                            
                                            // Update this location to the target position
                                            location.positionX = Int16(targetPos.x)
                                            location.positionY = Int16(targetPos.y)
                                            
                                            // Update the other location to this location's position
                                            otherLocation.positionX = Int16(originalPos.x)
                                            otherLocation.positionY = Int16(originalPos.y)
                                            
                                            // Save to database
                                            do {
                                                try viewContext.save()
                                                print("Swapped locations successfully")
                                                viewModel.refresh.toggle()
                                            } catch {
                                                print("Error swapping locations: \(error.localizedDescription)")
                                                // Reset view on error
                                                withAnimation(.spring()) {
                                                    viewModel.refresh.toggle()
                                                }
                                            }
                                        } else {
                                            print("Could not find other location to swap with")
                                            withAnimation(.spring()) {
                                                viewModel.refresh.toggle()
                                            }
                                        }
                                    } else {
                                        // Position is not occupied, just update normally
                                        // Update location to the exact position
                                        location.positionX = Int16(targetPos.x)
                                        location.positionY = Int16(targetPos.y)
                                        
                                        // Save to database
                                        do {
                                            try viewContext.save()
                                            print("Updated location position to (\(targetPos.x), \(targetPos.y))")
                                            viewModel.refresh.toggle()
                                        } catch {
                                            print("Error updating location position: \(error.localizedDescription)")
                                            // Reset view on error
                                            withAnimation(.spring()) {
                                                viewModel.refresh.toggle()
                                            }
                                        }
                                    }
                                } else {
                                    // Reset to original position if not dropped in a valid square
                                    withAnimation(.spring()) {
                                        viewModel.refresh.toggle()
                                    }
                                    print("Cannot update location: drag ended outside an allowed square")
                                }
                                
                                // Reset dragging state
                                withAnimation(.spring()) {
                                    isDragging = false
                                    selectedLocationObjectID = nil
                                }
                            }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.blue, lineWidth: 2)
                            .frame(width: size.width + 4, height: size.height + 4)
                    )
            } else {
                // Main image when not in positioning mode
                Image(imageName)
                    .resizable()
                    .frame(width: size.width, height: size.height)
                    .overlay(
                        isContextMenuPresented ? 
                            RoundedRectangle(cornerRadius: 2)
//                                .stroke(.color3, lineWidth: 4)
                                .frame(width: size.width + 4, height: size.height + 4)
                            : nil
                    )
                    .allowsHitTesting(false) // Don't react to touches for scrolling purposes
                
                // Gesture and menu handler (invisible)
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: size.width, height: size.height)
                    .contentShape(Rectangle())
                    // Combined gesture that handles both taps and long-press
                    .gesture(
                        TapGesture()
                            .onEnded {
                                print("The location is tapped")
                                print("Location: \(location.imageName ?? "Unnamed")")
                            }
                    )
                    // Separate context menu for long press
                    .contextMenu {
                        Button("Change position") {
                            withAnimation(.spring()) {
                                isDragging = true
                                selectedLocationObjectID = location.objectID
                            }
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: {
                            showDeleteAlert = true
                        }) {
                            Label("Delete location", systemImage: "trash")
                        }
                    } preview: {
                        // Use the location image directly as the preview
                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .onAppear { isContextMenuPresented = true }
                            .onDisappear { isContextMenuPresented = false }
                    }
                    // Use simultaneousGesture with DragGesture with high minimum distance
                    // to detect when user scrolls and cancel the tap
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 10)
                            .onChanged { _ in
                                // If dragging beyond threshold, it's a scroll, not a tap
                                // This is handled by the parent ScrollView
                            }
                    )
                    // Alert for delete confirmation
                    .alert("Delete Location?", isPresented: $showDeleteAlert) {
                        Button("Cancel", role: .cancel) {
                            // Do nothing, just close the alert
                        }
                        
                        Button("Delete", role: .destructive) {
                            // Call delete method from Location+Ext
                            if location.delete(from: viewContext) {
                                // Trigger refresh to update UI after successful deletion
                                viewModel.refresh.toggle()
                            }
                        }
                    } message: {
                        Text("Are you sure you want to delete this \(imageName)? This action cannot be undone.")
                    }
            }
        }
        .position(
            CGPoint(
                x: position.x + (isPositioning ? dragOffset.width : 0),
                y: position.y + (isPositioning ? dragOffset.height : 0)
            )
        )
        .animation(.interactiveSpring(), value: isPositioning)
    }

    // Add this helper function to the LocationRectangleView struct
    // Helper method to find a location at a specific position
    private func findLocationAt(position: CGPoint, in context: NSManagedObjectContext) -> Location? {
        let request: NSFetchRequest<Location> = Location.fetchRequest()
        
        do {
            let allLocations = try context.fetch(request)
            for possibleLocation in allLocations {
                // Skip if this is the current location
                if possibleLocation.objectID == location.objectID {
                    continue
                }
                
                let locationPoint = CGPoint(x: CGFloat(possibleLocation.positionX), y: CGFloat(possibleLocation.positionY))
                if locationPoint == position {
                    return possibleLocation
                }
            }
        } catch {
            print("Error fetching locations: \(error)")
        }
        
        return nil
    }
}

// New BackgroundView component that handles both grid and dot styles
struct BackgroundView: View {
    var style: MapStyle
    var gridSize: CGFloat = 40
    var color: Color = .gray
    
    var body: some View {
        Group {
            if style == .grid {
                GridBackground(gridSize: gridSize, color: color)
            } else {
                DottedBackground(dotSpacing: gridSize, color: color)
            }
        }
    }
}

// Keep the original GridBackground
struct GridBackground: View {
    var gridSize: CGFloat = 40
    var color: Color = .gray

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                var path = Path()

                // Vertical lines
                for x in stride(from: 0, to: size.width, by: gridSize) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }

                // Horizontal lines
                for y in stride(from: 0, to: size.height, by: gridSize) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }

                context.stroke(path, with: .color(color.opacity(0.3)), lineWidth: 1)
            }
            .background(Color.white)
        }
    }
}

// Add new DottedBackground for the dots style
struct DottedBackground: View {
    var dotSpacing: CGFloat = 40
    var color: Color = .gray
    var dotSize: CGFloat = 4
    
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                // Draw dots at intersection points
                for x in stride(from: 0, to: size.width, by: dotSpacing) {
                    for y in stride(from: 0, to: size.height, by: dotSpacing) {
                        let dotPath = Path(ellipseIn: CGRect(
                            x: x - dotSize/2,
                            y: y - dotSize/2,
                            width: dotSize,
                            height: dotSize
                        ))
                        context.fill(dotPath, with: .color(color.opacity(0.5)))
                    }
                }
            }
            .background(Color.white)
        }
    }
}

