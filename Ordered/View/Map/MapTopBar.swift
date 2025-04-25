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
    // Get access to the managed object context
    @Environment(\.managedObjectContext) private var viewContext
    
    // State for alert
    @State private var showingAlert = false
    @State private var newLocationName = "New Location"
    
    var body: some View {
        HStack {
            Text("Map")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            // Add button to create a new location
            Button(action: {
                showingAlert = true
            }) {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            .alert("Create New Location", isPresented: $showingAlert) {
                TextField("Location Name", text: $newLocationName)
                
                Button("Cancel", role: .cancel) {
                    // Reset name to default if canceled
                    newLocationName = "New Location"
                }
                
                Button("Create") {
                    createNewLocation()
                    viewModel.refresh.toggle()
                }
            } message: {
                Text("Enter a name for the new location")
            }
        }
        .padding(.vertical)
    }
    
    // Function to create a new location
    private func createNewLocation() {
        // Create position in center area of the map (using defaults from extension)
        let _ = Location.createNew(in: viewContext, name: newLocationName)
        
        // Reset name to default after creation
        newLocationName = "New Location"
    }
}

#Preview {
    MapTopBar(viewModel: ContentViewModel())
        .background(Color.gray.opacity(0.2))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 
