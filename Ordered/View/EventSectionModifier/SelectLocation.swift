//
//  SelectLocation.swift
//  Ordered
//
//  Created by Kai Hin Hung on 13/5/2025.
//

import SwiftUI
import CoreData

struct SelectLocation: View {
    @ObservedObject var viewModel: ContentViewModel
    
    // State for selected location
    @State var selectedLocation: Location?
    
    // Fetch all locations from Core Data
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Location.positionOrder, ascending: true)],
        animation: .default)
    private var locations: FetchedResults<Location>
    
    // Use 3 items per row for better spacing
    private let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 18), count: 4)
    
    var body: some View {
        VStack(spacing: 16) {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(locations, id: \.self) { location in
                        LocationItem(
                            location: location,
                            isSelected: selectedLocation?.objectID == location.objectID,
                            onSelect: {
                                selectedLocation = location
                            }
                        )
                    }
                }
                .padding(6)
            }
            .scrollIndicators(.hidden)
            .frame(height: 200)
            
            // Save/Cancel buttons
            HStack(spacing: 20) {
                // Save button
                Button(action: {
                    
                    withAnimation {
                        
                        if selectedLocation == nil{
                            
                        }
                        else {
                            Section_Cal.save(location: selectedLocation, sc: viewModel.changeSection_Cal, cal: viewModel.insertToCal, insertIndex: viewModel.insertIndex)
                            
                            viewModel.refresh.toggle()
                        }
                    }
            
                    dismiss()
                }) {
                    ZStack{
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.color3)
                            .frame(height: 40)
                        
                        Text(viewModel.changeSection_Cal == nil && viewModel.changeSection == nil ? "New Location" : "Change Location")
                            .font(.system(size: 20))
                            .foregroundStyle(Color(.white))
                            .bold()
                    }
                }
                .disabled(selectedLocation == nil)
                .opacity(selectedLocation == nil ? 0.6 : 1.0)
            }
            .padding(.top, 8)
        }
        .foregroundStyle(.cPrimary)
        .padding(.horizontal, K.horizontal_padding)
        .padding(.vertical, K.medium_size)
        .background(Color.cBackground.cornerRadius(30))
        .padding(.horizontal, K.horizontal_padding)
        .onAppear {
            // Initialize with current location if available
            if let section = viewModel.changeSection_Cal {
                selectedLocation = section.location
            }
        }
        .onDisappear{
            dismiss()
        }
    }
    
    func dismiss(){
        viewModel.showSelectLocation = false
        viewModel.changeSection_Cal = nil
        viewModel.changeSection = nil
        viewModel.insertToCal = nil
        viewModel.insertIndex = nil
        viewModel.refresh.toggle()
        print("dismissed")
    }
}

// Individual location item view
struct LocationItem: View {
    let location: Location
    let isSelected: Bool
    let onSelect: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 4) {
            // Location image - larger size
            Image(location.imageName ?? "home")
                .resizable()
                .scaledToFit()
                .frame(width: 55, height: 55)
                .padding(4)
            
            // Location name
            Text(location.name ?? location.imageName ?? "")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(colorScheme == .dark ? .white : .black)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .padding(.horizontal, 2)
                .padding(.bottom, 4)
        }
        .frame(minWidth: 70, maxWidth: .infinity)
        .frame(height: 85)
        .background(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.color3 : (colorScheme == .dark ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3)), 
                        lineWidth: isSelected ? 3 : 1)
        )
        .onTapGesture {
            onSelect()
        }
    }
}
