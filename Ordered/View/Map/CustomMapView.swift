//
//  SwiftUIView.swift
//  Ordered
//
//  Created by Kai Hin Hung on 24/4/2025.
//

import SwiftUI
import MapKit
import CoreData

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
    
    // Add state to track drag operations
    @State private var isDraggingOver: Bool = false
    @State private var draggedItemName: String? = nil
    
    // Add Environment for CoreData context and color scheme
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
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
                ScrollView(.vertical, showsIndicators: false) {
                    ZStack {
                        // First layer: background style
                        BackgroundView(style: currentMapStyle)
                            .frame(width: width, height: height)
                            .background(Color.cBackground) // Ensure background has color
                            .zIndex(0)
                            .allowsHitTesting(false) // Disable hit testing on background
                        
                        // Main drop area covering the entire map for tap gestures only
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
                            .zIndex(0) // Lowest zIndex
                        
                        // Visual indicators for allowed position squares
                        ForEach(0..<Location.allowedPositions.count, id: \.self) { index in
                            let position = Location.allowedPositions[index]
                            
                            // Individual state for each drop target to improve responsiveness
                            let isOccupied = Location.isPositionOccupied(at: position, context: viewContext)
                            
                            // Show blue rectangles for unoccupied positions
                            if !isOccupied {
                                ZStack {
                                    // Visual part - blue outline
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.color3, lineWidth: 2)
                                        .frame(width: 120, height: 120)
                                        .allowsHitTesting(false)
                                    
                                    // Invisible interactive part for drop handling
                                    Color.clear
                                        .frame(width: 120, height: 120)
                                        .contentShape(Rectangle())
                                        .onDrop(of: [.text], isTargeted: $isDraggingOver) { providers, _ in
                                            print("ondrop1")
                                            // Helper function to handle drop at this position
                                            func handleDrop() -> Bool {
                                                isDraggingOver = true
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                    isDraggingOver = false
                                                }
                                                
                                                guard let provider = providers.first else { return false }
                                                
                                                if let imageName = provider.suggestedName,
                                                   Location.availableImages.contains(imageName) {
                                                    
                                                    if locationExists(withImageName: imageName) {
                                                        print("Location of type \(imageName) already exists, ignoring drop")
                                                        return false
                                                    }
                                                    
                                                    // Create a new location at this position with the correct order
                                                    let order = Location.orderFromPosition(position)
                                                    let newLocation = Location.createNew(in: self.viewContext, 
                                                                              imageName: imageName,
                                                                              posOrder: order,
                                                                              colorScheme: colorScheme)
                                                    self.viewModel.refresh.toggle()
                                                    return true
                                                }
                                                
                                                provider.loadObject(ofClass: NSString.self) { string, _ in
                                                    guard let imageName = string as? String,
                                                          Location.availableImages.contains(imageName) else { return }
                                                    
                                                    if self.locationExists(withImageName: imageName) {
                                                        print("Location of type \(imageName) already exists, ignoring drop")
                                                        return
                                                    }
                                                    
                                                    let order = Location.orderFromPosition(position)
                                                    let newLocation = Location.createNew(in: self.viewContext, 
                                                                              imageName: imageName,
                                                                              posOrder: order,
                                                                              colorScheme: self.colorScheme)
                                                    self.viewModel.refresh.toggle()
                                                }
                                                return true
                                            }
                                            
                                            return handleDrop()
                                        }
                                }
                                .position(position)
                                .zIndex(10)
                            }
                        }
                        
                        // Third layer: draggable rectangles from Location entities
                        ForEach(locations) { location in
                            LocationRectangleView(
                                location: location,
                                isDragging: $isDragging,
                                selectedLocationObjectID: $selectedLocationObjectID,
                                viewModel: viewModel,
                                isDraggingOver: $isDraggingOver,
                                allowedPositions: Location.allowedPositions
                            )
                            .zIndex(2) 
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
                .scrollIndicators(.hidden)
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
                            // Still need this delay for gesture handling
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isScrolling = false
                            }
                        }
                )
                // Use preference key to report scroll view size
                .background(
                    GeometryReader { scrollGeo in
                        Color.cBackground
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
        // Convert position to order
        let order = Location.orderFromPosition(position)
        
        let request: NSFetchRequest<Location> = Location.fetchRequest()
        request.predicate = NSPredicate(format: "positionOrder == %d", order)
        
        do {
            let locations = try viewContext.fetch(request)
            return locations.first
        } catch {
            print("Error fetching locations: \(error)")
        }
        
        return nil
    }
    
    // Handle drop from top bar - legacy handler that calls the optimized one
    private func handleDrop(providers: [NSItemProvider], at dropPoint: CGPoint) -> Bool {
        // Find which position the drop point corresponds to
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
                // We found an empty square, create a new location
                guard let provider = providers.first else { return false }
                
                provider.loadObject(ofClass: NSString.self) { string, _ in
                    guard let imageName = string as? String,
                          Location.availableImages.contains(imageName) else { return }
                    
                    // Create a new location at this position with the correct order
                    let order = Location.orderFromPosition(position)
                    let _ = Location.createNew(in: self.viewContext, 
                                            imageName: imageName,
                                            posOrder: order,
                                            colorScheme: self.colorScheme)
                    self.viewModel.refresh.toggle()
                }
                
                return true
            }
        }
        
        // No matching position found
        return false
    }

    // Helper method to check if a location with a specific image name already exists
    private func locationExists(withImageName imageName: String) -> Bool {
        let request: NSFetchRequest<Location> = Location.fetchRequest()
        request.predicate = NSPredicate(format: "imageName == %@", imageName)
        
        do {
            let matchingLocations = try viewContext.fetch(request)
            return !matchingLocations.isEmpty
        } catch {
            print("Error checking for existing locations: \(error)")
            return false
        }
    }
}

struct LocationRectangleView: View {
    let location: Location
    @Binding var isDragging: Bool
    @Binding var selectedLocationObjectID: NSManagedObjectID?
    @GestureState private var dragOffset: CGSize = .zero
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var isContextMenuPresented = false
    // State for delete confirmation
    @State private var showDeleteAlert = false
    @ObservedObject var viewModel: ContentViewModel
    @Binding var isDraggingOver: Bool
    let allowedPositions: [CGPoint]
    // Add state for swap indicator
    @State private var isHoveringForSwap: Bool = false
    
    // Add states for location replacement confirmation
    @State private var showReplaceAlert = false
    @State private var pendingNewImageName: String? = nil
    
    private var isPositioning: Bool {
        isDragging && selectedLocationObjectID == location.objectID
    }
    
    private var position: CGPoint {
        // Use the new position property that converts from order to coordinates
        return location.position
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
                                
                                // Calculate current position during drag
                                let currentDragPosition = CGPoint(
                                    x: position.x + value.translation.width,
                                    y: position.y + value.translation.height
                                )
                                
                                // Check if we're hovering over an allowed position that has another location
                                var foundHoverTarget = false
                                for targetPos in allowedPositions {
                                    // Calculate the square boundaries
                                    let squareSize: CGFloat = 120
                                    let halfSize = squareSize / 2
                                    let minX = targetPos.x - halfSize
                                    let maxX = targetPos.x + halfSize
                                    let minY = targetPos.y - halfSize
                                    let maxY = targetPos.y + halfSize
                                    
                                    // Check if we're hovering over this position
                                    if currentDragPosition.x >= minX && currentDragPosition.x <= maxX &&
                                       currentDragPosition.y >= minY && currentDragPosition.y <= maxY {
                                        // Skip if this is our own position
                                        if targetPos == location.position {
                                            continue
                                        }
                                        
                                        // Check if position is occupied
                                        if let _ = findExistingLocationAt(position: targetPos) {
                                            // We're hovering over another location for swapping
                                            isHoveringForSwap = true
                                            foundHoverTarget = true
                                            break
                                        }
                                    }
                                }
                                
                                // Clear hover state if not hovering over any occupied position
                                if !foundHoverTarget {
                                    isHoveringForSwap = false
                                }
                            }
                            .onEnded { value in
                                // Reset hovering state
                                isHoveringForSwap = false
                                
                                let newPosition = CGPoint(
                                    x: position.x + value.translation.width,
                                    y: position.y + value.translation.height
                                )
                                
                                // Reset dragging state
                                withAnimation(.spring()) {
                                    isDragging = false
                                    selectedLocationObjectID = nil
                                }
                                
                                // Find if we're over an allowed position
                                var targetPosition: CGPoint? = nil
                                
                                for position in allowedPositions {
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
                                        targetPosition = position
                                        break
                                    }
                                }
                                
                                // Only proceed if the drop was inside an allowed square
                                if let targetPos = targetPosition {
                                    // Check if target position is already occupied by a different location
                                    if let otherLocation = findExistingLocationAt(position: targetPos) {
                                        // Swap positions with the other location
                                        swapPositions(with: otherLocation)
                                    } else {
                                        // Position is free, just update this location
                                        updatePosition(to: targetPos)
                                    }
                                } else {
                                    // Not dropped on a valid position, reset view
                                    viewModel.refresh.toggle()
                                }
                            }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.color3, lineWidth: 2)
                            .frame(width: size.width + 4, height: size.height + 4)
                    )
                    .overlay(
                        Group {
                            if isHoveringForSwap {
                                VStack(spacing: 0) {
                                    // Position the icon above the image
                                    Image(systemName: "arrow.trianglehead.2.clockwise")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.color3)
                                        .background(
                                            Circle()
                                                .fill(Color.cBackground)
                                                .frame(width: 24, height: 24)
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(Color.color3, lineWidth: 1.5)
                                                .frame(width: 24, height: 24)
                                        )
                                        .offset(y: -15)
                                        .zIndex(110)
                                    
                                    Spacer()
                                }
                                .frame(width: size.width, height: size.height)
                            }
                        }
                    )
            } else {
                // Main image when not in positioning mode
                Image(imageName)
                    .resizable()
                    .frame(width: size.width, height: size.height)
                    .overlay(
                        isContextMenuPresented ? 
                            RoundedRectangle(cornerRadius: 2)
                                .frame(width: size.width + 4, height: size.height + 4)
                            : nil
                    )
                
                // Only show the interactive overlay when not dragging from toolbar
                if !isDraggingOver {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: size.width, height: size.height)
                        .contentShape(Rectangle())
                        .contextMenu {
                            Button("Edit Location"){
                                //change color and name
                                viewModel.changeLocation = location
                                viewModel.showChangeLocation = true
                            }
                            
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
                            Image(imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                                .onAppear { isContextMenuPresented = true }
                                .onDisappear { isContextMenuPresented = false }
                        }
                        .onTapGesture {
                            //is tapped
                            viewModel.showLocationEventList = true
                            viewModel.location = location
                            print("Location: \(location.imageName ?? "Unnamed")")
                        }
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .onDrop(of: [.text], isTargeted: $isDraggingOver) { providers, _ in
            print("ondrop 2")
            // Helper function to handle drop at this location's position
            func handleDrop() -> Bool {
                // Set dragging state to block context menus during drop
                isDraggingOver = true
                // Still need this delay for UI state
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isDraggingOver = false
                }
                
                guard let provider = providers.first else { return false }
                
                // Get image name synchronously if possible
                if let imageName = provider.suggestedName, 
                   Location.availableImages.contains(imageName) {
                    // Store the pending image name and show confirmation alert
                    pendingNewImageName = imageName
                    showReplaceAlert = true
                    return true
                }
                
                // Fallback to async loading
                provider.loadObject(ofClass: NSString.self) { string, _ in
                    guard let imageName = string as? String,
                          Location.availableImages.contains(imageName) else { return }
                    
                    // Store the pending image name and show confirmation alert
                    pendingNewImageName = imageName
                    showReplaceAlert = true
                }
                return true
            }
            
            return handleDrop()
        }
        .alert("Delete Location?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            
            Button("Delete", role: .destructive) {
                if location.delete(from: viewContext) {
                    viewModel.refresh.toggle()
                }
            }
        } message: {
            Text("Are you sure you want to delete this \(imageName)? This action cannot be undone.")
        }
        // Add alert for location replacement
        .alert("Replace Location?", isPresented: $showReplaceAlert) {
            Button("Cancel", role: .cancel) {
                pendingNewImageName = nil
            }
            
            Button("Replace", role: .destructive) {
                if let newImageName = pendingNewImageName {
                    // Check if a different location with this image already exists
                    if locationExistsExcluding(imageName: newImageName, excludingLocation: location) {
                        print("Cannot update: Another location with type \(newImageName) already exists")
                    } else {
                        // Replace existing location
                        location.imageName = newImageName
                        location.name = newImageName
                        
                        // Set default color based on location type and color scheme
                        if let locationType = LocationType(rawValue: newImageName) {
                            location.color = locationType.colorFor(colorScheme: colorScheme)
                        }
                        
                        try? viewContext.save()
                        viewModel.refresh.toggle()
                    }
                    pendingNewImageName = nil
                }
            }
        } message: {
            if let newImageName = pendingNewImageName {
                Text("""
                     Are you sure you want to replace \(location.name ?? imageName) with \(newImageName)? 
                    All Settings in \(location.name ?? imageName) will be deleted
                    """)
            } else {
                Text("Are you sure you want to replace this location?")
            }
        }
        .position(
            CGPoint(
                x: position.x + (isPositioning ? dragOffset.width : 0),
                y: position.y + (isPositioning ? dragOffset.height : 0)
            )
        )
        .animation(.interactiveSpring(), value: isPositioning)
        .zIndex(isPositioning ? 100 : 2) // Set highest z-index when positioning
    }
    
    // Find an existing location at a position, excluding this location
    private func findExistingLocationAt(position: CGPoint) -> Location? {
        // Convert position to order
        let order = Location.orderFromPosition(position)
        
        let request: NSFetchRequest<Location> = Location.fetchRequest()
        request.predicate = NSPredicate(format: "positionOrder == %d", order)
        
        do {
            let allLocations = try viewContext.fetch(request)
            
            for existingLocation in allLocations {
                // Skip this location
                if existingLocation.objectID == location.objectID {
                    continue
                }
                
                return existingLocation
            }
        } catch {
            print("Error finding location: \(error)")
        }
        
        return nil
    }
    
    // Update position of this location
    private func updatePosition(to newPosition: CGPoint) {
        // Convert the position to order and set it
        location.setPosition(newPosition)
        
        do {
            try viewContext.save()
            print("Updated location position to \(newPosition)")
            viewModel.refresh.toggle()
        } catch {
            print("Error updating location: \(error)")
            viewModel.refresh.toggle()
        }
    }
    
    // Swap positions with another location
    private func swapPositions(with otherLocation: Location) {
        // Store original order values
        let thisOrder = location.positionOrder
        let otherOrder = otherLocation.positionOrder
        
        // Update position orders
        location.positionOrder = otherOrder
        otherLocation.positionOrder = thisOrder
        
        // Save changes
        do {
            try viewContext.save()
            print("Swapped location positions successfully")
            viewModel.refresh.toggle()
        } catch {
            print("Error swapping locations: \(error)")
            viewModel.refresh.toggle()
        }
    }

    // Helper method to check if a location with a specific image name already exists, excluding the current location
    private func locationExistsExcluding(imageName: String, excludingLocation: Location) -> Bool {
        let request: NSFetchRequest<Location> = Location.fetchRequest()
        request.predicate = NSPredicate(format: "imageName == %@ AND self != %@", imageName, excludingLocation)
        
        do {
            let matchingLocations = try viewContext.fetch(request)
            return !matchingLocations.isEmpty
        } catch {
            print("Error checking for existing locations: \(error)")
            return false
        }
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
            .background(Color.cBackground)
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
            .background(Color.cBackground)
        }
    }
}

