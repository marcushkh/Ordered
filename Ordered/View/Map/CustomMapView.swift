//
//  SwiftUIView.swift
//  Ordered
//
//  Created by Kai Hin Hung on 24/4/2025.
//

import SwiftUI
import MapKit

struct CustomMapView: View {
    @State private var scale: CGFloat = 1.0
    @State private var scrollOffset = CGPoint.zero
    @State private var hasCentered = false
    @State private var isDragging = false
    @State private var selectedRectangleId: UUID? = nil
    @State private var rectangles: [DraggableRectangle] = [
        DraggableRectangle(id: UUID(), position: CGPoint(x: 300, y: 300), size: CGSize(width: 80, height: 40))
    ]

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
                isScrollingEnabled: !isDragging
            ) {
                ZStack {
                    // Background with tap gesture to exit positioning mode
                    GridBackground()
                        .frame(width: width, height: height)
                        .onTapGesture {
                            // Exit positioning mode when tapping on the background
                            if isDragging {
                                isDragging = false
                                selectedRectangleId = nil
                            }
                            print("tapped the background")
                        }
                        .zIndex(0) // Ensure grid is at the bottom of the stack
                    
                    // Map all draggable rectangles
                    ForEach(rectangles.indices, id: \.self) { index in
                        DraggableRectangleView(
                            rectangleIndex: index,
                            rectangles: $rectangles,
                            isDragging: $isDragging,
                            selectedRectangleId: $selectedRectangleId
                        )
                        .zIndex(1) // Make rectangles above the grid
                    }
                }
                .frame(width: width, height: height)
            }
        }
        .ignoresSafeArea()
    }
}

struct DraggableRectangleView: View {
    let rectangleIndex: Int
    @Binding var rectangles: [DraggableRectangle]
    @Binding var isDragging: Bool
    @Binding var selectedRectangleId: UUID?
    @GestureState private var dragOffset: CGSize = .zero
    
    private var rectangle: DraggableRectangle {
        rectangles[rectangleIndex]
    }
    
    // Computed property to check if this rectangle is in positioning mode
    private var isPositioning: Bool {
        isDragging && selectedRectangleId == rectangle.id
    }
    
    var body: some View {
        Rectangle()
            .frame(width: rectangle.size.width, height: rectangle.size.height)
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
                                x: rectangle.position.x + value.translation.width,
                                y: rectangle.position.y + value.translation.height
                            )
                            rectangles[rectangleIndex].position = newPosition
                            print("Moved rectangle to: \(newPosition)")
                        }
                    }
            )
            // Add a context menu with "Change position" option
            .contextMenu {
                Button("Change position") {
                    // Enter positioning mode for this rectangle
                    isDragging = true
                    selectedRectangleId = rectangle.id
                    print("Positioning mode activated for rectangle \(rectangle.id)")
                }
            }
            // Visual indication that we're in positioning mode
            .overlay(
                isPositioning ?
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.blue, lineWidth: 2)
                        .frame(width: rectangle.size.width + 4, height: rectangle.size.height + 4)
                    : nil
            )
            .position(
                CGPoint(
                    x: rectangle.position.x + (isPositioning ? dragOffset.width : 0),
                    y: rectangle.position.y + (isPositioning ? dragOffset.height : 0)
                )
            )
            .animation(.interactiveSpring(), value: isPositioning)
            // Ensure this view doesn't capture taps outside its visible area
            .background(Color.clear)
    }
}

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
    let isScrollingEnabled: Bool
    let content: () -> Content

    func makeCoordinator() -> Coordinator {
        Coordinator(scale: $scale, scrollOffset: $scrollOffset, hasCentered: $hasCentered)
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
        uiView.isScrollEnabled = isScrollingEnabled
        
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
        weak var hostingView: UIView?

        init(scale: Binding<CGFloat>, scrollOffset: Binding<CGPoint>, hasCentered: Binding<Bool>) {
            _scale = scale
            _scrollOffset = scrollOffset
            _hasCentered = hasCentered
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return nil
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            scrollOffset = scrollView.contentOffset
        }
    }
}

// Model to represent a draggable rectangle
struct DraggableRectangle: Identifiable {
    let id: UUID
    var position: CGPoint
    var size: CGSize
    
    init(id: UUID = UUID(), position: CGPoint, size: CGSize) {
        self.id = id
        self.position = position
        self.size = size
    }
}

#Preview {
    CustomMapView()
}
