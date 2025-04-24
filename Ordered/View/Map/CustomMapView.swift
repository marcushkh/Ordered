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
    @State private var rectangles: [DraggableRectangle] = [
        DraggableRectangle(id: UUID(), position: CGPoint(x: 100, y: 100), size: CGSize(width: 80, height: 40))
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
                    GridBackground()
                        .frame(width: width, height: height)

                    // Map all draggable rectangles
                    ForEach(rectangles) { rect in
                        Rectangle()
                            .frame(width: rect.size.width, height: rect.size.height)
                            .foregroundStyle(.black)
                            .position(rect.position)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        isDragging = true
                                        if let index = rectangles.firstIndex(where: { $0.id == rect.id }) {
                                            rectangles[index].position = value.location
                                        }
                                    }
                                    .onEnded { _ in
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            isDragging = false
                                        }
                                    }
                            )
                    }
                    
                    // Add Rectangle button
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                // Add a new rectangle at the center of the visible area
                                let centerPosition = CGPoint(
                                    x: scrollOffset.x + geo.size.width/2,
                                    y: scrollOffset.y + geo.size.height/2
                                )
                                rectangles.append(
                                    DraggableRectangle(
                                        id: UUID(),
                                        position: centerPosition,
                                        size: CGSize(width: 80, height: 40)
                                    )
                                )
                            }) {
                                Image(systemName: "plus.rectangle")
                                    .font(.system(size: 24))
                                    .padding()
                                    .background(Color.white.opacity(0.8))
                                    .clipShape(Circle())
                            }
                            .padding()
                        }
                    }
                }
                .frame(width: width, height: height)
            }
        }
        .ignoresSafeArea()
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
