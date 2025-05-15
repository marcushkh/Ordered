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
    @ObservedObject var actionHandler = EventActionHandler.shared
    
    @State var refresh: Bool = false
    
    @State var currentTimePassed = "00:00"
    @State private var timer: Timer? = nil
    @Binding var highlightedEC: Event_Cal?
    
    var size: size = .large
    var showStartEndTime = true
    
    var body: some View {
        HStack{
            ZStack{
                Circle()
                    .fill(Color(hex: ec.section_cal?.location?.color))
                    .frame(height: size == .large ? K.xlarge_size : K.small_size)
                
                Text(ec.parent?.icon ?? "")
                    .font(.custom("", size: size == .large ? K.large_size : K.xsmall_size))
                    .shadow(radius: size == .large ? K.medium_size: K.xsmall_size)
            }
            .padding(.trailing)
            
            VStack(alignment: .leading){
                if highlightedEC == ec{
                    HStack{
                        Text((ec.parent?.name ?? "") + ((ec.detail != nil && ec.detail != "") ? ": " + ec.detail! : ""))
                            .font(size == .large ? .title3 : .subheadline)
                            .bold()
                        
                        Image(systemName: "star.circle")
                            .bold()
                    }
                    .foregroundStyle(.highlightText)
                }
                else{
                    Text((ec.parent?.name ?? "") + ((ec.detail != nil && ec.detail != "") ? ": " + ec.detail! : ""))
                        .font(size == .large ? .title3 : .subheadline)
                }
                
                
                // Schedule Event
                if let aStartTime = ec.aStartTime{
                    var timeBlock: String{
                        var ans = ""
                        
                        if showStartEndTime{
                            ans = ans + String(aStartTime.HHmmssPresentation())
                        }
                        
                        
                        if actionHandler.isCurrentEC(ec: ec){
                            ans = ans + " (" + currentTimePassed + ")"
                        }
                        else if let aEndTime = ec.aEndTime{
                            if ec.durationFinished != 0{
                                // if start and end time is the same, no need to show
                                if showStartEndTime{
                                    ans = ans + "-" + String(aEndTime.HHmmssPresentation()) + " "
                                }
                                ans = ans + "(" + Model.duration_to_string(min: ec.durationFinished) + ")"
                            }
                        }
                        
                        return ans
                    }
                    
                    Text(timeBlock)
                        .font(size == .large ? .subheadline : .caption)
                        .foregroundStyle(Color(hex: "5a5a5f"))
                        .onAppear {
                            if actionHandler.isCurrentEC(ec: ec){
                                currentTimePassed = actionHandler.getCurrentTimePassed()
                                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                                    if !actionHandler.isCurrentEC(ec: ec){
                                        timer?.invalidate()
                                        timer = nil
                                    }
                                    currentTimePassed = actionHandler.getCurrentTimePassed()
                                }
                            }
                        }
                        .onChange(of: actionHandler.currentECID) { oldValue, newValue in
                            if actionHandler.isCurrentEC(ec: ec){
                                currentTimePassed = actionHandler.getCurrentTimePassed()
                                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                                    if !actionHandler.isCurrentEC(ec: ec){
                                        timer?.invalidate()
                                        timer = nil
                                    }
                                    currentTimePassed = actionHandler.getCurrentTimePassed()
                                }
                            }
                        }
                }
                // Schedule Event that have not started
                else if ec.startTime != "-1" && ec.startTime != nil{
                    Text(String(ec.startTime?.HHmmssPresentation() ?? "") + "-" + String(ec.endTime?.HHmmssPresentation() ?? ""))
                        .font(size == .large ? .subheadline : .caption)
                        .foregroundStyle(.secondary)
                }
                // Duration Event
                else if ec.duration != -1{
                    Text(Model.duration_to_string(min: ec.duration))
                        .font(size == .large ? .subheadline : .caption)
                        .foregroundStyle(.secondary)
                }
                
            }
        }
        .onChange(of: refresh) { oldValue, newValue in
            print("refreshed")
        }
    }
}

