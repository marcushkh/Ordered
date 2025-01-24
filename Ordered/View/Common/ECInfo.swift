//
//  EventInfo.swift
//  Ordered
//
//  Created by Kai Hin Hung on 22/8/2024.
//

import SwiftUI

struct ECInfo: View {
    @ObservedObject var ec: Event_Cal
    @State var refresh: Bool = false
    
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
                
                if ec.startTime != "-1" && ec.startTime != nil{
                    Text(String(ec.startTime ?? "") + "-" + String(ec.endTime ?? ""))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                else if ec.duration != -1{
                    Text(Model.duration_to_string(ec.duration))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                
            }
        }
        .onChange(of: refresh) { oldValue, newValue in
            print("refreshed")
        }
    }
}

#Preview {
    ECInfo(ec: Sample.sampleEC)
}
