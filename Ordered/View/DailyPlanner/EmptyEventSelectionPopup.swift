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
                            Image(systemName: "checkmark")
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
        }
        .onChange(of: selectedEvent) { _, newValue in
            if newValue != nil {
                HapticFeedback.light()
            }
        }
    }
} 
