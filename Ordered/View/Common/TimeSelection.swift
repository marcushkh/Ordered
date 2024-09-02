//
//  TimeSelection.swift
//  Ordered
//
//  Created by Kai Hin Hung on 31/8/2024.
//

import SwiftUI

struct TimeSelection: View {
    @State var selectedTime = Date()
    @State var isSelectStartTime = true
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
    
    @Binding var isPresented: Bool
    @Binding var event: Event?
    @Binding var eventList: [Event]
    
    var body: some View {
        VStack{
            Text(isSelectStartTime ? "Start Time" : "End Time")
                .font(.title3)
                .bold()
            
            DatePicker(isSelectStartTime ? "Start Time" : "End Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(width: 330, height: 150)
                .clipped()
                .font(.title2)
                .padding(.bottom, 12)
            
            Button{
                if isSelectStartTime{
                    // Save start time
                    withAnimation {
                        event?.startTime = dateFormatter.string(from: selectedTime)
                        selectedTime = Calendar.current.date(byAdding: .hour, value: 1, to: selectedTime) ?? Date()
                        isSelectStartTime = false
                    }
                }
                else{
                    // Save end time + add the event into the selected item
                    
                    withAnimation {
                        print(event?.description ?? "ERROR")
                        event?.endTime = dateFormatter.string(from: selectedTime)
                        eventList.append(event!)
                        isPresented = false
                    }
                }
            } label: {
                ZStack{
                    RoundedRectangle(cornerSize: CGSize(width: 10, height: 10))
                        .fill(isSelectStartTime ? .color1 : .color3)
                        .frame(width: 305, height: 30)
                    
                    Text(isSelectStartTime ? "Confirm" : "Create Schedule")
                        .font(.title3)
                        .foregroundStyle(isSelectStartTime ? .color3 : .color1)
                }
            }
        }
        .padding()
        .background(Color.white.cornerRadius(25))
    }
}

#Preview {
    TimeSelection(isPresented: .constant(true), event: .constant(Sample.sampleEvent), eventList: .constant([]))
}
