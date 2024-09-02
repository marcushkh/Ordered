//
//  EventInfo.swift
//  Ordered
//
//  Created by Kai Hin Hung on 22/8/2024.
//

import SwiftUI

struct ECInfo: View {
    @ObservedObject var ec: Event_Cal
    
    var body: some View {
        HStack{
            ZStack{
                Circle()
                    .fill(Color(hex: ec.section_cal?.color))
                    .frame(height: K.xlarge_size)
                
                Text(ec.icon ?? "")
                    .font(.custom("", size: K.large_size))
                    .shadow(radius: K.medium_size)
            }
            .padding(.trailing)
            
            VStack(alignment: .leading){
                Text(ec.name ?? "")
                    .font(.title3)
                
                if ec.duration != -1{
                    Text(String(ec.duration))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                
            }
        }
    }
}

#Preview {
    ECInfo(ec: Sample.sampleEC)
}
