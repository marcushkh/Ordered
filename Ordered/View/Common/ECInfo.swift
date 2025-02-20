//
//  EventInfo.swift
//  Ordered
//
//  Created by Kai Hin Hung on 22/8/2024.
//

import SwiftUI

struct ECInfo: View {
    @ObservedObject var ec: Event_Cal
    @ObservedObject var actionHandler = EventActionHandler.shared
    
    @State var refresh: Bool = false
    
    @State var currentTimePassed = "00:00"
    @State private var timer: Timer? = nil
    @Binding var highlightedEC: Event_Cal?
    
    var body: some View {
        HStack{
            ZStack{
                Circle()
                    .fill(Color(hex: ec.section_cal?.color))
                    .frame(height: K.xlarge_size)
                
                Text(ec.parent?.icon ?? "")
                    .font(.custom("", size: K.large_size))
                    .shadow(radius: K.medium_size)
            }
            .padding(.trailing)
            
            VStack(alignment: .leading){
                if highlightedEC == ec{
                    HStack{
                        Text((ec.parent?.name ?? "") + ((ec.detail != nil && ec.detail != "") ? ": " + ec.detail! : ""))
                            .font(.title3)
                            .bold()
                        
                        Image(systemName: "star.circle")
                            .bold()
                    }
                    .foregroundStyle(.highlightText)
                }
                else{
                    Text((ec.parent?.name ?? "") + ((ec.detail != nil && ec.detail != "") ? ": " + ec.detail! : ""))
                        .font(.title3)
                }
                
                
                
                // Schedule Event
                if let aStartTime = ec.aStartTime{
                    var timeBlock: String{
                        var ans = String(aStartTime)
                        
                        if actionHandler.isCurrentEC(ec: ec){
                            ans = ans + " (" + currentTimePassed + ")"
                        }
                        else if let aEndTime = ec.aEndTime{
                            if aStartTime != aEndTime{
                                // if start and end time is the same, no need to show
                                ans = ans + "-" + String(aEndTime)
                                ans = ans + " (" + Model.duration_to_string(min: ec.durationFinished) + ")"
                            }
                        }
                        
                        return ans
                    }
                    
                    Text(timeBlock)
                        .font(.subheadline)
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
                    Text(String(ec.startTime ?? "") + "-" + String(ec.endTime ?? ""))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                // Duration Event
                else if ec.duration != -1{
                    Text(Model.duration_to_string(min: ec.duration))
                        .font(.subheadline)
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
    ECInfo(ec: Sample.sampleEC, highlightedEC: .constant(nil))
}
