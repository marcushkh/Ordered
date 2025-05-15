//
//  LocationPopup.swift
//  Ordered
//
//  Created by Kai Hin Hung on 11/5/2025.
//

import SwiftUI
import CoreData

struct LocationPopup: View{
    @ObservedObject var viewModel: ContentViewModel
    @ObservedObject var dayPlannerVM: DayPlannerViewModel
    
    @State var allEvents: [Event] = []
    @State var draggingItem: Event? = nil
    @State var addEvent = false
    @State var selectedEvent: Event? = nil
    @FocusState var searchTyping: Bool
    
    @State var refresh: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View{
        VStack{
            HStack{
                Image(viewModel.location?.imageName ?? "")
                    .resizable()
                    .frame(width: K.xlarge_size, height: K.xlarge_size)
                
                Text(viewModel.location?.name ?? viewModel.location?.imageName?.capitalizedFirst ?? "")
                    .font(.title3)
                    .bold()
                
                Spacer()
                
                Image(systemName: "plus")
                    .foregroundStyle(.color3)
                    .font(.title3)
                    .bold()
                    .onTapGesture{
                        addEvent = true
                    }
                    .sheet(isPresented: $addEvent){
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Search Event", text: $viewModel.searchEventNameMap)
                                .textFieldStyle(PlainTextFieldStyle())
                                .focused($searchTyping)
                        }
                        .padding(.vertical)
                        .padding(.horizontal)
                        
                        EventList(viewModel: viewModel, eventName: $viewModel.searchEventNameMap, selectedEvent: $selectedEvent, toggleHeartSelectEvent: true, showHeart: false, showEdit: false, showLocation: true)
                            .padding(.horizontal)
                            .padding(.bottom, searchTyping ? 0 : 70)
                            .onAppear{
                                viewModel.selectedEvent = nil
                            }
                            .onChange(of: selectedEvent) { oldValue, newValue in
                                if let event = newValue, let location = viewModel.location {
                                    let wasAdded = location.toggleEvent(event)
                                    
                                    if wasAdded {
                                        print("Added event \(event.name ?? "") to \(location.imageName ?? "location")")
                                    } else {
                                        print("Removed event \(event.name ?? "") from \(location.imageName ?? "location")")
                                    }
                                    
                                    viewModel.refresh.toggle()
                                    fetchEvents()
                                    
                                    selectedEvent = nil
                                }
                            }
                    }
            }
            
            Divider()
                .background(Color.color3)
                .frame(height: 4)
            
            ScrollView{
                VStack{
                    ForEach(allEvents, id:\.self){ e in
                        ZStack{
                            RoundedRectangle(cornerRadius: 20.0)
                                .fill(.color1)
                            
                            HStack{
                                EventInfo(e: e)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                        }
                        .frame(height: 60)
                        .onTapGesture {
                            withAnimation {
                                //Select and start the event
                                // Add event below the highlighted Event
                                let newEC = e.getEC()
                                
                                //if no Cal -> create Cal
                                let cal = Cal.get(date: dayPlannerVM.currentDate.getYYMMDD()) ?? Cal.new(date: dayPlannerVM.currentDate.getYYMMDD())
                                
                                //TODO: this need to be fixed. No need SC now?
                                if let sc = viewModel.highlightedEC?.section_cal{
                                    sc.insert(newEC, after: viewModel.highlightedEC!)
                                }
                                else{
                                    let new_section_Cal = Section_Cal.new()
                                    
                                    new_section_Cal.add(event: newEC)
                                    cal.add(new_section_Cal)
                                }
                                cal.sort()
                                
                                if newEC.duration == -1 && newEC.startTime == nil {
                                    //TODO: this need to be fixed. We dont want it to be ticked, we want it to be shown in the home page
                                    EventActionHandler.shared.tick(ec: newEC)
                                }
                                else{
                                    EventActionHandler.shared.start(ec: newEC)
                                }
                                
                                viewModel.currentTab = .home
                                viewModel.showLocationEventList = false
                                viewModel.refresh.toggle()
                                
                            }
                        }
                        .draggable(e.description){
                            ZStack{
                                Circle()
                                    .frame(height: K.xlarge_size)
                                
                                Text(e.icon ?? "")
                                    .font(.custom("", size: K.large_size))
                                    .shadow(radius: K.medium_size)
                                
                            }
                            .onAppear {
                                draggingItem = e
                            }
                        }
                        .dropDestination(for: String.self) { items, location in
                            draggingItem = nil
                            refresh.toggle()
                            return false
                        } isTargeted: { status in
                            
                            withAnimation {
                                //Reordering
                                if let draggingItem, status, draggingItem.objectID != e.objectID{
                                    let e_index = allEvents.firstIndex(of: e) ?? 0
                                    
                                    allEvents.remove(at: allEvents.firstIndex(of: draggingItem) ?? 0)
                                    allEvents.insert(draggingItem, at: e_index)
                                    
                                    allEvents = allEvents.sorted { $0.isFavourite && !$1.isFavourite  }
                                    
                                    // Reorder in location.events rather than changing event.order
                                    if let currentLocation = viewModel.location {
                                        reorderEventsInLocation(currentLocation)
                                    }
                                    
                                    refresh.toggle()
                                }
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
            .padding(.top, -9)
            .onAppear {
                withAnimation {
                    fetchEvents()
                }
            }
            .frame(height: 200)
        }
        .foregroundStyle(.cPrimary)
        .padding(.horizontal, K.horizontal_padding)
        .padding(.vertical, K.medium_size)
        .background(Color.cBackground.cornerRadius(30))
        .padding(.horizontal, K.horizontal_padding)
        .onChange(of: viewModel.refresh, { oldValue, newValue in
            
        })
        
    }
    private func fetchEvents() {
        let request: NSFetchRequest<Event> = Event.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Event.isFavourite, ascending: false),
            NSSortDescriptor(keyPath: \Event.order, ascending: true)
        ]
        
        if let location = viewModel.location {
            request.predicate = NSPredicate(format: "ANY locations == %@", location)
        }

        do {
            allEvents = try Model.viewContext.fetch(request)
        } catch {
            print("Fetch failed: \(error)")
        }
    }
    
    // New function to reorder events in the location's ordered events collection
    private func reorderEventsInLocation(_ location: Location) {
        // Get current ordered events as mutable ordered set
        guard let currentEvents = location.events else { return }
        let mutableEvents = currentEvents.mutableCopy() as! NSMutableOrderedSet
        
        // Clear the ordered set
        mutableEvents.removeAllObjects()
        
        // Add events back in the new order from our allEvents array
        // This preserves the favorite status order
        for event in allEvents {
            mutableEvents.add(event)
        }
        
        // Set the reordered events back to the location
        location.events = mutableEvents
        
        // Save the context
        do {
            try Model.viewContext.save()
            print("Successfully reordered events in location")
        } catch {
            print("Error reordering events in location: \(error)")
        }
    }
}
