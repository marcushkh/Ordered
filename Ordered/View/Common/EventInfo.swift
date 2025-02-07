//
//  EventInfo.swift
//  Ordered
//
//  Created by Kai Hin Hung on 22/8/2024.
//

import SwiftUI

struct EventInfo: View {
    
    @ObservedObject var e: Event
    
    var body: some View {
        HStack{
            ZStack{
                Circle()
                    .fill(.color1)
                    .frame(width: K.large_size)
                
                Text(e.icon ?? "")
                    .font(.title)
                    .shadow(radius: 10)
            }
            
            VStack(alignment: .leading){
                Text(e.name ?? "")
                
                // Schedule Event
                if let startTime = e.startTime {
                    HStack(spacing: 0){
                        Text(startTime)
                        if let endTime = e.endTime{
                            Text(" - ")
                            Text(e.endTime ?? "")
                        }
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }
                // Duration Event
                else if e.duration != -1{
                    Text(Model.duration_to_string(min: e.duration))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}

#Preview {
    EventInfo(e: Sample.sampleEvent)
}
