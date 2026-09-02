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
    
    // States for custom event ordering like EventBar
    @State private var sectionEvents: [Event] = []
    @State private var otherEvents: [Event] = []
    @State private var currentSection: Section? = nil
    
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
                    }
                    
                    ForEach(sectionEvents, id: \.self) { event in
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
                    if !sectionEvents.isEmpty && !otherEvents.isEmpty {
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
                        }
                    }
                    closePicker()
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
                    if let selectedEvent {
                        saveSelection(selectedEvent)
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
                viewModel: viewModel,
                onCreateEvent: { createdEvent in
                    currentSection?.add(event: createdEvent)
                    saveSelection(createdEvent)
                }
            )
        }
    }

    private func saveSelection(_ event: Event) {
        let eventCal: Event_Cal

        if let emptyEventCal = viewModel.emptyEventCal {
            eventCal = emptyEventCal
        } else if let sectionCal = viewModel.eventSelectionSectionCal {
            eventCal = Event_Cal.getEmpty()
            sectionCal.add(event: eventCal)
        } else {
            return
        }

        eventCal.parent = event
        eventCal.duration = -1
        eventCal.durationFinished = 0
        eventCal.startTime = nil
        eventCal.endTime = nil
        eventCal.aStartTime = nil
        eventCal.aEndTime = nil

        if viewModel.currentTab == .plan {
            viewModel.highlightedEC = eventCal
            viewModel.highlightedSC = nil
        }

        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save selected event: \(error)")
        }

        closePicker()
    }

    private func closePicker() {
        viewModel.showEmptyEventSelection = false
        viewModel.emptyEventCal = nil
        viewModel.eventSelectionSectionCal = nil
        selectedEvent = nil
        viewModel.refresh.toggle()
    }
    
    // Fetch events with same ordering logic as EventBar
    private func fetchEvents() {
        currentSection = viewModel.eventSelectionSectionCal?.parent
            ?? viewModel.emptyEventCal?.section_cal?.parent
        
        if let section = currentSection {
            sectionEvents = section.events?.array as? [Event] ?? []
            
            // Second section: Other events (same as EventBar bottom section with NSPredicate)
            let request: NSFetchRequest<Event> = Event.fetchRequest()
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \Event.isFavourite, ascending: false),
                NSSortDescriptor(keyPath: \Event.order, ascending: true)
            ]
            let selectedIDs = Set(sectionEvents.map(\.objectID))
            
            do {
                otherEvents = try Model.viewContext.fetch(request).filter { !selectedIDs.contains($0.objectID) }
            } catch {
                print("Failed to fetch other events: \(error)")
                otherEvents = []
            }
        } else {
            sectionEvents = []
            
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
                eventNameTyping: $eventNameTyping
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
                    duration: -1,
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
