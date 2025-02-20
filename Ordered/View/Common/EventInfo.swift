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
            Text(e.icon ?? "")
                .font(.title) 
            
            VStack(alignment: .leading){
                Text(e.name ?? "")
                    .font(.title3)
                
                // Schedule Event
                if let startTime = e.startTime {
                    HStack(spacing: 0){
                        Text(startTime)
                        if let endTime = e.endTime{
                            Text(" - ")
                            Text(endTime)
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
    }
}

#Preview {
    EventInfo(e: Sample.sampleEvent)
}
