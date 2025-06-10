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
    private let stationaryThreshold: TimeInterval = 15*60
    private var lastMovementTimestamp: Date?
    private var stationaryTimer: Timer?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    private override init() {
        super.init()
        setupLocationManager()
        setupBackgroundMonitoring()
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
    }
    
    func stopMonitoring() {
        locationManager.stopMonitoringSignificantLocationChanges()
        stopStationaryTimer()
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
    
    // Background-safe stationary detection using timestamps
    private func checkStationaryStatusUsingTimestamp() {
        guard let lastMovement = lastMovementTimestamp else { return }
        
        let timeSinceLastMovement = Date().timeIntervalSince(lastMovement)
        
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
                sendLocalNotification(message: "You have stopped moving")
                
                //create new location and event
                let event_Cal = Event_Cal.getEmpty(aStartTime: Date.now.getHHMM())
                event_Cal.aStartTime = Date.now.getHHMM()
                event_Cal.detail = description
                
                let new_section_Cal: Section_Cal = Section_Cal.new()
                new_section_Cal.add(event: event_Cal)
                
                let cal = Cal.get(date: Date.now.getYYMMDD()) ?? Cal.new(date: Date.now.getYYMMDD())
                
                cal.add(new_section_Cal)
                cal.sort()
            }
        }
    }
    
    private func updateStateToTransit() {
        if currentState != .transit {
            currentState = .transit
            print("User is now in transit")
            
            // Send local notification if in background
            if UIApplication.shared.applicationState != .active {
                sendLocalNotification(message: "Movement detected")
            }
        }
        
        // Update timestamp and restart timer
        lastMovementTimestamp = Date()
        startStationaryTimer()
    }
    
    private func sendLocalNotification(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Movement Status"
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
        print("App entered background - switching to timestamp-based detection")
        beginBackgroundTask()
        
        // Stop timer-based detection and rely on timestamp checking
        stopStationaryTimer()
    }
    
    @objc private func appWillEnterForeground() {
        print("App entering foreground - resuming timer-based detection")
        endBackgroundTask()
        
        // Check status using timestamp first
        checkStationaryStatusUsingTimestamp()
        
        // Resume timer-based detection
        if currentState == .transit {
            startStationaryTimer()
        }
        
        // Update background refresh status
        isBackgroundRefreshAvailable = UIApplication.shared.backgroundRefreshStatus == .available
    }
    
    deinit {
        stopMonitoring()
        NotificationCenter.default.removeObserver(self)
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

