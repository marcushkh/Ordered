//
//  EventInfo.swift
//  Ordered
//
//  Created by Kai Hin Hung on 22/8/2024.
//

import SwiftUI

struct EventInfo: View {
    @State var sect_cal: Section_Cal?
    @State var event_cal: Event_Cal?
    
    var body: some View {
        
        ZStack{
            Circle()
                .fill(Color(hex: sect_cal?.parent?.color))
                .frame(height: K.xlarge_size)
            
            Text(event_cal?.parent?.icon ?? "")
                .font(.custom("", size: K.large_size))
                .shadow(radius: K.medium_size)
        }
        .padding(.trailing)
        
        VStack(alignment: .leading){
            Text(event_cal?.parent?.name ?? "")
                .font(.title3)
            
            if event_cal?.parent?.duration != -1 {
                Text(String(event_cal?.parent?.duration ?? 0))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            
        }
        
    }
}

#Preview {
    EventInfo(sect_cal: nil, event_cal: nil)
}
