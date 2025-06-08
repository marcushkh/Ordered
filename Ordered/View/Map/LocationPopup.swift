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
                
                Text(viewModel.location?.name ?? viewModel.location?.imageName ?? "")
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
                                
                                let lastEvent = cal.getLastFinishedEvent()
                                
                                if let lastEvent = lastEvent, 
                                   let lastEventSectionCal = lastEvent.section_cal,
                                   lastEventSectionCal.location == viewModel.location {
                                    // Case 1: Insert after lastEvent in the same location
                                    lastEventSectionCal.insert(newEC, after: lastEvent)
                                }
                                else if let lastEvent = lastEvent,
                                        let lastEventSectionCal = lastEvent.section_cal,
                                        let nextSectionCal = cal.getNextSectionCal(after: lastEventSectionCal),
                                        nextSectionCal.location == viewModel.location {
                                    // Case 2: Insert at top of next section_cal with same location
                                    nextSectionCal.insertAtTop(newEC)
                                }
                                else {
                                    // Case 3: Create new section_cal with current location
                                    let new_section_Cal = Section_Cal.new(location: viewModel.location)
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
            .scrollIndicators(.hidden)
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
        .showCase(order: 8, title: "Tap on Any Task and start it now!", cornerRadius: 30){
            withAnimation {
                viewModel.showLocationEventList = false
                viewModel.location = nil
                viewModel.currentTab = .statistic
            }
        }
        .padding(.horizontal, K.horizontal_padding)
        .onChange(of: viewModel.refresh, { oldValue, newValue in
            
        })
        
    }
    private func fetchEvents() {
        allEvents = viewModel.location?.events?.array as? [Event] ?? []
    }
    
    // New function to reorder events in the location's ordered events collection
    private func reorderEventsInLocation(_ location: Location) {
        guard let currentEvents = location.events else { return }
        let mutableEvents = currentEvents.mutableCopy() as! NSMutableOrderedSet
        
        mutableEvents.removeAllObjects()
        
        for event in allEvents {
            mutableEvents.add(event)
        }
        
        location.events = mutableEvents
        
        do {
            try Model.viewContext.save()
            print("Successfully reordered events in location")
        } catch {
            print("Error reordering events in location: \(error)")
        }
    }
}
