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
    @AppStorage("mapStyle") private var mapStyle: String = MapStyle.grid.rawValue
    @State private var scale: CGFloat = 1.0
    @State private var scrollOffset = CGPoint.zero
    @State private var hasCentered = false
    @State private var isDragging = false
    @State private var selectedLocationObjectID: NSManagedObjectID? = nil
    @State private var isScrolling = false
    @State private var canvasSize: CGSize = .zero
    
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
            
            ScrollableView(
                contentSize: CGSize(width: width, height: height),
                containerSize: geo.size,
                scale: $scale,
                scrollOffset: $scrollOffset,
                hasCentered: $hasCentered,
                onScrollStarted: {
                    isScrolling = true
                },
                onScrollEnded: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isScrolling = false
                    }
                }
            ) {
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
                                print("tapped the background")
                            }
                        }
                        .zIndex(1)
                    
                    // Third layer: draggable rectangles from Location entities
                    ForEach(locations) { location in
                        LocationRectangleView(
                            location: location,
                            isDragging: $isDragging,
                            selectedLocationObjectID: $selectedLocationObjectID
                        )
                        .zIndex(2)
                    }
                }
                .frame(width: width, height: height)
                .onAppear {
                    print("Canvas initialized")
                    canvasSize = CGSize(width: width, height: height)
                }
            }
        }
        .ignoresSafeArea()
    }
}

// Modified view to use Location entity instead of DraggableRectangle
struct LocationRectangleView: View {
    let location: Location
    @Binding var isDragging: Bool
    @Binding var selectedLocationObjectID: NSManagedObjectID?
    @GestureState private var dragOffset: CGSize = .zero
    
    // Computed property to check if this location is in positioning mode
    private var isPositioning: Bool {
        isDragging && selectedLocationObjectID == location.objectID
    }
    
    // Get position from Location entity
    private var position: CGPoint {
        CGPoint(
            x: CGFloat(location.positionX),
            y: CGFloat(location.positionY)
        )
    }
    
    // Default size for the rectangle
    private let size = CGSize(width: 80, height: 40)
    
    var body: some View {
        Rectangle()
            .frame(width: size.width, height: size.height)
            .foregroundStyle(.black)
            // Ensure hit testing is limited to visible rectangle
            .contentShape(Rectangle())
            // Only apply the gesture when in positioning mode
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .updating($dragOffset) { value, state, _ in
                        if isPositioning {
                            state = CGSize(
                                width: value.translation.width,
                                height: value.translation.height
                            )
                        }
                    }
                    .onEnded { value in
                        // Only update position if in positioning mode
                        if isPositioning {
                            let newPosition = CGPoint(
                                x: position.x + value.translation.width,
                                y: position.y + value.translation.height
                            )
                            // In the full implementation, we would update location.positionX/Y here
                            print("Would move location to: \(newPosition)")
                            
                            // For now, we're not modifying the database as requested
                        }
                    }
            )
            // Add a context menu with "Change position" option
            .contextMenu {
                Button("Change position") {
                    // Enter positioning mode for this location
                    withAnimation(.spring()) {
                        isDragging = true
                        selectedLocationObjectID = location.objectID
                    }
                    print("Positioning mode activated for location: \(location.name ?? "Unnamed")")
                }
            }
            // Visual indication that we're in positioning mode
            .overlay(
                isPositioning ?
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.blue, lineWidth: 2)
                        .frame(width: size.width + 4, height: size.height + 4)
                    : nil
            )
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

class CenteringScrollView: UIScrollView {
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let contentView = subviews.first else { return }
        var frame = contentView.frame
        frame.origin.x = contentView.frame.width  < bounds.width  ? (bounds.width  - contentView.frame.width ) / 2 : 0
        frame.origin.y = contentView.frame.height < bounds.height ? (bounds.height - contentView.frame.height) / 2 : 0
        contentView.frame = frame
    }
}

struct ScrollableView<Content: View>: UIViewRepresentable {
    let contentSize: CGSize
    let containerSize: CGSize
    @Binding var scale: CGFloat
    @Binding var scrollOffset: CGPoint
    @Binding var hasCentered: Bool
    let onScrollStarted: () -> Void
    let onScrollEnded: () -> Void
    let content: () -> Content

    func makeCoordinator() -> Coordinator {
        Coordinator(scale: $scale, 
                    scrollOffset: $scrollOffset, 
                    hasCentered: $hasCentered,
                    onScrollStarted: onScrollStarted,
                    onScrollEnded: onScrollEnded)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = CenteringScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 1.0
        scrollView.bounces = false
        scrollView.bouncesZoom = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false

        let hosting = UIHostingController(rootView: content())
        hosting.view.translatesAutoresizingMaskIntoConstraints = true
        hosting.view.frame = CGRect(origin: .zero, size: contentSize)
        scrollView.addSubview(hosting.view)
        context.coordinator.hostingView = hosting.view

        scrollView.contentSize = contentSize
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.contentInset = .zero
        scrollView.clipsToBounds = true

        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        uiView.layoutIfNeeded()
        
        let contentWidth = contentSize.width * uiView.zoomScale
        let contentHeight = contentSize.height * uiView.zoomScale
        let boundsWidth = uiView.bounds.width
        let boundsHeight = uiView.bounds.height

        let insetX = max((boundsWidth - contentWidth) / 2, 0)
        let insetY = max((boundsHeight - contentHeight) / 2, 0)

        uiView.contentInset = UIEdgeInsets(top: insetY, left: insetX, bottom: insetY, right: insetX)

        if !hasCentered {
            DispatchQueue.main.async {
                uiView.layoutIfNeeded()
                let offsetX = max((uiView.contentSize.width - uiView.bounds.width) / 2, 0)
                let offsetY = max((uiView.contentSize.height - uiView.bounds.height) / 2, 0)
                uiView.setContentOffset(CGPoint(x: offsetX, y: offsetY), animated: false)
                hasCentered = true
            }
        }
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        @Binding var scale: CGFloat
        @Binding var scrollOffset: CGPoint
        @Binding var hasCentered: Bool
        let onScrollStarted: () -> Void
        let onScrollEnded: () -> Void
        weak var hostingView: UIView?
        private var isScrolling = false

        init(scale: Binding<CGFloat>, 
             scrollOffset: Binding<CGPoint>, 
             hasCentered: Binding<Bool>,
             onScrollStarted: @escaping () -> Void,
             onScrollEnded: @escaping () -> Void) {
            _scale = scale
            _scrollOffset = scrollOffset
            _hasCentered = hasCentered
            self.onScrollStarted = onScrollStarted
            self.onScrollEnded = onScrollEnded
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return nil
        }

        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            if !isScrolling {
                isScrolling = true
                onScrollStarted()
            }
        }
        
        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if !decelerate {
                isScrolling = false
                onScrollEnded()
            }
        }
        
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            isScrolling = false
            onScrollEnded()
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            scrollOffset = scrollView.contentOffset
        }
    }
}

#Preview {
    CustomMapView()
}
