//
//  EventInfo.swift
//  Ordered
//
//  Created by Kai Hin Hung on 22/8/2024.
//

import SwiftUI

enum size{
    case medium
    case large
}

struct ECInfo: View {
    @ObservedObject var ec: Event_Cal
    @State var refresh: Bool = false
    @Binding var highlightedEC: Event_Cal?
    
    var size: size = .large
    var showStartEndTime = true
    
    var body: some View {
        HStack{
            ZStack{
                Circle()
                    .fill(Color(hex: ec.section_cal?.parent?.color))
                    .frame(height: size == .large ? K.xlarge_size : K.small_size)
                
                Text(ec.parent?.icon ?? "")
                    .font(.custom("", size: size == .large ? K.large_size : K.xsmall_size))
                    .shadow(radius: size == .large ? K.medium_size: K.xsmall_size)
            }
            .padding(.trailing)
            
            VStack(alignment: .leading){
                if highlightedEC == ec{
                    HStack{
                        Text(ec.parent?.name ?? "Select Event")
                            .font(size == .large ? .title3 : .subheadline)
                            .bold()
                        
                        Image(systemName: "star.circle")
                            .bold()
                    }
                    .foregroundStyle(.highlightText)
                }
                else{
                    Text(ec.parent?.name ?? "Select Event")
                        .font(size == .large ? .title3 : .subheadline)
                        .foregroundStyle(ec.parent == nil ? .secondary : .primary)
                }

                if let aStartTime = ec.aStartTime{
                    Text(showStartEndTime ? aStartTime.HHmmssPresentation() : "Done")
                        .font(size == .large ? .subheadline : .caption)
                        .foregroundStyle(Color(hex: "5a5a5f"))
                }
                
            }
        }
        .onChange(of: refresh) { oldValue, newValue in
            print("refreshed")
        }
    }
}
