//
//  EventInfo.swift
//  Ordered
//
//  Created by Kai Hin Hung on 22/8/2024.
//

import SwiftUI

struct EventInfo: View {
    @ObservedObject var s: Section
    @ObservedObject var e: Event
    
    var body: some View {
        HStack{
            ZStack{
                Circle()
                    .fill(Color(hex: s.color))
                    .frame(height: K.xlarge_size)
                
                Text(e.icon ?? "")
                    .font(.custom("", size: K.large_size))
                    .shadow(radius: K.medium_size)
            }
            .padding(.trailing)
            
            VStack(alignment: .leading){
                Text(e.name ?? "")
                    .font(.title3)
                
                if e.startTime != nil {
                    HStack(spacing: 0){
                        Text(e.startTime ?? "")
                        Text(" - ")
                        Text(e.endTime ?? "")
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }
                else if e.duration != -1{
                    Text(String(e.duration))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                
            }
        }
    }
}

#Preview {
    EventInfo(s: Sample.sampleSection, e: Sample.sampleEvent)
}
