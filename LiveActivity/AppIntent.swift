//
//  AppIntent.swift
//  LiveActivity
//
//  Created by Kai Hin Hung on 23/1/2025.
//

import WidgetKit
import AppIntents
import ActivityKit

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "This is an example widget." }

    // An example configurable parameter.
    @Parameter(title: "Favorite Emoji", default: "😃")
    var favoriteEmoji: String
}

struct Tick: LiveActivityIntent{
    static var title: LocalizedStringResource = "Start Event"
    static var description = IntentDescription("Event in Current Location is started now")
    
    func perform() async throws -> some IntentResult {
        for activity in Activity<LiveActivityAttributes>.activities {
            
             await MainActor.run {
                Task {
                    do {
                        if let ec = Event_Cal.getEC(activity.contentState.CustomEventList[activity.contentState.currentLocation].objectId){
                            EventActionHandler.shared.tick(ec: ec)
                        }
                    } catch {
                        print("Error updating Live Activity: \(error.localizedDescription)")
                    }
                }
            }
        }
        return .result()
    }
}

struct Start: LiveActivityIntent{
    static var title: LocalizedStringResource = "Start Event"
    static var description = IntentDescription("Event in Current Location is started now")
    
    func perform() async throws -> some IntentResult {
        for activity in Activity<LiveActivityAttributes>.activities {
            
             await MainActor.run {
                Task {
                    do {
                        if let ec = Event_Cal.getEC(activity.contentState.CustomEventList[activity.contentState.currentLocation].objectId){
                            EventActionHandler.shared.start(ec: ec)
                        }
                    } catch {
                        print("Error updating Live Activity: \(error.localizedDescription)")
                    }
                }
            }
        }
        return .result()
    }
}

struct Pause: LiveActivityIntent{
    static var title: LocalizedStringResource = "Pause Event"
    static var description = IntentDescription("Event in Current Location is paused now")
    
    func perform() async throws -> some IntentResult {
        for activity in Activity<LiveActivityAttributes>.activities {
            
             await MainActor.run {
                Task {
                    do {
                        if let ec = Event_Cal.getEC(activity.contentState.CustomEventList[activity.contentState.currentLocation].objectId){
                            EventActionHandler.shared.pause(ec: ec)
                        }
                    } catch {
                        print("Error updating Live Activity: \(error.localizedDescription)")
                    }
                }
            }
        }
        return .result()
    }
}

struct Resume: LiveActivityIntent{
    static var title: LocalizedStringResource = "Resume Event"
    static var description = IntentDescription("Event in Current Location is resume now")
    
    func perform() async throws -> some IntentResult {
        for activity in Activity<LiveActivityAttributes>.activities {
            
             await MainActor.run {
                Task {
                    do {
                        if let ec = Event_Cal.getEC(activity.contentState.CustomEventList[activity.contentState.currentLocation].objectId){
                            EventActionHandler.shared.resume(ec: ec)
                        }
                    } catch {
                        print("Error updating Live Activity: \(error.localizedDescription)")
                    }
                }
            }
        }
        return .result()
    }
}

struct End: LiveActivityIntent{
    static var title: LocalizedStringResource = "End Event"
    static var description = IntentDescription("Event in Current Location is ended now")
    
    func perform() async throws -> some IntentResult {
        for activity in Activity<LiveActivityAttributes>.activities {
            
             await MainActor.run {
                Task {
                    do {
                        if let ec = Event_Cal.getEC(activity.contentState.CustomEventList[activity.contentState.currentLocation].objectId){
                            EventActionHandler.shared.end(ec: ec)
                        }
                    } catch {
                        print("Error updating Live Activity: \(error.localizedDescription)")
                    }
                }
            }
            LiveActivityActions.refreshLiveActivities()
        }
        return .result()
    }
}

struct MoveForward: LiveActivityIntent {
    
    static var title: LocalizedStringResource = "Move Forward"
    static var description = IntentDescription("Current Location is increased by 1")
    
    func perform() async throws -> some IntentResult {
        LiveActivityActions.CurrentLocationIncrement()
        return .result()
    }
}

struct Reset: LiveActivityIntent {
    
    static var title: LocalizedStringResource = "Reset Current Location"
    static var description = IntentDescription("Current Location is reset to 0")
    
    func perform() async throws -> some IntentResult {
        LiveActivityActions.resetCurrentLocation()
        return .result()
    }
}
