//
//  EventHandler.swift
//  Ordered
//
//  Created by Kai Hin Hung on 25/1/2025.
//
import SwiftUI
import UIKit

class EventActionHandler: ObservableObject{
    // Singleton instance for global access
    static let shared = EventActionHandler()

    @Published var timePassed: Double { //in sec
        didSet {
            UserDefaults.standard.set(timePassed, forKey: "timePassed")
        }
    }

    @Published var startTime: Date? {
        didSet {
            UserDefaults.standard.set(startTime, forKey: "startTime")
        }
    }

    @Published var currentECID: String? {
        didSet {
            UserDefaults.standard.set(currentECID, forKey: "currentECID")
        }
    }

    private init() {
        self.timePassed = UserDefaults.standard.double(forKey: "timePassed")
        self.startTime = UserDefaults.standard.object(forKey: "startTime") as? Date
        self.currentECID = UserDefaults.standard.string(forKey: "currentECID")
    }

    func tick(ec: Event_Cal){
        HapticFeedback.heavy()
        
        let currentTime = Date.now.getHHMM()
        
        // End previous event at the exact time this event starts
        if let id = currentECID, let url = URL(string: id), let previousEC = Event_Cal.getEC(url){
            end(ec: previousEC, customEndTime: currentTime)
        }
        
        if ec.aEndTime == nil{
            ec.aStartTime = currentTime
            ec.aEndTime = currentTime
            LiveActivityActions.startLiveActivity()
        }
        LiveActivityActions.refreshLiveActivities()
    }
    
    func start(ec: Event_Cal){
        HapticFeedback.heavy()
        
        // First, determine the start time for the new event
        let newEventStartTime: String
        if ec.aStartTime == nil{
            newEventStartTime = Date.now.getHHMM()
        } else {
            newEventStartTime = ec.aStartTime!
        }
        
        // End the previous event at the exact time this new event starts
        if let id = currentECID, let url = URL(string: id), let previousEC = Event_Cal.getEC(url){
            end(ec: previousEC, customEndTime: newEventStartTime)
        }
        
        timePassed = 0
        startTime = Date.now
        currentECID = ec.objectID.uriRepresentation().absoluteString
        
        if ec.aStartTime == nil{
            ec.aStartTime = newEventStartTime
        }
        else{
            let timeInterval = Date.now.timeIntervalSince(Date.getDateFromHHMM(ec.aStartTime!))
            timePassed = timeInterval
            print("TIME PASSED = \(timePassed)")
        }
        
        LiveActivityActions.startLiveActivity()
        LiveActivityActions.refreshLiveActivities()
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
        
        print("Started")
    }
    
    func pause(ec: Event_Cal){
        HapticFeedback.light()
        
        if let startTime = startTime{
            let timeinterval = Date.now.timeIntervalSince(startTime)
            timePassed += timeinterval
        }
        startTime = nil
        LiveActivityActions.refreshLiveActivities()
        print("paused")
    }
    
    func resume(ec: Event_Cal){
        HapticFeedback.light()
        
        if let id = currentECID, ec.objectID.uriRepresentation().absoluteString == id{
            startTime = Date.now
        }
        else{
            start(ec: ec)
        }
        LiveActivityActions.startLiveActivity()
        LiveActivityActions.refreshLiveActivities()
    }
    
    func end(ec: Event_Cal, customEndTime: String? = nil){
        HapticFeedback.heavy()
        
        if let id = currentECID, let url = URL(string: id), let ec = Event_Cal.getEC(url){
            let actualEndTime = customEndTime ?? Date.now.getHHMM()
            ec.aEndTime = actualEndTime
            
            // Calculate correct duration based on actual end time
            if let customEndTime = customEndTime {
                // If custom end time provided, calculate duration from aStartTime to customEndTime
                if let aStartTime = ec.aStartTime {
                    let startDate = Date.getDateFromHHMM(aStartTime)
                    let endDate = Date.getDateFromHHMM(customEndTime)
                    let actualDuration = endDate.timeIntervalSince(startDate)
                    ec.durationFinished += Int32(actualDuration/60) // Convert to minutes
                    print("Custom end time duration: \(actualDuration/60) minutes")
                }
            } else {
                // If no custom end time, use the existing logic with current time
                if let startTime = startTime{
                    let timeinterval = Date.now.timeIntervalSince(startTime)
                    timePassed += timeinterval
                }
                ec.durationFinished += Int32(timePassed/60) //Duration finished is using minute
                print("Current time duration: \(timePassed/60) minutes")
            }
            
            do {
                try Model.viewContext.save()
            } catch {
                print("Failed to save event: \(error.localizedDescription)")
            }
        }
        print("ended with time: " + String(timePassed))
        
        timePassed = 0
        startTime = nil
        currentECID = nil
        LiveActivityActions.refreshLiveActivities()
    }
    
    func isCurrentEC(ec: Event_Cal) -> Bool{
        if let id = currentECID, ec.objectID.uriRepresentation().absoluteString == id{
            return true
        }
        return false
    }
    
    func getCurrentTimePassed() -> String{
        if let startTime = startTime{
            let t = timePassed + Date.now.timeIntervalSince(startTime)
            return Model.duration_to_HHmmss(sec: Int32(t))
        }
        return Model.duration_to_HHmmss(sec: Int32(timePassed))
    }
    
    func AddCurrentTimePassed(min: Int) {
        timePassed += Double(min * 60)
        if timePassed < 0 {timePassed = 0}
    }
    
    func reset(){
        timePassed = 0
        startTime = nil
        currentECID = nil
    }
}
