//
//  Resting.swift
//  Ordered
//
//  Created by Kai Hin Hung on 19/5/2025.
//
import SwiftUI
import PopupView
import CoreData

struct LocationSelection: View{
    @ObservedObject var viewModel: ContentViewModel
    @ObservedObject var welcomeVM: WelcomeVM
    
    @Environment(\.colorScheme) private var colorScheme
    
     @FetchRequest(
        sortDescriptors: [
            SortDescriptor(\.positionOrder, order: .forward)
        ]
    )
    private var locations: FetchedResults<Location>
    
    @State var showAlert = false
    
    var body: some View{
        VStack(alignment: .leading){
            HStack{
                Spacer()
                VStack{
                    if !welcomeVM.showPopup{
                        Text("Configure the places you are active in")
                            .font(.title2)
                            .bold()
                            .multilineTextAlignment(.center)
                    }
                    else{
                        Text("Select the Events that you would do in the Selected Place")
                            .font(.title2)
                            .bold()
                            .multilineTextAlignment(.center)
                    }
                    
                }
                Spacer()
            }
            
            Divider()
                .foregroundStyle(.color3)
            
            
            ScrollView{
                VStack{
                    ForEach(locations){ location in
                        ZStack{
                            RoundedRectangle(cornerRadius: 20.0)
                                .fill(.color1)
                            
                            HStack{
                                Image(location.imageName ?? "")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 40)
                                
                                Text(location.name ?? "")
                                    
                                Spacer()
                                
                                Button{
                                    withAnimation {
                                        if location.delete(from: Model.viewContext) {
                                            
                                        }
                                    }
                                    
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .bold()
                                        .foregroundStyle(Color.cPrimary, Color.error)
                                }
                            }
                            .frame(height: 60)
                            .padding(.horizontal)
                        }
                        .onTapGesture {
                            welcomeVM.location = location
                            welcomeVM.showPopup = true
                        }
                    }
                    
                    // Get existing location image names to filter against
                    let existingImageNames = locations.compactMap { $0.imageName }
                    
                    // Filter LocationType cases that aren't already created
                    ForEach(LocationType.allCases.filter { locationType in
                        !existingImageNames.contains(locationType.rawValue)
                    }, id: \.self){ location in
                        ZStack{
                            RoundedRectangle(cornerRadius: 20.0)
                                .fill(.color1)
                            
                            HStack{
                                Image(location.rawValue)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 40)
                                
                                Text(location.rawValue.capitalizedFirst)
                                    
                                Spacer()
                            }
                            .frame(height: 60)
                            .padding(.horizontal)
                        }
                        .onTapGesture {
                            if Location.count() >= 8 {
                                showAlert = true
                            }
                            else if (Location.count() >= 5 && !viewModel.isSubscriptionActive){
                                viewModel.isShowPaywall = true
                            }
                            else{
                                // First, check if a location with this image name already exists
                                let existingLocation = Location.findByImageName(location.rawValue, in: Model.viewContext)
                                
                                // If location exists, use it; otherwise create a new one
                                if let existingLoc = existingLocation {
                                    welcomeVM.location = existingLoc
                                    welcomeVM.showPopup = true
                                } else {
                                    // Create new location only if one doesn't exist
                                    let newLocation = Location.createNew(in: Model.viewContext,
                                                                         imageName: location.rawValue,
                                                                         colorScheme: colorScheme)
                                    for event in Event.getAllFavorite(){
                                        newLocation?.addEvent(event)
                                    }
                                    
                                    if let newLocation = newLocation {
                                        welcomeVM.location = newLocation
                                        welcomeVM.showPopup = true
                                    }
                                }
                            }
                        }
                        .alert("Only 8 Locations can be created", isPresented: $showAlert) {
                            Button{
                                showAlert = false
                            } label: {
                                Text("ok")
                            }
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        
    }
}
