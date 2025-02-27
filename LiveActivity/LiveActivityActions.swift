//
//  LiveActivityActions.swift
//  Ordered
//
//  Created by Kai Hin Hung on 26/2/2025.
//
import SwiftUI
import ActivityKit

struct LiveActivityActions{
    static func startLiveActivity() {

        if Activity<LiveActivityAttributes>.activities.isEmpty {
            let attributes = LiveActivityAttributes()
            
            let currentLocation = Cal.get(date: Date.now)?.getCurrentLocation() ?? 0
            let customEventList = Cal.get(date: Date.now)?.getCustomEventList() ?? []
            
            let initialContentState = LiveActivityAttributes.ContentState(
                currentLocation: currentLocation,
                CustomEventList: customEventList,
                nextColorLocation: getNextColorLocation(events: customEventList, currentLocation: currentLocation)
            )
        
            do {
                var liveActivity = try Activity<LiveActivityAttributes>.request(
                    attributes: attributes,
                    contentState: initialContentState,
                    pushType: nil
                )
            } catch {
                print("Error starting Live Activity: \(error.localizedDescription)")
            }
        }
    }
    
    //Update
    static func refreshLiveActivities() {
        let activeActivities = Activity<LiveActivityAttributes>.activities
        for activity in activeActivities {
            
            let currentLocation = Cal.get(date: Date.now)?.getCurrentLocation() ?? 0
            let customEventList = Cal.get(date: Date.now)?.getCustomEventList() ?? []
            
            let updatedContentState = LiveActivityAttributes.ContentState(
                currentLocation: currentLocation,
                CustomEventList: customEventList,
                nextColorLocation: getNextColorLocation(events: customEventList, currentLocation: currentLocation)
            )
            
            Task {
                 await activity.update(using: updatedContentState)
            }
        }
    }
    
    //Move CurrentLocation forward
    static func CurrentLocationIncrement(){
        for activity in Activity<LiveActivityAttributes>.activities {
            if activity.contentState.currentLocation + 1 >= activity.contentState.CustomEventList.count {
                continue
            }
            
            let updatedState = LiveActivityAttributes.ContentState(
                currentLocation: activity.contentState.currentLocation + 1,
                CustomEventList: activity.contentState.CustomEventList,
                nextColorLocation: getNextColorLocation(events: activity.contentState.CustomEventList, currentLocation: activity.contentState.currentLocation + 1)
            )
            
            Task{
                try await activity.update(using: updatedState)
            }
        }
    }
    
    static func getNextColorLocation(events: [CustomEvent], currentLocation: Int) -> Int{
        for ec in events.dropFirst(currentLocation){
            if ec.color != events[currentLocation].color{
                return events.firstIndex(of: ec)!
            }
        }
        return events.count - 1
    }
}
