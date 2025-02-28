//
//  EventHandler.swift
//  Ordered
//
//  Created by Kai Hin Hung on 25/1/2025.
//
import SwiftUI

class EventActionHandler: ObservableObject{
    // Singleton instance for global access
    static let shared = EventActionHandler()

    @Published var timePassed: Double {
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
        // Load initial values from UserDefaults
        self.timePassed = UserDefaults.standard.double(forKey: "timePassed")
        self.startTime = UserDefaults.standard.object(forKey: "startTime") as? Date
        self.currentECID = UserDefaults.standard.string(forKey: "currentECID")
    }

    func tick(ec: Event_Cal){
        if ec.aEndTime == nil{
            ec.aStartTime = Date.now.getHHMM()
            ec.aEndTime = Date.now.getHHMM()
            LiveActivityActions.startLiveActivity()
        }
        LiveActivityActions.refreshLiveActivities()
    }
    
    func start(ec: Event_Cal){
        //set the start time, already
        
        //if another event is running now => end the event  
        if let id = currentECID, let url = URL(string: id), let ec = Event_Cal.getEC(url){
            end(ec: ec)
        }
        
        timePassed = 0
        startTime = Date.now
        currentECID = ec.objectID.uriRepresentation().absoluteString
        
        ec.aStartTime = Date.now.getHHMM()
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
        if let startTime = startTime{
            let timeinterval = Date.now.timeIntervalSince(startTime)
            timePassed += timeinterval
        }
        startTime = nil
        LiveActivityActions.refreshLiveActivities()
        print("paused")
    }
    
    func resume(ec: Event_Cal){
        if let id = currentECID, ec.objectID.uriRepresentation().absoluteString == id{
            startTime = Date.now
        }
        else{
            start(ec: ec)
        }
        LiveActivityActions.refreshLiveActivities()
    }
    
    func end(ec: Event_Cal){
        //save the timePassed
        if let startTime = startTime{
            let timeinterval = Date.now.timeIntervalSince(startTime)
            timePassed += timeinterval
        }
        if let id = currentECID, let url = URL(string: id), let ec = Event_Cal.getEC(url){
            ec.aEndTime = Date.now.getHHMM()
            ec.durationFinished += Int32(timePassed/60) //Duration finished is using minute
            do {
                try Model.viewContext.save()
            } catch {
                print("Failed to save event: \(error.localizedDescription)")
            }
        }
        print("ended with time: " + String(timePassed))
        
        //set all to 0
        timePassed = 0
        startTime = nil
        currentECID = nil
        LiveActivityActions.refreshLiveActivities()
        //Put the activity one forward
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
}
