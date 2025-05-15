//
//  LocationInfo.swift
//  Ordered
//
//  Created by Kai Hin Hung on 22/8/2024.
//

import SwiftUI

struct LocationInfo: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var location: Location
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color(hex: location.color ?? ""))
                    .frame(height: K.xlarge_size)
                
                if let imageName = location.imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: K.medium_size, height: K.medium_size)
                }
            }
            .padding(.trailing, 8)
            
            VStack(alignment: .leading) {
                Text(location.name ?? "")
                    .font(.title3)
            }
            
            Spacer()
        }
    }
}

#Preview {
    // Create a mock location for preview
    let previewContext = PersistenceController.preview.container.viewContext
    let location = Location(context: previewContext)
    location.name = "Home"
    location.imageName = "home"
    location.color = "#FF9500"
    
    return LocationInfo(location: location)
        .previewLayout(.sizeThatFits)
        .padding()
} 