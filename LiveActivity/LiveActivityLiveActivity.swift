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
        var currentLocation: Int = 0
        var CustomEventList: [CustomEvent]
        var nextColorLocation: Int = 0
    }
    // Fixed non-changing properties about your activity go here!
}

struct LiveActivityLiveActivity: Widget {
    var i = EventActionHandler.shared
    
    var body: some WidgetConfiguration {
    ActivityConfiguration(for: LiveActivityAttributes.self) { context in
        VStack{
            HStack{
                Text(context.state.CustomEventList[context.state.currentLocation].name)
                    .font(.title3)
                    .bold()
                    
                Spacer()
                
                Text(context.state.CustomEventList[context.state.currentLocation].aStartTime?.HHmmssPresentation() ?? "")
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 0) {
                //For each
                ForEach(Array(context.state.CustomEventList.dropFirst(context.state.currentLocation).prefix(3).enumerated()), id: \.element.objectId) { index, event in
                    ZStack{
                        Circle()
                            .fill(Color(hex: event.color))
                            .frame(width: 30, height: 30)
                            .overlay{
                                if index == 0{
                                    Circle()
                                        .stroke(lineWidth: 3)
                                        .fill(.cPrimary)
                                }
                            }
                            
                        Text(event.icon)
                            .font(.title3)
                    }
                    
                    if index != 2{
                        Rectangle()
                            .fill(.color3)
                            .frame(width: 20, height: 3)
                    }
                }
                Spacer()
                
                if context.state.nextColorLocation != 0 && context.state.nextColorLocation > context.state.currentLocation + 3{
                    Line()
                        .stroke(style: StrokeStyle(lineWidth: 3, dash: [5]))
                        .frame(height: 3)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.color3)
                        .padding(.top, 3)
                    
                    ZStack{
                        Circle()
                            .fill(Color(hex: context.state.CustomEventList[context.state.nextColorLocation].color))
                            .frame(width: 30, height: 30)
                        
                        Text(context.state.CustomEventList[context.state.nextColorLocation].icon)
                            .font(.title3)
                    }
                    .padding(.trailing)
                }
                
                //Case handling
                Button(intent: MoveForward()) {
                    Image(systemName: "forward.fill")
                        .foregroundStyle(.cPrimary, .color3)
                }
                .buttonBorderShape(.circle)
                
                Button(intent: Start()) {
                    Image(systemName: "play.fill")
                        .foregroundStyle(.cPrimary, .color3)
                }
                .buttonBorderShape(.circle)
                
            }
        }
        .padding()
    } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T")
            } minimal: {
                Text("HI")
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}
