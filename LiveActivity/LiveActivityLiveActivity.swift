//
//  LiveActivityLiveActivity.swift
//  LiveActivity
//
//  Created by Kai Hin Hung on 23/1/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct LiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var CustomEventList: [CustomEvent]
        var currentLocation: Int = 0
        var nextColorLocation: Int = 0
        var startTime: Date?
        var timePassed: Double = 0
        var currentECID: String?
    }
    // Fixed non-changing properties about your activity go here!
}

struct LiveActivityLiveActivity: Widget {
    @State var currentTimePassed: String = ""
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivityAttributes.self) { context in
            let currentEvent = context.state.CustomEventList[context.state.currentLocation]
            let currentLocation = context.state.currentLocation
            let eventList = context.state.CustomEventList
        let nextColorLocation = context.state.nextColorLocation
            let startTime = context.state.startTime
            let timePassed = context.state.timePassed
            
            HStack(spacing: 0){
                Text(currentEvent.name)
                    .font(.title3)
                    .bold()
                
                Spacer()
            
                if let currentECID = context.state.currentECID, currentECID == currentEvent.objectId{
                    if let startTime = context.state.startTime {
                        Text(timerInterval: (Calendar.current.date(byAdding: .second, value: Int(timePassed) * -1, to: startTime) ?? Date.now)...Date.distantFuture, countsDown: false)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                    else{
                        if timePassed != 0{
                            Text(Model.duration_to_HHmmss(sec: Int32(timePassed)))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                if currentLocation != 0{
                    Button(intent: Reset()) {
                        Image(systemName: "arrowshape.turn.up.backward.fill")
                            .foregroundStyle(.b)
                            .frame(width: 13, height: 13)
                    }
                    .buttonBorderShape(.circle)
                }
            }
            .padding(.top)
            .padding(.horizontal)
            
            HStack(spacing: 0) {
                //For each
                ForEach(Array(eventList.dropFirst(currentLocation).prefix(3).enumerated()), id: \.element.objectId) { index, event in
                    ZStack{
                        Circle()
                            .fill(Color(hex: event.color))
                            .frame(width: 30, height: 30)
                            .overlay{
                                if index == 0{
                                    Circle()
                                        .stroke(lineWidth: 2)
                                        .fill(.cPrimary)
                                }
                            }
                        
                        Text(event.icon)
                            .font(.title3)
                    }
                    
                    if index != 2 && eventList.count - currentLocation - 1 > index {
                        Rectangle()
                            .fill(.color3)
                            .frame(width: index == 0 ? 17 : 20, height: 3)
                            .padding(.leading, index == 0 ? 2 : 0)
                    }
                }
                Spacer()
                
                if nextColorLocation != 0 && nextColorLocation > currentLocation + 2{
                    Line()
                        .stroke(style: StrokeStyle(lineWidth: 3, dash: [5]))
                        .frame(height: 3)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.color3)
                        .padding(.top, 3)
                    
                    ZStack{
                        Circle()
                            .fill(Color(hex: eventList[nextColorLocation].color))
                            .frame(width: 30, height: 30)
                        
                        Text(eventList[nextColorLocation].icon)
                            .font(.title3)
                    }
                    .padding(.trailing)
                }
                
                HStack(spacing: 4){
                    //Case handling
                    if currentEvent.aStartTime == nil{
                        Button(intent: MoveForward()) {
                            Image(systemName: "forward.fill")
                                .foregroundStyle(Color.b)
                        }
                        .buttonBorderShape(.circle)
                    }
                    else{
                        Button(intent: End()) {
                            Image(systemName: "stop.fill")
                                .foregroundStyle(Color.b)
                        }
                        .buttonBorderShape(.circle)
                    }
                    
                    if currentEvent.startTime == nil && (currentEvent.duration == nil || currentEvent.duration == -1){
                        Button(intent: Tick()) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.b)
                        }
                        .buttonBorderShape(.circle)
                    }
                    else if currentEvent.aStartTime == nil{
                        Button(intent: Start()) {
                            Image(systemName: "play.fill")
                                .foregroundStyle(Color.b)
                        }
                        .buttonBorderShape(.circle)
                    }
                    else if startTime == nil{
                        Button(intent: Resume()) {
                            Image(systemName: "play.fill")
                                .foregroundStyle(Color.b)
                        }
                        .buttonBorderShape(.circle)
                    }
                    else if startTime != nil{
                        Button(intent: Pause()) {
                            Image(systemName: "pause.fill")
                                .foregroundStyle(Color.b)
                        }
                        .buttonBorderShape(.circle)
                    }
                }
            }
            .padding()
            .background(.color1)
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                let currentEvent = context.state.CustomEventList[context.state.currentLocation]
                let currentLocation = context.state.currentLocation
                let eventList = context.state.CustomEventList
                let nextColorLocation = context.state.nextColorLocation
                let startTime = context.state.startTime
                let timePassed = context.state.timePassed
                
                DynamicIslandExpandedRegion(.leading) {
                    Text(currentEvent.name)
                        .font(.title3)
                        .bold()
                        .padding(.top, 4)
                        .padding(.horizontal, 2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack{
                        if let currentECID = context.state.currentECID, currentECID == currentEvent.objectId{
                            if let startTime = context.state.startTime {
                                Text(timerInterval: (Calendar.current.date(byAdding: .second, value: Int(timePassed) * -1, to: startTime) ?? Date.now)...Date.distantFuture, countsDown: false)
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.trailing)
                            }
                            else{
                                if timePassed != 0{
                                    Text(Model.duration_to_HHmmss(sec: Int32(timePassed)))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                    .padding(.horizontal, 2)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 0) {
                        //For each
                        ForEach(Array(eventList.dropFirst(currentLocation).prefix(3).enumerated()), id: \.element.objectId) { index, event in
                            ZStack{
                                Circle()
                                    .fill(Color(hex: event.color))
                                    .frame(width: 30, height: 30)
                                    .overlay{
                                        if index == 0{
                                            Circle()
                                                .stroke(lineWidth: 2)
                                                .fill(.cPrimary)
                                        }
                                    }
                                
                                Text(event.icon)
                                    .font(.title3)
                            }
                            
                            if index != 2 && eventList.count - currentLocation - 1 > index {
                                Rectangle()
                                    .fill(.color3)
                                    .frame(width: index == 0 ? 17 : 20, height: 3)
                                    .padding(.leading, index == 0 ? 2 : 0)
                            }
                        }
                        Spacer()
                        
                        if nextColorLocation != 0 && nextColorLocation > currentLocation + 2{
                            Line()
                                .stroke(style: StrokeStyle(lineWidth: 3, dash: [5]))
                                .frame(height: 3)
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(.color3)
                                .padding(.top, 3)
                            
                            ZStack{
                                Circle()
                                    .fill(Color(hex: eventList[nextColorLocation].color))
                                    .frame(width: 30, height: 30)
                                
                                Text(eventList[nextColorLocation].icon)
                                    .font(.title3)
                            }
                            .padding(.trailing)
                        }
                        
                        HStack(spacing: 4){
                            //Case handling
                            if currentEvent.aStartTime == nil{
                                Button(intent: MoveForward()) {
                                    Image(systemName: "forward.fill")
                                        .foregroundStyle(Color.b)
                                }
                                .buttonBorderShape(.circle)
                            }
                            else{
                                Button(intent: End()) {
                                    Image(systemName: "stop.fill")
                                        .foregroundStyle(Color.b)
                                }
                                .buttonBorderShape(.circle)
                            }
                            
                            if currentEvent.startTime == nil && (currentEvent.duration == nil || currentEvent.duration == -1){
                                Button(intent: Tick()) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.b)
                                }
                                .buttonBorderShape(.circle)
                            }
                            else if currentEvent.aStartTime == nil{
                                Button(intent: Start()) {
                                    Image(systemName: "play.fill")
                                        .foregroundStyle(Color.b)
                                }
                                .buttonBorderShape(.circle)
                            }
                            else if startTime == nil{
                                Button(intent: Resume()) {
                                    Image(systemName: "play.fill")
                                        .foregroundStyle(Color.b)
                                }
                                .buttonBorderShape(.circle)
                            }
                            else if startTime != nil{
                                Button(intent: Pause()) {
                                    Image(systemName: "pause.fill")
                                        .foregroundStyle(Color.b)
                                }
                                .buttonBorderShape(.circle)
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
            } compactLeading: {
                ZStack{
                    Circle()
                        .fill(Color(hex: context.state.CustomEventList[context.state.nextColorLocation].color))
                    
                    Text(context.state.CustomEventList[context.state.nextColorLocation].icon)
                        .font(.title3)
                }
            } compactTrailing: {
                let startTime = context.state.startTime
                let timePassed = context.state.timePassed
                let currentEvent = context.state.CustomEventList[context.state.currentLocation]
                
                if let currentECID = context.state.currentECID, currentECID == currentEvent.objectId{
                    if let startTime = context.state.startTime {
                        Text(timerInterval: (Calendar.current.date(byAdding: .second, value: Int(timePassed) * -1, to: startTime) ?? Date.now)...Date.distantFuture, countsDown: false)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 43)
                    }
                    else{
                        if timePassed != 0{
                            Text(Model.duration_to_HHmmss(sec: Int32(timePassed)))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } minimal: {
                ZStack{
                    Circle()
                        .fill(Color(hex: context.state.CustomEventList[context.state.nextColorLocation].color))
                        .frame(width: 30, height: 30)
                    
                    Text(context.state.CustomEventList[context.state.nextColorLocation].icon)
                        .font(.title3)
                }
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
    
}
