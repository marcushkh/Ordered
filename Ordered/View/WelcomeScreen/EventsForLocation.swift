//
//  EventsForLocation.swift
//  Ordered
//
//  Created by Kai Hin Hung on 22/5/2025.
//
import SwiftUI


struct EventsForLocation: View {
    @ObservedObject var viewModel: ContentViewModel
    @ObservedObject var welcomeVM: WelcomeVM
    
    init(viewModel: ContentViewModel, welcomeVM: WelcomeVM) {
        self.welcomeVM = welcomeVM
        self.viewModel = viewModel

    }
    
    var body: some View {
        VStack{
            ZStack{
                RoundedRectangle(cornerRadius: 20.0)
                    .fill(.color3)
                    .frame(height: 60)
                
                HStack{
                    if let location = welcomeVM.location {
                        Image(location.imageName ?? "")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                        
                        Text(location.name ?? location.imageName ?? "")
                    }
                    
                    Spacer()
                }
                .foregroundStyle(.cBackground)
                .frame(height: 60)
                .padding(.horizontal)
            }
            Divider()
            
            ScrollView{
                VStack{
                    // Safely cast and handle existing events
                    ForEach(welcomeVM.location?.events?.array as? [Event] ?? [], id: \.self){ e in
                        ZStack{
                            RoundedRectangle(cornerRadius: 20.0)
                                .fill(.color1)
                            
                            HStack{
                                EventInfo(e: e)
                                
                                Spacer()
                                
                                Button{
                                    withAnimation {
                                        welcomeVM.location?.toggleEvent(e)
                                        if (e.locations == nil || e.locations?.count == 0) && e.isFavourite == false {
                                            e.delete()
                                        }
                                        viewModel.refresh.toggle()
                                    }
                                    
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .bold()
                                        .foregroundStyle(Color.cPrimary, Color.error)
                                }
                            }
                            .padding(.horizontal)
                            
                        }
                        .frame(height: 60)
                    }
                    
                    let existingEventNames = (welcomeVM.location?.events?.array as? [Event] ?? [])
                        .compactMap { $0.name }
                    
                    ForEach((LocationType.from(welcomeVM.location?.imageName ?? "")?.defaultEvents ?? [])
                        .filter { defaultEvent in 
                            !existingEventNames.contains(defaultEvent.name)
                        }, 
                        id: \.self) { event in
                        
                        ZStack{
                            RoundedRectangle(cornerRadius: 20.0)
                                .fill(.color1)
                            
                            HStack{
                                Text(event.icon)
                                    .font(.title)
                                
                                Text(event.name)
                                    .font(.title3)
                                
                                Spacer()
                                
                                Button{
                                    withAnimation{
                                        // Find existing event or create a new one
                                        let event = Event.findOrCreate(
                                            icon: event.icon,
                                            name: event.name,
                                            duration: event.duration ?? -1,
                                            order_insert_first: false
                                        )
                                        
                                        // Associate the event with the location
                                        if let location = welcomeVM.location {
                                            _ = location.toggleEvent(event)
                                        }
                                        
                                        viewModel.refresh.toggle()
                                    }
                                    
                                } label:{
                                    Image(systemName: "plus.circle.fill")
                                        .bold()
                                        .foregroundStyle(.cPrimary, .success)
                                }
                            }
                            .frame(height: 60)
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.top)
            }
            .scrollIndicators(.hidden)
            .padding(.top, -8)
            .frame(height: 470)
            .onChange(of: viewModel.refresh) { _, _ in
                
            }
            
            Button{
                withAnimation {
                    welcomeVM.showPopup = false
                    welcomeVM.location = nil
                }
            } label:{
                Text("Done")
                    .font(.title3)
                    .foregroundStyle(Color(.white))
                    .bold()
                    .padding([.top, .bottom], 10)
                    .padding([.leading, .trailing], 100)
                    .background(Color(hex: "484B6A"))
                    .clipShape(.rect(cornerRadius: 20))
            }
        }
        .foregroundStyle(.cPrimary)
        .padding(.horizontal, K.horizontal_padding)
        .padding(.top, K.medium_size)
        .padding(.bottom, 8)
        .background(Color.cBackground.cornerRadius(30))
        .padding(.horizontal, K.horizontal_padding)
    }
}
