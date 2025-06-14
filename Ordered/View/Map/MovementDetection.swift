//
//  MovementDetection.swift
//  Ordered
//
//  Created by Kai Hin Hung on 9/6/2025.
//

import Foundation
import CoreLocation
import Combine
import UIKit
import UserNotifications

enum MovementState {
    case transit
    case stationary
}

class MovementDetection: NSObject, ObservableObject {
    static let shared = MovementDetection()
    
    @Published var currentState: MovementState = .stationary
    @Published var lastKnownLocation: CLLocation?
    @Published var isBackgroundRefreshAvailable = true
    
    private let locationManager = CLLocationManager()
    
    #if DEBUG
    private let stationaryThreshold: TimeInterval = 15*60 // 1 minutes
    #else
    private let stationaryThreshold: TimeInterval = 15*60 // 15 minutes
    #endif
    
    private var lastMovementTimestamp: Date?
    private var stationaryTimer: Timer?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var backgroundCheckTimer: Timer?
    
    private override init() {
        super.init()
        setupLocationManager()
        setupBackgroundMonitoring()
        requestNotificationPermission()
    }
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Request location permissions
        requestLocationPermission()
    }
    
    private func setupBackgroundMonitoring() {
        // Monitor background app refresh status
        isBackgroundRefreshAvailable = UIApplication.shared.backgroundRefreshStatus == .available
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            // Request "Always" permission for background location
            locationManager.requestAlwaysAuthorization()
        case .denied, .restricted:
            print("Location access denied")
        case .authorizedWhenInUse:
            // Prompt user to upgrade to "Always" for background functionality
            print("Consider upgrading to 'Always' location permission for background tracking")
            locationManager.requestAlwaysAuthorization()
            startMonitoring()
        case .authorizedAlways:
            startMonitoring()
        @unknown default:
            break
        }
    }
    
    func startMonitoring() {
        guard CLLocationManager.significantLocationChangeMonitoringAvailable() else {
            print("Significant location change monitoring not available")
            return
        }
        
        locationManager.startMonitoringSignificantLocationChanges()
        print("Started monitoring significant location changes")
        
        // Set initial timestamp
        lastMovementTimestamp = Date()
        startStationaryTimer()
        startBackgroundCheckTimer()
    }
    
    func stopMonitoring() {
        locationManager.stopMonitoringSignificantLocationChanges()
        stopStationaryTimer()
        stopBackgroundCheckTimer()
        endBackgroundTask()
        print("Stopped monitoring location changes")
    }
    
    private func startStationaryTimer() {
        stopStationaryTimer()
        
        stationaryTimer = Timer.scheduledTimer(withTimeInterval: stationaryThreshold, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateStateToStationary()
            }
        }
    }
    
    private func stopStationaryTimer() {
        stationaryTimer?.invalidate()
        stationaryTimer = nil
    }
    
    // New: Background check timer that runs periodically
    private func startBackgroundCheckTimer() {
        stopBackgroundCheckTimer()
        
        // Check every 5 minutes in foreground, every minute in background
        let interval: TimeInterval = UIApplication.shared.applicationState == .active ? 300 : 60
        
        backgroundCheckTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.checkStationaryStatusUsingTimestamp()
            }
        }
    }
    
    private func stopBackgroundCheckTimer() {
        backgroundCheckTimer?.invalidate()
        backgroundCheckTimer = nil
    }
    
    // Enhanced timestamp-based stationary detection
    private func checkStationaryStatusUsingTimestamp() {
        guard let lastMovement = lastMovementTimestamp else { 
            // If no movement recorded, assume stationary
            if currentState != .stationary {
                updateStateToStationary()
            }
            return 
        }
        
        let timeSinceLastMovement = Date().timeIntervalSince(lastMovement)
        
        print("Time since last movement: \(timeSinceLastMovement/60) minutes, threshold: \(stationaryThreshold/60) minutes")
        
        if timeSinceLastMovement >= stationaryThreshold && currentState != .stationary {
            updateStateToStationary()
        }
    }
    
    private func updateStateToStationary() {
        if currentState != .stationary {
            currentState = .stationary
            print("User is now stationary")
            
            // Send local notification if in background
            if UIApplication.shared.applicationState != .active {
                sendLocalNotification(title: "New Empty Event is created for you!", message: "Since you have stopped moving, an empty event is created for you! Select the event you are currently doing. ")
            }
            
            let cal = Cal.getOrCreateWithDefault(date: Date.now)
            
            // Remove the last empty event before creating a new one
            cal.removeLastEmptyEvent()
            
            let event_Cal = Event_Cal.getEmpty(aStartTime: lastMovementTimestamp?.getHHMM())
            
            var new_section_Cal: Section_Cal = cal.section_cals?.lastObject as? Section_Cal ?? Section_Cal.new()
            if new_section_Cal.location != nil{
                new_section_Cal = Section_Cal.new()
            }
            new_section_Cal.add(event: event_Cal)
            
            cal.add(new_section_Cal)
            cal.sort()
        }
    }
    
    private func updateStateToTransit() {
        if currentState != .transit {
            currentState = .transit
            print("User is now in transit")
            
            // Send local notification if in background
            if UIApplication.shared.applicationState != .active {
                #if DEBUG
                sendLocalNotification(title: "movement detected", message: "Movement detected")
                #endif
            }
        }
        // Update timestamp and restart timer
        lastMovementTimestamp = Date()
        startStationaryTimer()
    }
    
    private func sendLocalNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }
    
    // Background task management
    private func beginBackgroundTask() {
        endBackgroundTask()
        
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    @objc private func appDidEnterBackground() {
        print("App entered background - maintaining timestamp-based detection")
        beginBackgroundTask()
        
        // Keep the stationary timer running for as long as possible
        // Don't stop it immediately - let iOS manage background execution
        
        // Start more frequent background checks
        startBackgroundCheckTimer()
        
        // Immediately check current status
        checkStationaryStatusUsingTimestamp()
    }
    
    @objc private func appWillEnterForeground() {
        print("App entering foreground - resuming full detection")
        endBackgroundTask()
        
        // Check status using timestamp first - this is crucial
        checkStationaryStatusUsingTimestamp()
        
        // Resume/restart timers based on current state
        if currentState == .transit {
            startStationaryTimer()
        }
        
        // Restart background check timer with foreground interval
        startBackgroundCheckTimer()
        
        // Update background refresh status
        isBackgroundRefreshAvailable = UIApplication.shared.backgroundRefreshStatus == .available
    }
    
    deinit {
        stopMonitoring()
        NotificationCenter.default.removeObserver(self)
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension MovementDetection: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.lastKnownLocation = location
            self.updateStateToTransit()
        }
        
        print("Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        print("App state: \(UIApplication.shared.applicationState.rawValue)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse:
            print("Location permission: When In Use - limited background functionality")
            startMonitoring()
        case .authorizedAlways:
            print("Location permission: Always - full background functionality")
            startMonitoring()
        case .denied, .restricted:
            print("Location access denied")
            stopMonitoring()
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
}

