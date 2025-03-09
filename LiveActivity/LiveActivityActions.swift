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
            
            let dayStartTime = UserDefaults.standard.integer(forKey: "DayStartTime")
            
            let currentLocation = Cal.get(date: MyCalendar.getToday())?.getCurrentLocation() ?? 0
            var customEventList = Cal.get(date: MyCalendar.getToday())?.getCustomEventList() ?? []
            customEventList = Array(customEventList.dropFirst(currentLocation).prefix(8))
            
            let initialContentState = LiveActivityAttributes.ContentState(
                CustomEventList: customEventList,
                currentLocation: 0,
                nextColorLocation: getNextColorLocation(events: customEventList, currentLocation: 0),
                startTime: EventActionHandler.shared.startTime,
                timePassed: EventActionHandler.shared.timePassed,
                currentECID: EventActionHandler.shared.currentECID
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
            
            let dayStartTime = UserDefaults.standard.integer(forKey: "DayStartTime")
            let currentLocation = Cal.get(date: MyCalendar.getToday())?.getCurrentLocation() ?? 0
            var customEventList = Cal.get(date: MyCalendar.getToday())?.getCustomEventList() ?? []
            customEventList = Array(customEventList.dropFirst(currentLocation).prefix(10))
            
            Task{
                if customEventList.isEmpty {
                    await activity.end(dismissalPolicy: .immediate)
                }
            }
            
            let updatedContentState = LiveActivityAttributes.ContentState(
                CustomEventList: customEventList,
                currentLocation: 0,
                nextColorLocation: getNextColorLocation(events: customEventList, currentLocation: 0),
                startTime: EventActionHandler.shared.startTime,
                timePassed: EventActionHandler.shared.timePassed,
                currentECID: EventActionHandler.shared.currentECID
            )
            
            Task {
                await activity.update(using: updatedContentState)
            }
        }
    }
    
    static func getNextColorLocation(events: [CustomEvent], currentLocation: Int) -> Int{
        if events.dropFirst(currentLocation).count >= 3{
            for ec in events.dropFirst(currentLocation + 2){
                if events.dropFirst(currentLocation).count >= 3{
                    if ec.color != events[2 + currentLocation].color{
                        print(events.firstIndex(of: ec)!)
                        return events.firstIndex(of: ec)!
                    }
                }
            }
        }
        
        return events.count - 1
    }
    
    //Move CurrentLocation forward
    static func CurrentLocationIncrement(){
        for activity in Activity<LiveActivityAttributes>.activities {
            if activity.contentState.currentLocation + 1 >= activity.contentState.CustomEventList.count {
                //Remove Live Activity
                continue
            }
            
            let updatedState = LiveActivityAttributes.ContentState(
                CustomEventList: activity.contentState.CustomEventList,
                currentLocation: activity.contentState.currentLocation + 1,
                nextColorLocation: getNextColorLocation(events: activity.contentState.CustomEventList, currentLocation: activity.contentState.currentLocation + 1),
                startTime: EventActionHandler.shared.startTime,
                timePassed: EventActionHandler.shared.timePassed,
                currentECID: EventActionHandler.shared.currentECID
            )
            
            Task{
                try await activity.update(using: updatedState)
            }
        }
    }
    
    //Move CurrentLocation forward
    static func resetCurrentLocation(){
        for activity in Activity<LiveActivityAttributes>.activities {
            
            let updatedState = LiveActivityAttributes.ContentState(
                CustomEventList: activity.contentState.CustomEventList,
                currentLocation: 0,
                nextColorLocation: getNextColorLocation(events: activity.contentState.CustomEventList, currentLocation: 0),
                startTime: EventActionHandler.shared.startTime,
                timePassed: EventActionHandler.shared.timePassed,
                currentECID: EventActionHandler.shared.currentECID
            )
            
            Task{
                try await activity.update(using: updatedState)
            }
        }
    }
}
