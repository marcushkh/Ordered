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

struct CustomMapView: View {
    @ObservedObject var viewModel: ContentViewModel
    @AppStorage("mapStyle") private var mapStyle: String = MapStyle.grid.rawValue
    @State private var scale: CGFloat = 1.0
    @State private var isScrolling = false
    @State private var isDragging = false
    @State private var selectedLocationObjectID: NSManagedObjectID? = nil
    @State private var scrollViewID = UUID() // ID for ScrollViewReader
    
    // Add Environment for CoreData context
    @Environment(\.managedObjectContext) private var viewContext
    
    // FetchRequest for Location entities
    @FetchRequest(
        sortDescriptors: [
            SortDescriptor(\.name, order: .forward)
        ]
    )
    private var locations: FetchedResults<Location>
    
    // Computed property to determine current map style
    private var currentMapStyle: MapStyle {
        MapStyle(rawValue: mapStyle) ?? .grid
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width * 2
            let height = geo.size.height * 2
            
            // Calculate center position for content
            let centerX = (width - geo.size.width) / 2
            let centerY = (height - geo.size.height) / 2
            
            // Native ScrollView with ScrollViewReader for programmatic scrolling
            ScrollViewReader { scrollProxy in
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    ZStack {
                        // First layer: background style
                        BackgroundView(style: currentMapStyle)
                            .frame(width: width, height: height)
                            .zIndex(0)
                        
                        // Second layer: transparent tap detector
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
                            .zIndex(1)
                        
                        // Third layer: draggable rectangles from Location entities
                        ForEach(locations) { location in
                            LocationRectangleView(
                                location: location,
                                isDragging: $isDragging,
                                selectedLocationObjectID: $selectedLocationObjectID,
                                viewModel: viewModel
                            )
                            .zIndex(2)
                        }
                        .onChange(of: viewModel.refresh) { oldValue, newValue in
                            // Refresh handling
                        }
                        
                        // Center point marker - hidden but used for scrolling to center
                        Color.clear
                            .frame(width: 1, height: 1)
                            .id("center")
                            .position(x: width/2, y: height/2)
                    }
                    .frame(width: width, height: height)
                    // Add padding to ensure content can scroll to edges
                    .padding(EdgeInsets(
                        top: geo.size.height/2,
                        leading: geo.size.width/2,
                        bottom: geo.size.height/2,
                        trailing: geo.size.width/2
                    ))
                }
                // Track scrolling state using a gesture
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { _ in
                            isScrolling = true
                        }
                        .onEnded { _ in
                            // Small delay to prevent tap detection immediately after scrolling
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isScrolling = false
                            }
                        }
                )
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            scrollProxy.scrollTo("center", anchor: .center)
                        }
                    }
                }
                .onChange(of: viewModel.currentTab){
                    withAnimation {
                        scrollProxy.scrollTo("center", anchor: .center)
                    }
                }
                .onChange(of: viewModel.refresh) {
                }
                .id(scrollViewID)
            }
        }
        .ignoresSafeArea()
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
    
    private let size = CGSize(width: 100, height: 100)
    
    var body: some View {
        ZStack {
            if isPositioning {
                // The actual rectangle when in positioning mode
                Rectangle()
                    .frame(width: size.width, height: size.height)
                    .foregroundStyle(.black)
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
                                
                                // Update the database with new position
                                // Convert from CGFloat to Int16 for database
                                let newPosX = Int16(max(0, min(Int(newPosition.x), Int(Int16.max))))
                                let newPosY = Int16(max(0, min(Int(newPosition.y), Int(Int16.max))))
                                
                                // Call the update method from our extension
                                location.updatePosition(posX: newPosX, posY: newPosY, context: viewContext)
                            }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.blue, lineWidth: 2)
                            .frame(width: size.width + 4, height: size.height + 4)
                    )
            } else {
                // Main rectangle with conditional border based on context menu state
                Rectangle()
                    .frame(width: size.width, height: size.height)
                    .foregroundStyle(.black)
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
                                print("The rectangle is tapped")
                                print("Location: \(location.name ?? "Unnamed")")
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
                        // Custom preview showing the actual rectangle
                        VStack {
                            Rectangle()
                                .frame(width: size.width, height: size.height)
                                .foregroundStyle(.black)
                                .cornerRadius(2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 2)
//                                        .stroke(.color3, lineWidth: 4)
                                )
                                .onAppear { isContextMenuPresented = true }
                                .onDisappear { isContextMenuPresented = false }
                            
                            if let name = location.name, !name.isEmpty {
                                Text(name)
                                    .font(.caption)
                            }
                        }
                        .padding(5)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
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
                        Text("Are you sure you want to delete '\(location.name ?? "this location")'? This action cannot be undone.")
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

