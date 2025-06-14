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
    
    var body: some View {
        VStack(spacing: 16) {
            
            // Event List
            EventList(
                viewModel: viewModel,
                eventName: .constant(""),
                selectedEvent: $selectedEvent,
                toggleHeartSelectEvent: true,
                showHeart: false,
                showEdit: false,
                showLocation: false,
                showDelete: false
            )
            .frame(height: 300)
            
            // Save Button
            Button(action: {
                if let event = selectedEvent, let eventCal = viewModel.emptyEventCal {
                    // Update the event_cal with the selected parent
                    eventCal.parent = event
                    eventCal.duration = event.duration
                    eventCal.startTime = event.startTime
                    eventCal.endTime = event.endTime
                    
                    withAnimation {
                        if event.duration == -1 && event.startTime == nil {
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
                    selectedEvent = nil
                    viewModel.refresh.toggle()
                }
            }) {
                ZStack{
                    RoundedRectangle(cornerRadius: 20)
                        .fill(selectedEvent != nil ? Color.color3 : Color.gray)
                        .frame(height: 40)
                    
                    Text("Save")
                        .font(.title3)
                        .foregroundStyle(Color.white)
                        .bold()
                        .cornerRadius(10)
                }
            }
            .disabled(selectedEvent == nil)
        }
        .padding(.horizontal, K.horizontal_padding)
        .padding(.vertical, K.medium_size)
        .background(Color.cBackground.cornerRadius(20))
        .padding(.horizontal, K.horizontal_padding)
        .onAppear {
            selectedEvent = nil
        }
        .onChange(of: selectedEvent) { _, newValue in
            if newValue != nil {
                HapticFeedback.light()
            }
        }
    }
} 
