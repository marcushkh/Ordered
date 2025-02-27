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

struct MoveForward: LiveActivityIntent {
    
    static var title: LocalizedStringResource = "Move Forward"
    static var description = IntentDescription("Current Location is increased by 1")
    
    func perform() async throws -> some IntentResult {
        LiveActivityActions.CurrentLocationIncrement()
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
                        if let ec = Event_Cal.getEC(URL: activity.contentState.CustomEventList[activity.contentState.currentLocation].objectId){
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
