//
//  EmptyEventSelectionPopup.swift
//  Ordered
//
//  Created by AI Assistant on 2025.
//

import SwiftUI
import CoreData

struct EmptyEventSelectionPopup: View {
    @ObservedObject var viewModel: ContentViewModel
    @State var selectedEvent: Event? = nil
    
    // States for creating new event
    @State private var showCreateNewEvent = false
    @State private var newEventName = ""
    @State private var newEventEmoji = "💡"
    @State private var giveSuggestion = true
    
    // States for custom event ordering like EventBar
    @State private var locationEvents: [Event] = []
    @State private var otherEvents: [Event] = []
    @State private var currentLocation: Location? = nil
    
    let data = DataLoader()
    
    var body: some View {
        VStack(spacing: 16) {
            
            // Event List
            ScrollView{
                VStack{
                    // Create new event button
                    ZStack{
                        RoundedRectangle(cornerRadius: 20.0)
                            .fill(.color1)
                        
                        HStack{
                            Image(systemName: "plus.circle")
                                .font(.title)
                            
                            Text("Create new Event")
                                .font(.title3)
                                .bold()
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 60)
                    .padding(.horizontal, 3)
                    .padding(.bottom, -4)
                    .onTapGesture {
                        showCreateNewEvent = true
                        newEventName = ""
                        newEventEmoji = "💡"
                        giveSuggestion = true
                    }
                    
                    // Location Events Section (same as EventBar top section)
                    ForEach(locationEvents, id: \.self) { event in
                        ZStack{
                            RoundedRectangle(cornerRadius: 20.0)
                                .fill(.color1)
                            
                            HStack{
                                EventInfo(e: event)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 20.0)
                                .stroke(selectedEvent == event ? Color.color3 : Color.clear, lineWidth: 3)
                        )
                        .frame(height: 60)
                        .padding(.horizontal, 3)
                        .onTapGesture {
                            withAnimation {
                                selectedEvent = event
                                HapticFeedback.light()
                            }
                        }
                    }
                    
                    // Separator (only show if both sections have content)
                    if !locationEvents.isEmpty && !otherEvents.isEmpty {
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                            
                            Text("Other Events")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 8)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 3)
                        .padding(.vertical, 8)
                    }
                    
                    // Other Events Section (same as EventBar bottom section)
                    ForEach(otherEvents, id: \.self) { event in
                        ZStack{
                            RoundedRectangle(cornerRadius: 20.0)
                                .fill(.color1)
                            
                            HStack{
                                EventInfo(e: event)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 20.0)
                                .stroke(selectedEvent == event ? Color.color3 : Color.clear, lineWidth: 3)
                        )
                        .frame(height: 60)
                        .padding(.horizontal, 3)
                        .onTapGesture {
                            withAnimation {
                                selectedEvent = event
                                HapticFeedback.light()
                            }
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .frame(height: 250)
            
            // Two Button Layout - Delete on left, Save on right
            HStack(spacing: 12) {
                // Delete Button
                Button(action: {
                    if let eventCal = viewModel.emptyEventCal {
                        withAnimation {
                            eventCal.delete()
                            viewModel.showEmptyEventSelection = false
                            viewModel.emptyEventCal = nil
                            viewModel.refresh.toggle()
                        }
                    }
                }) {
                    ZStack{
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.error)
                            .frame(height: 40)
                        
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundStyle(Color.white)
                            .bold()
                    }
                }
                .frame(width: 60)
                
                // Save Button
                Button(action: {
                    if let selectedEvent = selectedEvent, let eventCal = viewModel.emptyEventCal {
                        // Save functionality - Update the event_cal with the selected parent
                        eventCal.parent = selectedEvent
                        eventCal.duration = selectedEvent.duration
                        eventCal.startTime = selectedEvent.startTime
                        eventCal.endTime = selectedEvent.endTime
                        
                        withAnimation {
                            if selectedEvent.duration == -1 && selectedEvent.startTime == nil {
                                EventActionHandler.shared.tick(ec: eventCal)
                            } else {
                                EventActionHandler.shared.start(ec: eventCal)
                            }
                        }
                        
                        do {
                            try Model.viewContext.save()
                        } catch {
                            print("Failed to save event_cal parent: \(error)")
                        }
                        
                        viewModel.showEmptyEventSelection = false
                        viewModel.emptyEventCal = nil
                        self.selectedEvent = nil
                        viewModel.refresh.toggle()
                    }
                }) {
                    ZStack{
                        RoundedRectangle(cornerRadius: 20)
                            .fill(selectedEvent != nil ? Color.color3 : Color.gray)
                            .frame(height: 40)
                        
                        HStack {
                            Text("Save")
                        }
                        .font(.title3)
                        .foregroundStyle(Color.white)
                        .bold()
                    }
                }
                .disabled(selectedEvent == nil)
            }
        }
        .padding(.horizontal, K.horizontal_padding)
        .padding(.vertical, K.medium_size)
        .background(Color.cBackground.cornerRadius(20))
        .padding(.horizontal, K.horizontal_padding)
        .onAppear {
            selectedEvent = nil
            fetchEvents()
        }
        .onChange(of: selectedEvent) { _, newValue in
            if newValue != nil {
                HapticFeedback.light()
            }
        }
        .sheet(isPresented: $showCreateNewEvent) {
            CreateNewEventSheet(
                eventName: $newEventName,
                selectedEmoji: $newEventEmoji,
                giveSuggestion: $giveSuggestion,
                viewModel: viewModel,
                onCreateEvent: { createdEvent in
                    // Assign the newly created event to the empty event
                    if let eventCal = viewModel.emptyEventCal {
                        eventCal.parent = createdEvent
                        eventCal.duration = createdEvent.duration
                        eventCal.startTime = createdEvent.startTime
                        eventCal.endTime = createdEvent.endTime
                        
                        // Add the newly created event to the location if the empty event is under a location
                        if let location = eventCal.section_cal?.location {
                            location.addEvent(createdEvent)
                        }
                        
                        withAnimation {
                            EventActionHandler.shared.start(ec: eventCal)
                        }
                        
                        do {
                            try Model.viewContext.save()
                        } catch {
                            print("Failed to save new event to empty event_cal: \(error)")
                        }
                        
                        viewModel.showEmptyEventSelection = false
                        viewModel.emptyEventCal = nil
                        viewModel.refresh.toggle()
                    }
                }
            )
        }
    }
    
    // Fetch events with same ordering logic as EventBar
    private func fetchEvents() {
        // Get current location from empty event's section
        currentLocation = viewModel.emptyEventCal?.section_cal?.location
        
        if let location = currentLocation {
            // First section: Events assigned to this location (same as EventBar top section)
            locationEvents = location.events?.array as? [Event] ?? []
            
            // Second section: Other events (same as EventBar bottom section with NSPredicate)
            let request: NSFetchRequest<Event> = Event.fetchRequest()
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \Event.isFavourite, ascending: false),
                NSSortDescriptor(keyPath: \Event.order, ascending: true)
            ]
            request.predicate = NSPredicate(format: "isActive == true AND (locations.@count == 0 OR NONE locations == %@)", location)
            
            do {
                otherEvents = try Model.viewContext.fetch(request)
            } catch {
                print("Failed to fetch other events: \(error)")
                otherEvents = []
            }
        } else {
            // No location - show all active events with standard ordering
            locationEvents = []
            
            let request: NSFetchRequest<Event> = Event.fetchRequest()
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \Event.isFavourite, ascending: false),
                NSSortDescriptor(keyPath: \Event.order, ascending: true)
            ]
            request.predicate = NSPredicate(format: "isActive == true")
            
            do {
                otherEvents = try Model.viewContext.fetch(request)
            } catch {
                print("Failed to fetch events: \(error)")
                otherEvents = []
            }
        }
    }
}

// New sheet view for creating events
struct CreateNewEventSheet: View {
    @Binding var eventName: String
    @Binding var selectedEmoji: String
    @Binding var giveSuggestion: Bool
    @FocusState var eventNameTyping: Bool
    
    @ObservedObject var viewModel: ContentViewModel
    let onCreateEvent: (Event) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            
            // Event creation interface
            EventAndEmoji(
                eventName: $eventName,
                selectedEmoji: $selectedEmoji,
                eventNameTyping: $eventNameTyping,
                giveSuggestion: $giveSuggestion
            ){
                ZStack{
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.color1))
                        .frame(width: 60, height: 60)
                    
                    Text(selectedEmoji)
                        .font(.custom("", size: 50))
                        .shadow(radius: K.medium_size)
                    
                }
            } eventNameView: {
                ZStack{
                    TextField("Event", text: $eventName)
                        .multilineTextAlignment(.leading)
                        .focused($eventNameTyping)
                        .underlineTextField(underline: .color3, focus: eventNameTyping, focusColor: Color(.color2))
                        .font(.system(size: 24))
                        .frame(width: 228, height: 80)
                }
            }
            .padding(.top)
            .padding(.horizontal, K.horizontal_padding * 2)
            
            Spacer()
            
            // Create Button
            Button(action: {
                let newEvent = Event.save(
                    icon: selectedEmoji,
                    name: eventName,
                    startTime: nil,
                    endTime: nil,
                    duration: 30, // 30 minutes duration
                    order_insert_first: false
                )
                
                onCreateEvent(newEvent)
                dismiss()
            }) {
                ZStack{
                    RoundedRectangle(cornerRadius: 20)
                        .fill(eventName.isEmpty ? Color.gray : Color.color3)
                        .frame(height: 50)
                    
                    Text("Create Event")
                        .font(.title3)
                        .foregroundStyle(Color.white)
                        .bold()
                }
            }
            .disabled(eventName.isEmpty)
            .padding(.horizontal, K.horizontal_padding)
            .padding(.bottom, 30)
        }
        .onAppear {
            eventNameTyping = true
        }
    }
} 
