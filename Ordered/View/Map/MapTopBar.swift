//
//  MapTopBar.swift
//  Ordered
//
//  Created on current date
//

import SwiftUI
import CoreData

struct MapTopBar: View {
    @ObservedObject var viewModel: ContentViewModel
    @Environment(\.managedObjectContext) private var viewContext
    
    // Available location types with their images
    private let locationImages = Location.availableImages
    
    var body: some View {
        VStack {
            // Image selector - horizontal scrollview
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(locationImages, id: \.self) { imageName in
                        DraggableLocationButton(
                            imageName: imageName,
                            viewModel: viewModel,
                            viewContext: viewContext
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.vertical)
            }
            .frame(height: 100)
        }
        .padding(.vertical, -10)
    }
}

// Component for a draggable location button
struct DraggableLocationButton: View {
    let imageName: String
    @ObservedObject var viewModel: ContentViewModel
    let viewContext: NSManagedObjectContext
    
    // State for drag operation
    @State private var isDragging = false
    
    var body: some View {
        Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 60, height: 60)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
            )
            .opacity(isDragging ? 0.5 : 1.0)
            .onDrag {
                // Set the data for the drag operation and update state
                isDragging = true
                
                // Use a shorter timer to reset dragging state
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isDragging = false
                }
                
                // Create a simpler item provider with the image name
                // Use UTType.text to ensure fast drag operation
                let provider = NSItemProvider(object: imageName as NSString)
                
                // Skip preview handling to make drag more responsive
                provider.suggestedName = imageName
                return provider
            } preview: {
                // A more distinctive preview that clearly shows what's being dragged
                DragPreview(imageName: imageName)
            }
    }
}

// Custom drag preview
struct DragPreview: View {
    let imageName: String
    
    var body: some View {
        ZStack {
            // The main image
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                
            // Subtle overlay to indicate it's being dragged
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.blue, lineWidth: 2)
                .frame(width: 100, height: 100)
        }
    }
}

#Preview {
    MapTopBar(viewModel: ContentViewModel())
        .background(Color.gray.opacity(0.2))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 
